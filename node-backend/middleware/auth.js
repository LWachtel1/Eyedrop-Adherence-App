/**
 * Allows verificaiton of firebase ID tokens
 */

const admin = require('firebase-admin'); //allows you to interact with Firebase

//middleware callback function to verify Firebase Auth Token 
/*
My app, which is a client of Firebase Authentication, communicates with this custom node.js
backend. Therefore, we need to be able to identify any currently signed-in user on this server 
itself.
https://firebase.google.com/docs/auth/admin/verify-id-tokens

Essentially allows authentication of user before they are allowed to use subsequent node server 
functionality

Must also check token has not been revoked ("expiry")
https://firebase.google.com/docs/auth/admin/manage-sessions?_gl=1*1tol4rg*_up*MQ..*_ga*MTAwMTU1OTg4Ny4xNzM4Mjc3NDQy*_ga_CW55HF8NVT*MTczODI3NzQ0MS4xLjAuMTczODI3NzQ0MS4wLjAuMA..#detect_id_token_revocation
*/
async function verifyFirebaseToken(req, res, next) {
    try {

        //extracts the Authorization header from the request
        const authHeader = req.headers.authorization;

        //checks if authHeader exists or does not start with Bearer - if either true, return error
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: "Unauthorized" });
        }
        //splits the string "Bearer <FirebaseToken>" to retrieve only <FirebaseToken> 
        const token = authHeader.split(' ')[1];
        
        
        if (!token) return res.status(401).json({ error: "Unauthorized" });

        const decodedToken = await admin.auth().verifyIdToken(token, true); // Check expiry
        req.user = decodedToken;
        next();
    } catch (error) {
        if (error.code === "auth/id-token-expired") {
            return res.status(401).json({ error: "Token expired. Please refresh." });
        }
        res.status(403).json({ error: "Invalid token" });
    }
}

module.exports = {
    verifyFirebaseToken
};