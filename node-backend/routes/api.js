/**
 * Defines API routes
 */

//!!!DOES NOT DEFINE ALL CRUD Operations


const express = require('express');
const { ensureCouchDBUserExists } = require('../controllers/couchdbController');
const { userProxy } = require('../controllers/syncController');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getUserDatabase } = require('../utils/couchdb');


const router = express.Router();



//endpoint that can be used by client to check if CouchDB server is running
router.get('/status', async (req, res) => {
    try {
        const dbs = await nano.db.list();
        res.json({ status: "OK", couchdb: dbs.length > 0 ? "Connected" : "No DBs found" });
    } catch (error) {
        res.status(500).json({ status: "Error", message: "CouchDB connection failed" });
    }
});

//Route for manual save of individual documents (to service  requests from flutter front end)
router.post('/save-data', verifyFirebaseToken, async (req, res) => {
    const db = await getUserDatabase(req.user.uid);
    const userId = req.user.uid;
    //Adds userId to the document to ensure ownership tracking in the shared user_data database
    //(assumes flutter front-end does not provide user ID field in its document)
    const newDoc = { ...req.body, userId }; 
    try {
        const response = await db.insert(newDoc);
        res.json(response);
    } catch (error) {
        res.status(500).json({ error: 'Failed to save data' });
    }
});




//SYNC MIDDLEWARE START

// Middleware to filter allowed HTTP methods before proxying
router.use('/sync', verifyFirebaseToken, (req, res, next) => {
    if (!['GET', 'PUT', 'POST', 'DELETE'].includes(req.method)) {
        return res.status(405).json({ error: "Method Not Allowed" });
    }
    next();
});

// Middleware for checking if CouchDB user exists before syncing
router.use('/sync', verifyFirebaseToken, async (req, res, next) => {
    await ensureCouchDBUserExists(req.user.uid);
    next();
});




/** 
 * The actual sync route
 * Reverse Proxy for bidrectional syncing between a local PouchDB sync and CouchDB
 * sets up middleware function for routes beginning with /sync
 * first - authenticates user with verifyFirebaseToken callback function
 * this is followed by an asynchronous anonymous callback function
*/

router.use('/sync', verifyFirebaseToken, userProxy);

//SYNC MIDDLEWARE END

// Endpoint to Flutter app that returns the sync endpoint so Flutter app can intiate syncing
//from the client side
router.get('/get-db-url', verifyFirebaseToken, (req, res) => {
    res.json({ dbUrl: `${config.COUCHDB_URL}/users_data` });
});



module.exports = router;