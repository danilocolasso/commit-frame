#!/bin/sh
# Interactive setup for commit-frame. Run via `make setup`.
set -e
cd "$(dirname "$0")"

B='\033[1m'; DIM='\033[2m'; GRN='\033[32m'; CYN='\033[36m'; RED='\033[31m'; YLW='\033[33m'; RST='\033[0m'

printf "\n  ${B}COMMIT FRAME${RST} ${DIM}setup${RST}\n"
printf "  ${DIM}────────────────────────────────────────${RST}\n\n"

cur_user=$(grep -o 'USER = "[^"]*"' generate.py | cut -d'"' -f2)
printf "  ${CYN}GitHub username${RST} ${DIM}[%s]${RST}\n  > " "$cur_user"
read -r user
user=${user:-$cur_user}

while :; do
    printf "\n  ${CYN}Screen size${RST} ${DIM}(WIDTHxHEIGHT of your device) [640x480]${RST}\n  > "
    read -r size
    size=${size:-640x480}
    case "$size" in
        [1-9]*x[1-9]*) width=${size%x*}; height=${size#*x}; break ;;
        *) printf "  ${RED}format: 640x480${RST}\n" ;;
    esac
done

chromium=$(grep -o 'CHROMIUM = "[^"]*"' generate.py | cut -d'"' -f2)
if [ ! -x "$chromium" ]; then
    for c in "$(command -v chromium 2>/dev/null || true)" \
             /opt/homebrew/bin/chromium \
             "/Applications/Chromium.app/Contents/MacOS/Chromium" \
             "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
        if [ -n "$c" ] && [ -x "$c" ]; then chromium="$c"; break; fi
    done
fi
if [ -x "$chromium" ]; then
    printf "  ${GRN}✓${RST} chromium: ${DIM}%s${RST}\n" "$chromium"
else
    printf "  ${RED}✗ chromium not found${RST} — install it (macOS: brew install --cask chromium) and rerun\n\n"
    exit 1
fi

if python3 -c "import PIL" 2>/dev/null; then
    printf "  ${GRN}✓${RST} pillow installed\n"
else
    printf "  ${YLW}!${RST} pillow missing. ${CYN}Install now?${RST} ${DIM}[Y/n]${RST} "
    read -r yn
    case "$yn" in
        n|N) printf "  ${RED}pillow is required${RST} — pip3 install pillow, then rerun\n\n"; exit 1 ;;
        *) pip3 install pillow ;;
    esac
fi

python3 - "$user" "$chromium" "$width" "$height" <<'EOF'
import re, sys
from pathlib import Path
user, chromium, width, height = sys.argv[1:5]
p = Path("generate.py")
t = p.read_text()
t = re.sub(r'^USER = .*', f'USER = "{user}"', t, flags=re.M)
t = re.sub(r'^CHROMIUM = .*', f'CHROMIUM = "{chromium}"', t, flags=re.M)
t = re.sub(r'^WIDTH = .*', f'WIDTH = {width}', t, flags=re.M)
t = re.sub(r'^HEIGHT = .*', f'HEIGHT = {height}', t, flags=re.M)
p.write_text(t)
EOF
printf "  ${GRN}✓${RST} generate.py configured for ${B}%s${RST} at ${B}%sx%s${RST}\n" "$user" "$width" "$height"

printf "\n  ${DIM}test render...${RST}\n"
python3 generate.py
printf "  ${GRN}✓${RST} out/github-dashboard.png rendered\n"

started=""
if [ "$(uname)" = "Darwin" ]; then
    case "$PWD" in
        "$HOME/Documents"*)
            printf "\n  ${YLW}!${RST} project lives under ~/Documents — macOS blocks launchd there (privacy/TCC).\n"
            printf "    Move it (e.g. ~/Projects) to enable start-at-login; for now run ./run.sh\n"
            ;;
        *)
            printf "\n  ${CYN}Start at login?${RST} ${DIM}(launchd agent) [Y/n]${RST} "
            read -r yn
            case "$yn" in
                n|N) ;;
                *)
                    label="com.$(whoami).commit-frame"
                    plist="$HOME/Library/LaunchAgents/$label.plist"
                    cat > "$plist" <<EOF2
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$label</string>
    <key>ProgramArguments</key><array><string>$PWD/run.sh</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>$HOME/Library/Logs/commit-frame.log</string>
    <key>StandardErrPath</key><string>$HOME/Library/Logs/commit-frame.log</string>
</dict>
</plist>
EOF2
                    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
                    launchctl bootstrap "gui/$(id -u)" "$plist"
                    printf "  ${GRN}✓${RST} launchd agent running — starts with your Mac ${DIM}(logs: ~/Library/Logs/commit-frame.log)${RST}\n"
                    started=1
                    ;;
            esac
            ;;
    esac
fi
[ -n "$started" ] || printf "\n  ${DIM}start serving with:${RST} ./run.sh\n"

ip=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')
printf "\n  ${GRN}${B}done${RST} — point your client at ${B}http://%s:8000/github-dashboard.png${RST}\n\n" "${ip:-<host>}"
