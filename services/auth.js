/*********************************************
 *  Auth Middleware — x-token header
 *********************************************/

const crypto = require('crypto');

module.exports = function createAuthMiddleware(validToken) {
    return (req, res, next) => {
        const token = req.headers['x-token'];

        if (!token) {
            return res.status(401).json({
                success: false,
                error:   'Missing x-token header.'
            });
        }

        // Timing-safe comparison to prevent timing attacks
        const a = Buffer.from(String(token));
        const b = Buffer.from(String(validToken));

        if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
            return res.status(403).json({
                success: false,
                error:   'Invalid token.'
            });
        }

        next();
    };
};
