#!/data/data/com.termux/files/usr/bin/bash
###############################################
#  FocusCaseX — Termux:Boot auto-start
#  Place this in ~/.termux/boot/
###############################################

# Wait for system to settle after reboot
sleep 10

# Acquire wake-lock
termux-wake-lock 2>/dev/null

# Find install directory
FOCUSCASEX_DIR="$HOME/focuscasex"
if [ ! -d "$FOCUSCASEX_DIR" ]; then
    # Try common locations
    for DIR in "$HOME/projects/focuscasex" "$HOME/code/focuscasex" "/data/data/com.termux/files/home/focuscasex"; do
        if [ -d "$DIR" ]; then
            FOCUSCASEX_DIR="$DIR"
            break
        fi
    done
fi

if [ ! -f "$FOCUSCASEX_DIR/ecosystem.config.js" ]; then
    echo "[FocusCaseX Boot] Install directory not found. Exiting."
    exit 1
fi

cd "$FOCUSCASEX_DIR"

# Resurrect pm2 saved processes
pm2 resurrect 2>/dev/null

# If processes aren't running, start fresh
SERVER_PID=$(pm2 pid focuscasex-server 2>/dev/null)
if [ -z "$SERVER_PID" ] || [ "$SERVER_PID" = "0" ]; then
    pm2 start ecosystem.config.js 2>/dev/null
    pm2 save 2>/dev/null
fi

echo "[FocusCaseX Boot] System started at $(date)" >> "$FOCUSCASEX_DIR/boot.log"
