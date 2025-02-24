const config = require('./config');
const express = require('express'); //allows creation of the server
const apiRoutes = require('./routes/api');
const cors = require('cors');  //allows front-end to access back-end despite differing origins
const { checkCouchDB } = require('./utils/couchdb');
const ngrok = require('@ngrok/ngrok')


const admin = require('firebase-admin'); //allows you to interact with Firebase


//initialises a Firebase Admin SDK instance using a service account key file
admin.initializeApp({
    credential: admin.credential.cert(require(`${process.env.SERVICEACCOUNT_KEYPATH}`)),
});


//creates Express app
const app = express();

//Exposes locally hosted development server with a public URL to allow Android app to make requests
async function expose() {
    // Establish connectivity
    const listener = await ngrok.forward({ addr: `${config.PORT}`, authtoken: config.NGROK_AUTHTOKEN, domain:`${config.NGROK_DOMAIN}`})
    // Output ngrok url to console
    console.log(`Ingress established at: ${listener.url()}`)
  }

expose()

//Middleware 
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests from 'null' (for local development, file://)
    if (origin === null || origin === 'file://') {
      callback(null, true);  // Allow requests from local files and null origin
    } else {
      // Dynamically set origin for CORS, only allowing the origin of the request
      callback(null, origin);  // Allow the request from the exact origin
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE'],  // Define methods your server supports
  allowedHeaders: ['Content-Type', 'Authorization'],  // Allowed headers
  credentials: true,  // Allow credentials like cookies or Authorization headers
};



app.use(cors(corsOptions));

app.options('*', cors(corsOptions));  

/*
app.use((req, res, next) => {
  // Allow requests from 'null' (for local development, file://)
  res.header('Access-Control-Allow-Origin', 'null');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);  // No content for preflight requests
  }

  next();
});*/

app.use(express.json()); //parse incoming JSON requests for all requests (regardlesss of path)

app.use('/api', apiRoutes);



checkCouchDB().then(() => {
    app.listen(3000, () => console.log(`Server running on ${config.PORT}`));
});
