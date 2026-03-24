/*********************************************
 *  Crypto Service — AES access-token codec
 *********************************************/

const CryptoJS = require('crypto-js');

/**
 * Encrypt url + token into a single access token string.
 */
function encodeAccess(url, token) {
    const payload   = JSON.stringify({ url, token });
    const encrypted = CryptoJS.AES.encrypt(payload, token);
    return encrypted.toString();
}

/**
 * Decrypt an access token back into { url, token }.
 */
function decodeAccess(accessToken, token) {
    try {
        const bytes     = CryptoJS.AES.decrypt(accessToken, token);
        const decrypted = bytes.toString(CryptoJS.enc.Utf8);

        if (!decrypted) throw new Error('Empty result.');

        return JSON.parse(decrypted);
    } catch (_err) {
        throw new Error('Invalid access token or wrong passphrase.');
    }
}

module.exports = { encodeAccess, decodeAccess };
