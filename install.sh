#!/data/data/com.termux/files/usr/bin/bash
###############################################
#  FocusCaseX — Termux Installer (v2)
#  Tunnels: cloudflared + localtunnel
#  24/7 via pm2 + wake-lock + Termux:Boot
###############################################
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$INSTALL_DIR"

echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}       FocusCaseX Installer  v2.0${NC}"
echo -e "${CYAN}       24/7 · Cloudflared · LocalTunnel${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# ── 0. Storage permission ─────────────────
echo -e "[0/9] Requesting storage access..."
if [ ! -d "/storage/emulated/0" ]; then
    termux-setup-storage
    echo "      Grant the permission prompt, then wait..."
    sleep 4
fi
if [ ! -d "/storage/emulated/0" ]; then
    echo -e "${RED}[✗] Storage access not available. Grant permission and re-run.${NC}"
    exit 1
fi
echo -e "${GREEN}      ✓ Storage accessible.${NC}"

# ── 1. System packages ────────────────────
echo "[1/9] Installing system packages..."
pkg update -y -q 2>/dev/null
pkg install -y -q nodejs git wget unzip termux-services 2>/dev/null || true

# ── 2. npm dependencies ───────────────────
echo "[2/9] Installing npm dependencies..."
npm install --production 2>&1 | tail -1

# ── 3. pm2 ─────────────────────────────────
echo "[3/9] Installing pm2..."
if ! command -v pm2 &>/dev/null; then
    npm install -g pm2 2>&1 | tail -1
    echo -e "${GREEN}      ✓ pm2 installed.${NC}"
else
    echo "      pm2 already installed."
fi

# ── 4. Cloudflared ─────────────────────────
echo "[4/9] Installing cloudflared..."
if ! command -v cloudflared &>/dev/null; then
    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64) CF_ARCH="arm64" ;;
        armv7l|armv8l) CF_ARCH="arm" ;;
        x86_64)  CF_ARCH="amd64" ;;
        i686)    CF_ARCH="386" ;;
        *)       CF_ARCH="arm64" ;;
    esac
    CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}"
    echo "      Downloading cloudflared (${CF_ARCH})..."
    wget -q "$CF_URL" -O "$PREFIX/bin/cloudflared" 2>/dev/null
    if [ $? -eq 0 ] && [ -s "$PREFIX/bin/cloudflared" ]; then
        chmod +x "$PREFIX/bin/cloudflared"
        echo -e "${GREEN}      ✓ cloudflared installed.${NC}"
    else
        rm -f "$PREFIX/bin/cloudflared"
        echo -e "${YELLOW}      ⚠ cloudflared download failed. Will use localtunnel as fallback.${NC}"
    fi
else
    echo "      cloudflared already installed."
fi

# ── 5. Verify localtunnel ─────────────────
echo "[5/9] Verifying localtunnel (npm)..."
if node -e "require('localtunnel')" 2>/dev/null; then
    echo -e "${GREEN}      ✓ localtunnel available.${NC}"
else
    echo -e "${YELLOW}      ⚠ localtunnel not found in node_modules. Re-running npm install...${NC}"
    npm install localtunnel --save --production 2>&1 | tail -1
fi

# ── 6. Storage directory ──────────────────
echo "[6/9] Creating data directory..."
DATA_PATH="/storage/emulated/0/FocusCaseX"
mkdir -p "$DATA_PATH"
echo "      $DATA_PATH"

# ── 7. Generate config ────────────────────
echo "[7/9] Generating config.json..."
if [ -f "config.json" ]; then
    echo "      config.json exists. Skipping (delete to regenerate)."
else
    TOKEN=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
    cat > config.json <<CONFIGEOF
{
  "dataPath": "$DATA_PATH",
  "token": "$TOKEN",
  "port": 3000,
  "tunnel": "cloudflared",
  "fallbackTunnel": "localtunnel"
}
CONFIGEOF
    echo -e "${GREEN}      ✓ Config generated with secure token.${NC}"
fi

# ── 8. Termux:Boot integration ────────────
echo "[8/9] Setting up Termux:Boot (24/7)..."
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"
cp "$INSTALL_DIR/boot/focuscasex-boot.sh" "$BOOT_DIR/focuscasex-boot.sh"
chmod +x "$BOOT_DIR/focuscasex-boot.sh"
echo -e "${GREEN}      ✓ Boot script installed.${NC}"
echo -e "${YELLOW}      ⚠ Install Termux:Boot from F-Droid for auto-start on reboot.${NC}"

# ── 9. Register CLI commands ──────────────
echo "[9/9] Registering CLI commands..."
chmod +x start.sh stop.sh status.sh ui/banner.sh
chmod +x boot/focuscasex-boot.sh
ln -sf "$INSTALL_DIR/start.sh"  "$PREFIX/bin/focuscasex-start"
ln -sf "$INSTALL_DIR/stop.sh"   "$PREFIX/bin/focuscasex-stop"
ln -sf "$INSTALL_DIR/status.sh" "$PREFIX/bin/focuscasex-status"
echo -e "${GREEN}      ✓ Commands registered.${NC}"

# ── Configure pm2 startup ─────────────────
pm2 startup 2>/dev/null || true

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}    ✅  FocusCaseX Installed (24/7 Ready)${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo "  Start   :  focuscasex-start"
echo "  Stop    :  focuscasex-stop"
echo "  Status  :  focuscasex-status"
echo ""
echo "  Tunnel  :  cloudflared (primary)"
echo "  Fallback:  localtunnel (auto)"
echo "  24/7    :  pm2 auto-restart + wake-lock"
echo "  Boot    :  Termux:Boot (install from F-Droid)"
echo ""
echo "================================================="
echo ""
