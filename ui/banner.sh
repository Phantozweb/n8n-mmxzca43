#!/data/data/com.termux/files/usr/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}         FocusCaseX Local Engine  v2.0${NC}"
echo -e "${CYAN}=================================================${NC}"
echo -e " Status   : ${GREEN}STARTING${NC}"
echo -e " Mode     : 24/7 Local Clinical Database"
echo -e " Security : Token Protected Access"
echo -e " Tunnel   : ${YELLOW}Cloudflared + LocalTunnel fallback${NC}"
echo -e " Upkeep   : pm2 auto-restart + wake-lock"
echo -e "${CYAN}=================================================${NC}"
