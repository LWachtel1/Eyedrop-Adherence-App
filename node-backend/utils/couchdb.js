/**
 * defines helper functions for couchdb 
 * helper functions: 
 * check if CouchDB is running,
 * check if database exists,
 * password generation 
 * 
 */


const nano = require('nano')(process.env.COUCHDB_URL); //CouchDB client
const crypto = require('crypto'); //for dynamic password generation for individual CouchDB user



//Checks CouchDB is running before Node server runs
async function checkCouchDB() {
    try {
        await nano.db.list();
        console.log('CouchDB connection verified.');
    } catch (error) {
        console.error('Failed to connect to CouchDB:', error.message);
        process.exit(1); // Exit process if database is unreachable
    }
}

//Returns whole user database in CouchDB. Creates if does not already exist.
async function getUserDatabase(userId) {
    try {
        const dbName = 'users_data';
        //retrieves a list of all databases in CouchDB
        const dbList = await nano.db.list();

        if (!dbList.includes(dbName)) {
            await nano.db.create(dbName);
            console.log(`Created shared database: ${dbName}`);
        }
        //returns a database instance for interacting with the user's database
        return nano.use(dbName);
    } catch (error) {
        console.error(`Error creating/accessing database:`, error);
        throw new Error('Database error');
    }
}

//generates secure password for each user while avoiding need for storing it 
function generateCouchDBPassword(userId) {
    const secretKey = process.env.FIREBASE_SECRET_KEY; // 🔐 Securely stored key
    return crypto.createHmac('sha256', secretKey).update(userId).digest('hex');
}

module.exports = { 
    generateCouchDBPassword,
    getUserDatabase, checkCouchDB
};