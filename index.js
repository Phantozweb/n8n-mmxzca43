/*********************************************
 *  FocusCaseX — Main API Server
 *********************************************/

const express        = require('express');
const path           = require('path');
const fs             = require('fs-extra');
const storage        = require('./services/storage');
const authMiddleware = require('./services/auth');

// ── Load config ───────────────────────────
const configPath = path.join(__dirname, 'config.json');

if (!fs.existsSync(configPath)) {
    console.error('[FocusCaseX] config.json not found. Run install.sh first.');
    process.exit(1);
}

const config = fs.readJsonSync(configPath);

if (!config.token || !config.dataPath) {
    console.error('[FocusCaseX] Invalid config.json. Missing token or dataPath.');
    process.exit(1);
}

fs.ensureDirSync(config.dataPath);

// ── Express ───────────────────────────────
const app = express();
app.use(express.json({ limit: '10mb' }));

// ── Health check (public) ─────────────────
app.get('/health', (_req, res) => {
    res.json({
        status:  'ok',
        service: 'FocusCaseX',
        version: '2.0.0',
        uptime:  Math.floor(process.uptime()),
        mode:    '24/7'
    });
});

// ── Tunnel status (public, no secrets) ────
app.get('/ping', (_req, res) => {
    res.json({ pong: true, time: Date.now() });
});

// ── Auth wall ─────────────────────────────
app.use(authMiddleware(config.token));

// ── GET /read ─────────────────────────────
app.get('/read', async (req, res) => {
    try {
        const file = req.query.file || 'data';
        const data = await storage.read(config.dataPath, file);
        res.json({ success: true, data });
    } catch (err) {
        console.error('[READ]', err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ── POST /write ───────────────────────────
app.post('/write', async (req, res) => {
    try {
        if (req.body === undefined || req.body === null) {
            return res.status(400).json({ success: false, error: 'Empty body.' });
        }
        const file = req.query.file || 'data';
        await storage.write(config.dataPath, file, req.body);
        res.json({ success: true, message: 'Data written.' });
    } catch (err) {
        console.error('[WRITE]', err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ── POST /append ──────────────────────────
app.post('/append', async (req, res) => {
    try {
        if (req.body === undefined || req.body === null) {
            return res.status(400).json({ success: false, error: 'Empty body.' });
        }
        const file = req.query.file || 'data';
        await storage.append(config.dataPath, file, req.body);
        res.json({ success: true, message: 'Data appended.' });
    } catch (err) {
        console.error('[APPEND]', err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ── GET /files ────────────────────────────
app.get('/files', async (_req, res) => {
    try {
        const files = await storage.listFiles(config.dataPath);
        res.json({ success: true, files });
    } catch (err) {
        console.error('[FILES]', err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ── DELETE /delete ────────────────────────
app.delete('/delete', async (req, res) => {
    try {
        const file = req.query.file;
        if (!file) return res.status(400).json({ success: false, error: 'Specify ?file=name' });
        await storage.deleteFile(config.dataPath, file);
        res.json({ success: true, message: `${file}.json deleted.` });
    } catch (err) {
        console.error('[DELETE]', err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ── 404 ───────────────────────────────────
app.use((_req, res) => {
    res.status(404).json({ success: false, error: 'Route not found.' });
});

// ── Start ─────────────────────────────────
const PORT = config.port || 3000;
app.listen(PORT, () => {
    console.log(`[FocusCaseX] Server on port ${PORT}`);
    console.log(`[FocusCaseX] Data: ${config.dataPath}`);
    console.log(`[FocusCaseX] Auth: token-protected`);
    console.log(`[FocusCaseX] Mode: 24/7`);
});
