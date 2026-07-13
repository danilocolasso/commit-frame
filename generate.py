#!/usr/bin/env python3
"""Renders out/*.png (640x480 dashboard images, one per variant): fetches the
public GitHub contribution calendar, injects it into the template and renders
it with headless Chromium. Run in a loop via run.sh."""
import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

from PIL import Image

USER = "danilocolasso"
WIDTH = 640
HEIGHT = 480
VARIANTS = {"github-dashboard.png": 12}
CHROMIUM = "/opt/homebrew/bin/chromium"
BASE = Path(__file__).parent
OUT_DIR = BASE / "out"

url = f"https://github.com/users/{USER}/contributions"
html = urllib.request.urlopen(url, timeout=15).read().decode()
cells = sorted(re.findall(r'data-date="(\d{4}-\d\d-\d\d)"[^>]*data-level="(\d)"', html))
if not cells:
    sys.exit("contribution calendar not found in GitHub's HTML")
start = cells[0][0]
levels = "".join(level for _, level in cells)

template = (
    (BASE / "template.html")
    .read_text()
    .replace("__USER__", USER)
    .replace("__START__", start)
    .replace("__LEVELS__", levels)
    .replace("__W__", str(WIDTH))
    .replace("__H__", str(HEIGHT))
    # the layout is designed at 640x480; zoom scales it to any screen, letterboxed
    .replace("__ZOOM__", f"{min(WIDTH / 640, HEIGHT / 480):.4f}")
)

OUT_DIR.mkdir(exist_ok=True)
for name, months in VARIANTS.items():
    out = OUT_DIR / name
    with tempfile.TemporaryDirectory() as td:
        dash = Path(td, "dash.html")
        dash.write_text(template.replace("__MONTHS__", str(months)))
        shot = Path(td, "shot.png")
        # ponytail: a 640x480 window renders a broken layout on this chromium; 640x800 + crop is the proven path
        subprocess.run(
            [CHROMIUM, "--headless", "--disable-gpu", "--hide-scrollbars",
             f"--screenshot={shot}", "--window-size={},{}".format(WIDTH, HEIGHT + 320), f"file://{dash}"],
            check=True, capture_output=True, timeout=60,
        )
        tmp = out.with_suffix(".tmp.png")
        Image.open(shot).crop((0, 0, WIDTH, HEIGHT)).save(tmp)
        tmp.replace(out)  # atomic swap: the client never downloads a half-written png

print(f"ok: {start} +{len(levels)} days -> {', '.join(VARIANTS)}")
