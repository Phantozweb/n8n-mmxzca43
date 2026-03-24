#!/data/data/com.termux/files/usr/bin/bash
###############################################
#  FocusCaseX — Stop
###############################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "[*] Stopping FocusCaseX..."

pm2 delete focuscasex-server 2>/dev/null \
    && echo -e "${GREEN}[✓] Server stopped.${NC}" \
    || echo "[·] Server was not running."

pm2 delete focuscasex-tunnel 2>/dev/null \
    && echo -e "${GREEN}[✓] Tunnel manager stopped.${NC}" \
    || echo "[·] Tunnel manager was not running."

pkill -f "cloudflared tunnel" 2>/dev/null \
    && echo -e "${GREEN}[✓] Cloudflared process killed.${NC}" \
    || echo "[·] No cloudflared process."

pm2 save 2>/dev/null || true

# Release wake-lock
termux-wake-unlock 2>/dev/null \
    && echo -e "${GREEN}[✓] Wake-lock released.${NC}" \
    || echo "[·] No wake-lock to release."

# Clean state files
rm -f "$SCRIPT_DIR/.tunnel-state.json"
rm -f "$SCRIPT_DIR/.access-token.txt"

echo ""
echo "================================================="
echo "  FocusCaseX shutdown complete."
echo "  24/7 mode deactivated."
echo "================================================="
echo ""
