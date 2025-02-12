/**
 * Handles logic for interacting with couchdb users
 */
const config = require('../config');
const nano = require('nano')(config.COUCHDB_URL); //CouchDB client
const { generateCouchDBPassword } = require('../utils/couchdb');



//Checks if CouchDB user exists and creates them if not
async function ensureCouchDBUserExists(userId) {
    const username = `firebase:${userId}`;
    const password = generateCouchDBPassword(userId);

    const userDoc = {
        _id: `org.couchdb.user:${username}`,
        name: username,
        type: "user",
        roles: [],
        password: password
    };

    try {
        // First, check if the user already exists in the _users database
        const existingUser = await nano.use('_users').get(`org.couchdb.user:${username}`);
        console.log(`CouchDB user already exists: ${username}`);
        return; // Exit early if the user exists
    } catch (error) {
        // If the user doesn't exist (404), proceed with creation
        if (error.statusCode === 404) {
            try {
                await nano.use('_users').insert(userDoc);
                console.log(`Created CouchDB user: ${username}`);
            } catch (insertError) {
                console.error(`Error creating CouchDB user:`, insertError);
                throw new Error('Failed to create CouchDB user');
            }
        } else {
            console.error(`Error checking CouchDB user existence:`, error);
            throw new Error('Failed to check CouchDB user existence');
        }
    }
}

module.exports = {
    ensureCouchDBUserExists
};