/*********************************************
 *  Storage Service — Multi-file JSON store
 *********************************************/

const fs   = require('fs-extra');
const path = require('path');

function filePath(dataDir, name) {
    // Sanitize: only allow alphanumeric, dash, underscore
    const safe = String(name).replace(/[^a-zA-Z0-9_\-]/g, '');
    if (!safe) throw new Error('Invalid file name.');
    return path.join(dataDir, `${safe}.json`);
}

async function read(dataDir, name) {
    const fp = filePath(dataDir, name);
    if (!(await fs.pathExists(fp))) return [];
    return fs.readJson(fp);
}

async function write(dataDir, name, data) {
    await fs.ensureDir(dataDir);
    await fs.writeJson(filePath(dataDir, name), data, { spaces: 2 });
}

async function append(dataDir, name, entry) {
    await fs.ensureDir(dataDir);
    const fp = filePath(dataDir, name);
    let existing = [];

    if (await fs.pathExists(fp)) {
        const raw = await fs.readJson(fp);
        existing = Array.isArray(raw) ? raw : [raw];
    }

    existing.push(entry);
    await fs.writeJson(fp, existing, { spaces: 2 });
}

async function listFiles(dataDir) {
    await fs.ensureDir(dataDir);
    const entries = await fs.readdir(dataDir);
    return entries
        .filter(f => f.endsWith('.json'))
        .map(f => f.replace('.json', ''));
}

async function deleteFile(dataDir, name) {
    const fp = filePath(dataDir, name);
    if (!(await fs.pathExists(fp))) {
        throw new Error(`File ${name}.json does not exist.`);
    }
    await fs.remove(fp);
}

module.exports = { read, write, append, listFiles, deleteFile };
