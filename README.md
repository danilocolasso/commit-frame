# commit-frame

Renders your GitHub contribution graph, today's commit status and streaks as
a 640×480 PNG, refreshed every minute and served over HTTP. Built to feed
[pocket-frame](https://github.com/danilocolasso/pocket-frame) on a Miyoo
Mini+, but any client that can display a PNG works.

```
generate.py   GitHub calendar → template.html → headless Chromium → out/*.png
run.sh        serves out/ on :8000, reruns generate.py every 60s
```

## Setup

```sh
make setup
```

The wizard asks for your GitHub username and screen size (any resolution —
the layout scales to fit), checks Chromium/Pillow, does a test render, and
(on macOS) can install a start-at-login launchd agent. `make stop` / `make
start` control it; rerun `make setup` to change configs. Prefer doing it by
hand? See [docs/manual-setup.md](docs/manual-setup.md).

Then point your client at `http://<host>:8000/github-dashboard.png`.

No token needed — data comes from GitHub's public contribution calendar
(private contributions included if enabled in your profile settings).
