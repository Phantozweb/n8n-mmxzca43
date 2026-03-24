/*********************************************
 *  Tunnel Service — importable helper
 *  (Used by tunnel-wrapper.js, also usable standalone)
 *********************************************/

const { spawn } = require('child_process');

/**
 * Start cloudflared and return the public URL.
 */
function startCloudflared(port) {
    return new Promise((resolve, reject) => {
        const proc = spawn('cloudflared', [
            'tunnel', '--url', `http://localhost:${port}`, '--no-autoupdate'
        ], { stdio: ['ignore', 'pipe', 'pipe'] });

        let output   = '';
        let resolved = false;

        function check(chunk) {
            output += chunk.toString();
            const match = output.match(/https:\/\/[a-zA-Z0-9\-]+\.trycloudflare\.com/);
            if (match && !resolved) {
                resolved = true;
                resolve({ url: match[0], process: proc });
            }
        }

        proc.stdout.on('data', check);
        proc.stderr.on('data', check);
        proc.on('error', err => { if (!resolved) { resolved = true; reject(err); } });

        setTimeout(() => {
            if (!resolved) { resolved = true; proc.kill(); reject(new Error('Timeout')); }
        }, 30000);
    });
}

/**
 * Start localtunnel and return the public URL.
 */
async function startLocaltunnel(port) {
    const localtunnel = require('localtunnel');
    const tunnel = await localtunnel(port);
    return { url: tunnel.url, tunnel };
}

module.exports = { startCloudflared, startLocaltunnel };
