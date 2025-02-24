//Handles loading of env variables

require('dotenv').config();  //used to load environment variables from a .env file

module.exports = {
    COUCHDB_URL: process.env.COUCHDB_URL,
    FIREBASE_SECRET_KEY: process.env.FIREBASE_SECRET_KEY,
    SERVICEACCOUNT_KEYPATH: process.env.SERVICEACCOUNT_KEYPATH,
    PORT : process.env.PORT,
    NGROK_AUTHTOKEN: process.env.NGROK_AUTHTOKEN,
    NGROK_DOMAIN: process.env.NGROK_DOMAIN
};
