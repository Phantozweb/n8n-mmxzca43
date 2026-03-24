/*********************************************
 *  FocusCaseX — Tunnel Wrapper
 *  Managed by pm2. Auto-restarts on failure.
 *  Tries cloudflared first, falls back to localtunnel.
 *********************************************/

const fs         = require('fs-extra');
const path       = require('path');
const tunnelSvc  = require('./services/tunnel');
const cryptoSvc  = require('./services/crypto');

const STATE_FILE  = path.join(__dirname, '.tunnel-state.json');
const CONFIG_FILE = path.join(__dirname, 'config.json');
const TOKEN_FILE  = path.join(__dirname, '.access-token.txt');

let config;
try {
    config = fs.readJsonSync(CONFIG_FILE);
} catch (err) {
    console.error('[Tunnel] Cannot read config.json:', err.message);
    process.exit(1);
}

const PORT            = config.port || 3000;
const PRIMARY_TUNNEL  = config.tunnel || 'cloudflared';
const FALLBACK_TUNNEL = config.fallbackTunnel || 'localtunnel';

// ── State management ──────────────────────
function writeState(type, url, status) {
    const state = {
        type,
        url,
        status,
        startedAt: new Date().toISOString(),
        pid: process.pid
    };
    fs.writeJsonSync(STATE_FILE, state, { spaces: 2 });
    console.log(`[Tunnel] State: ${status} via ${type} → ${url}`);
}

function writeAccessToken(url) {
    try {
        const encrypted = cryptoSvc.encodeAccess(url, config.token);
        fs.writeFileSync(TOKEN_FILE, encrypted, 'utf8');
        console.log('[Tunnel] Access token written to .access-token.txt');
    } catch (err) {
        console.error('[Tunnel] Failed to write access token:', err.message);
    }
}

// ── Main ──────────────────────────────────
async function main() {
    console.log('[Tunnel] Starting tunnel manager...');
    console.log(`[Tunnel] Primary: ${PRIMARY_TUNNEL}, Fallback: ${FALLBACK_TUNNEL}`);

    const strategies = {
        cloudflared: async () => {
            const { url, process: proc } = await tunnelSvc.startCloudflared(PORT);
            writeState('cloudflared', url, 'active');
            writeAccessToken(url);

            proc.on('exit', (code) => {
                console.error(`[Tunnel] cloudflared exited with code ${code}. pm2 will restart.`);
                writeState('cloudflared', '', 'dead');
                process.exit(1);
            });
            return { url };
        },
        localtunnel: async () => {
            const { url, tunnel } = await tunnelSvc.startLocaltunnel(PORT);
            writeState('localtunnel', url, 'active');
            writeAccessToken(url);

            tunnel.on('close', () => {
                console.error('[Tunnel] localtunnel closed. pm2 will restart.');
                writeState('localtunnel', '', 'dead');
                process.exit(1);
            });
            return { url };
        }
    };

    const primary  = strategies[PRIMARY_TUNNEL];
    const fallback = strategies[FALLBACK_TUNNEL];

    // Try primary
    if (primary) {
        try {
            const result = await primary();
            console.log(`[Tunnel] ✓ Connected via ${PRIMARY_TUNNEL}: ${result.url}`);
            return; // Keep process alive
        } catch (err) {
            console.error(`[Tunnel] ${PRIMARY_TUNNEL} failed: ${err.message}`);
        }
    }

    // Try fallback
    if (fallback && FALLBACK_TUNNEL !== PRIMARY_TUNNEL) {
        try {
            const result = await fallback();
            console.log(`[Tunnel] ✓ Connected via ${FALLBACK_TUNNEL} (fallback): ${result.url}`);
            return;
        } catch (err) {
            console.error(`[Tunnel] ${FALLBACK_TUNNEL} failed: ${err.message}`);
        }
    }

    // All failed
    console.error('[Tunnel] All tunnel strategies failed. pm2 will retry.');
    writeState('none', '', 'failed');
    process.exit(1);
}

// ── Graceful shutdown ─────────────────────
process.on('SIGTERM', () => {
    console.log('[Tunnel] SIGTERM received. Shutting down.');
    fs.removeSync(STATE_FILE);
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('[Tunnel] SIGINT received. Shutting down.');
    fs.removeSync(STATE_FILE);
    process.exit(0);
});

main().catch(err => {
    console.error('[Tunnel] Fatal:', err.message);
    process.exit(1);
});
