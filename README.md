# commit-frame

Renders your GitHub contribution graph, today's commit status and streaks
as a 640×480 PNG, refreshed every minute and served over HTTP. Built to feed
[pocket-frame](https://github.com/danilocolasso/pocket-frame) on a Miyoo Mini+,
but any client that can display a PNG works.

```
generate.py  fetches github.com/users/<user>/contributions (public, no token),
             injects the data into template.html, screenshots it with headless
             Chromium, writes out/github-dashboard.png atomically
run.sh       serves out/ on :8000 and reruns generate.py every 60s
```

## Requirements

Chromium (`brew install --cask chromium`) and Pillow (`pip3 install pillow`).

## Run

```sh
./run.sh
```

Then point any client at `http://<host>:8000/github-dashboard.png`.

To start it at login on macOS, adapt the paths in `launchd.plist` and:

```sh
cp launchd.plist ~/Library/LaunchAgents/com.<you>.commit-frame.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.<you>.commit-frame.plist
```

Heads-up: launchd can't execute from `~/Documents` (macOS privacy) — keep the
project somewhere like `~/Projects`.

## Config

Constants at the top of `generate.py`: `USER`, `CHROMIUM` path, and `VARIANTS`
(output filename → months of graph shown; add a `"...-6m.png": 6` entry for a
half-year graph with bigger cells). Visuals live in `template.html` — plain
HTML/CSS, edit away.

Private contributions show up if "Include private contributions on my
profile" is enabled in your GitHub settings. Streaks are computed over the
1-year calendar window.
