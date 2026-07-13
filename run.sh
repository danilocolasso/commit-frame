#!/bin/sh
# Serves out/ on port 8000 and regenerates the dashboard every 60s.
cd "$(dirname "$0")" || exit 1
mkdir -p out
exec >> "$HOME/Library/Logs/commit-frame.log" 2>&1

echo "[run.sh] start $(date)"
python3 -u -m http.server 8000 -d out &
trap 'kill $!' EXIT INT TERM

while true; do
    python3 -u generate.py || echo "[run.sh] generate failed; keeping previous image"
    sleep 60
done
