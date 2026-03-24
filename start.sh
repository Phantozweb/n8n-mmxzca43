#!/data/data/com.termux/files/usr/bin/bash
###############################################
#  FocusCaseX — Start (24/7 mode)
###############################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Pre-flight ─────────────────────────────
if [ ! -f "config.json" ]; then
    echo -e "${RED}[✗] config.json not found. Run install.sh first.${NC}"
    exit 1
fi
if [ ! -d "node_modules" ]; then
    echo -e "${RED}[✗] node_modules missing. Run install.sh first.${NC}"
    exit 1
fi

# ── Banner ─────────────────────────────────
bash ui/banner.sh

# ── Acquire wake-lock (prevent Android killing us) ──
echo ""
echo "[*] Acquiring wake-lock for 24/7 operation..."
termux-wake-lock 2>/dev/null && \
    echo -e "${GREEN}[✓] Wake-lock acquired. CPU will stay active.${NC}" || \
    echo -e "${YELLOW}[·] Wake-lock unavailable. Install Termux:API for best 24/7 performance.${NC}"

# ── Kill previous instances ────────────────
pm2 delete focuscasex-server 2>/dev/null || true
pm2 delete focuscasex-tunnel 2>/dev/null || true
pkill -f "cloudflared tunnel" 2>/dev/null || true

# Clean stale state
rm -f .tunnel-state.json .access-token.txt

# ── Start everything via pm2 ecosystem ─────
echo "[*] Starting FocusCaseX (server + tunnel)..."
pm2 start ecosystem.config.js 2>/dev/null

sleep 2

# ── Verify server ──────────────────────────
SERVER_PID=$(pm2 pid focuscasex-server 2>/dev/null)
if [ -z "$SERVER_PID" ] || [ "$SERVER_PID" = "0" ]; then
    echo -e "${RED}[✗] Server failed to start.${NC}"
    echo "    Check: pm2 logs focuscasex-server"
    exit 1
fi
echo -e "${GREEN}[✓] Server running on port 3000  (pid $SERVER_PID)${NC}"

# ── Wait for tunnel ───────────────────────
echo "[*] Waiting for tunnel to establish..."
TRIES=0
TUNNEL_URL=""
while [ $TRIES -lt 30 ]; do
    sleep 2
    TRIES=$((TRIES + 1))
    if [ -f ".tunnel-state.json" ]; then
        TUNNEL_URL=$(node -e "
            try {
                const s = require('fs').readFileSync('.tunnel-state.json','utf8');
                const j = JSON.parse(s);
                if (j.url && j.status === 'active') process.stdout.write(j.url);
            } catch(e) {}
        " 2>/dev/null)
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
    fi
    printf "."
done
echo ""

if [ -z "$TUNNEL_URL" ]; then
    echo -e "${RED}[✗] Tunnel failed after 60s.${NC}"
    echo "    Check: pm2 logs focuscasex-tunnel"
    echo ""
    echo -e "${YELLOW}    Server is still running locally: http://localhost:3000${NC}"
    # Save pm2 state anyway
    pm2 save 2>/dev/null || true
    exit 1
fi

TUNNEL_TYPE=$(node -e "
    try {
        const s = require('fs').readFileSync('.tunnel-state.json','utf8');
        process.stdout.write(JSON.parse(s).type || 'unknown');
    } catch(e) { process.stdout.write('unknown'); }
" 2>/dev/null)

echo -e "${GREEN}[✓] Tunnel active via ${TUNNEL_TYPE}${NC}"
echo -e "${GREEN}    ${TUNNEL_URL}${NC}"

# ── Generate encrypted access token ───────
ACCESS_TOKEN=$(TUNNEL_URL="$TUNNEL_URL" node -e "
    const cryptoSvc = require('./services/crypto');
    const config    = require('./config.json');
    process.stdout.write(cryptoSvc.encodeAccess(process.env.TUNNEL_URL, config.token));
" 2>/dev/null)

# Save access token to file for later retrieval
echo "$ACCESS_TOKEN" > .access-token.txt

# ── Save pm2 process list (survives restart) ──
pm2 save 2>/dev/null || true

# ── Display ────────────────────────────────
echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}  🔑  Encrypted Access Token${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""
echo "  $ACCESS_TOKEN"
echo ""
echo -e "${CYAN}-------------------------------------------------${NC}"
echo "  Use this token in the frontend to connect."
echo "  Do NOT share raw URLs."
echo ""
echo "  Retrieve later:  focuscasex-status"
echo -e "${CYAN}=================================================${NC}"
echo ""
echo -e "${GREEN}  ✅  24/7 Mode Active${NC}"
echo "  • pm2 auto-restarts on crash"
echo "  • Wake-lock prevents CPU sleep"
echo "  • Tunnel reconnects automatically"
echo "  • Run 'focuscasex-stop' to shut down"
echo ""
echo "================================================="
echo ""
