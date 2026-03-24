#!/data/data/com.termux/files/usr/bin/bash
###############################################
#  FocusCaseX — Status Check
###############################################

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}       FocusCaseX Status${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# Server check
SERVER_PID=$(pm2 pid focuscasex-server 2>/dev/null)
if [ -n "$SERVER_PID" ] && [ "$SERVER_PID" != "0" ]; then
    UPTIME=$(pm2 jlist 2>/dev/null | node -e "
        let d='';process.stdin.on('data',c=>d+=c);
        process.stdin.on('end',()=>{
            try{const a=JSON.parse(d);const p=a.find(x=>x.name==='focuscasex-server');
            if(p){const u=Math.floor((Date.now()-p.pm2_env.pm_uptime)/1000);
            const h=Math.floor(u/3600);const m=Math.floor((u%3600)/60);
            process.stdout.write(h+'h '+m+'m');}else process.stdout.write('?');}
            catch(e){process.stdout.write('?');}});
    " 2>/dev/null)
    echo -e "  Server   : ${GREEN}RUNNING${NC}  (pid $SERVER_PID, uptime ${UPTIME:-?})"
else
    echo -e "  Server   : ${RED}STOPPED${NC}"
fi

# Tunnel check
TUNNEL_PID=$(pm2 pid focuscasex-tunnel 2>/dev/null)
if [ -n "$TUNNEL_PID" ] && [ "$TUNNEL_PID" != "0" ]; then
    echo -e "  Tunnel   : ${GREEN}RUNNING${NC}  (pid $TUNNEL_PID)"
else
    echo -e "  Tunnel   : ${RED}STOPPED${NC}"
fi

# Tunnel URL
if [ -f ".tunnel-state.json" ]; then
    TURL=$(node -e "
        try{const s=require('fs').readFileSync('.tunnel-state.json','utf8');
        const j=JSON.parse(s);process.stdout.write(j.url||'none');}catch(e){process.stdout.write('none');}
    " 2>/dev/null)
    TTYPE=$(node -e "
        try{const s=require('fs').readFileSync('.tunnel-state.json','utf8');
        process.stdout.write(JSON.parse(s).type||'?');}catch(e){process.stdout.write('?');}
    " 2>/dev/null)
    if [ "$TURL" != "none" ]; then
        echo -e "  Tunnel URL: ${GREEN}${TURL}${NC}"
        echo -e "  Tunnel via: ${TTYPE}"
    else
        echo -e "  Tunnel URL: ${YELLOW}Not yet available${NC}"
    fi
else
    echo -e "  Tunnel URL: ${RED}No state file${NC}"
fi

# Access token
echo ""
if [ -f ".access-token.txt" ]; then
    echo -e "${CYAN}  🔑 Access Token:${NC}"
    echo ""
    cat .access-token.txt
    echo ""
else
    echo -e "  ${YELLOW}No access token generated yet.${NC}"
fi

# Wake lock
WAKELOCK_STATUS="unknown"
if command -v termux-wake-lock &>/dev/null; then
    # Check if wake-lock process hint exists
    if pgrep -f "termux-wake-lock" &>/dev/null || [ -f "$PREFIX/var/lock/termux-wake-lock" ]; then
        WAKELOCK_STATUS="active"
    else
        WAKELOCK_STATUS="inactive"
    fi
fi

echo ""
echo -e "  Wake-lock: ${WAKELOCK_STATUS}"
echo ""
echo -e "${CYAN}=================================================${NC}"
echo ""
