const config = require('../config');
/*
extracts createProxyMiddleware function

allows creation of a middleware that will intercept requests and redirect them to a 
different target server or endpoint. Often used in dev environments to handle CORS issues or 
to forward requests to a backend server.
*/ 
const { createProxyMiddleware } = require('http-proxy-middleware');

const { generateCouchDBPassword } = require('../utils/couchdb');


//Creates a single instance of Secure Reverse Proxy to CouchDb database with Per-User Authentication
const userProxy = createProxyMiddleware({
    target: process.env.COUCHDB_URL,
    //ensures that the host header in the request is updated to match the target server
    changeOrigin: true,
    //removes /sync from the request path and replaces with users_data
    pathRewrite: { '^/sync': '/users_data' },
    
    onProxyReq: async (proxyReq, req) => {
        try {
            const userId = req.user?.uid;
            if (!userId) throw new Error("Missing user ID");
            
            //Generate the password dynamically
            const userPassword = generateCouchDBPassword(userId);
            const couchDBUsername = `firebase:${userId}`;
            const authHeader = Buffer.from(`${couchDBUsername}:${userPassword}`).toString('base64');

            //modifies the outgoing request by adding an Authorization header for CouchDB.
            proxyReq.setHeader('Authorization', `Basic ${authHeader}`);
        } catch (error) {
            console.error("Proxy Auth Error:", error);
            req.res.status(401).json({ error: "Authentication Failed" });
        }
    },
    //error handling
    onError: (err, req, res) => {
        console.error("Proxy Error:", err);
        res.status(500).json({ error: "Proxy server error" });
    }
});


module.exports = {
    userProxy
};