# Manual setup

Everything `make setup` does, by hand.

## 1. Requirements

- Chromium: `brew install --cask chromium` (any Chrome/Chromium binary works)
- Pillow: `pip3 install pillow`

## 2. Configure

Constants at the top of `generate.py`:

| Constant | Meaning |
|---|---|
| `USER` | GitHub username to render |
| `WIDTH`, `HEIGHT` | output resolution — the 640×480 layout is scaled to fit (letterboxed), so any handheld screen works |
| `CHROMIUM` | path to the Chromium/Chrome binary |
| `VARIANTS` | output filename → months of graph shown; add `"github-dashboard-6m.png": 6` for a half-year graph with bigger cells |

Visuals live in `template.html` — plain HTML/CSS, edit away.

## 3. Run

```sh
./run.sh
```

Serves `out/` on port 8000 and reruns `generate.py` every 60s.
Test: `curl -I http://localhost:8000/github-dashboard.png`

With the launchd agent installed, `make start` / `make stop` control it.
To change configs later, just rerun `make setup`.

## 4. Start at login (macOS)

Adapt the paths in `launchd.plist`, then:

```sh
cp launchd.plist ~/Library/LaunchAgents/com.<you>.commit-frame.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.<you>.commit-frame.plist
```

Heads-up: launchd can't execute from `~/Documents` (macOS privacy/TCC) —
keep the project somewhere like `~/Projects`. Logs go to
`~/Library/Logs/commit-frame.log`.

## Notes

- Data comes from `github.com/users/<user>/contributions` — public, no token.
  Private contributions are included if "Include private contributions on my
  profile" is enabled in your GitHub profile settings.
- Streaks (current/best) are computed over the 1-year calendar window.
- The PNG is written atomically (tmp + rename), so clients never download a
  half-written file.
