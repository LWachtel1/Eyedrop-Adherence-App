const config = require('./config');
const express = require('express'); //allows creation of the server
const apiRoutes = require('./routes/api');
const cors = require('cors');  //allows front-end to access back-end despite differing origins
const { checkCouchDB } = require('./utils/couchdb');

const admin = require('firebase-admin'); //allows you to interact with Firebase


//initialises a Firebase Admin SDK instance using a service account key file
admin.initializeApp({
    credential: admin.credential.cert(require(`${process.env.SERVICEACCOUNT_KEYPATH}`)),
});


//creates Express app
const app = express();

//Middleware 
app.use(cors()); //allow CORS for all requests (regardlesss of path)
app.use(express.json()); //parse incoming JSON requests for all requests (regardlesss of path)

app.use('/api', apiRoutes);


checkCouchDB().then(() => {
    app.listen(3000, () => console.log('Server running on port 3000'));
});
