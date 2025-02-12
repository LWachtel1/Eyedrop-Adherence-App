import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
//Used to fetch the current user's authentication token
import 'package:firebase_auth/firebase_auth.dart';


///The main API for PouchDB interactions
///
///It provides CRUD operations that can be called from anywhere in Flutter app.
class PouchDBService {

  //creates a private static instance of PouchDBService when class first loads
  static final PouchDBService _instance = PouchDBService._internal();

  //private named constructor is called  only once to initialise _instance.
  PouchDBService._internal();

  //factory constructor always returns the same _instance, so only 1 PouchDBService instance is made.
  factory PouchDBService() => _instance;

  late WebViewController _controller;
// Completer that completes when the controller is set.
  final Completer<void> _initializedCompleter = Completer<void>();

 //Method called by the pouchdb_background widget once the WebView is ready.
  void initialize(WebViewController controller) {
    if (!_initializedCompleter.isCompleted) {
      _controller = controller;
      _initializedCompleter.complete();
    }
  }

    /// Returns a future that completes when initialization is finished.
  Future<void> ensureInitialized() async {
    return _initializedCompleter.future;
  }

  //Retrieves the Firebase authentication token of the logged-in user.
//The token will be sent to the WebView for authentication purposes in database synchronization.
Future<String?> getAuthToken() async {
  try{
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; //handles case where user is null
    // Force a token refresh to get the latest token.
    return await user.getIdToken(true);  // true forces the refresh
  } catch(e){
     print("Error fetching auth token: $e");
    return null;
  }
  
}

Future<void> checkUserDoc(String userId) async {
  await ensureInitialized();
  String jsCode = "checkUserDoc('$userId');";
  await _controller.runJavaScript(jsCode);
}


Future<void> startPouchDBSync() async {
  //Fetches Firebase authentication token and user ID.
  String? token = await getAuthToken();
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  if (token == null || userId == null) {
    print("User is not authenticated");
    return;
  }

  
  
 
  //JS running inside of webview cannot directly access Firebase auth
  //so Flutter injects token into cookie to send it securely - Webview can read cookies
  _controller.runJavaScript("document.cookie = 'authToken=$token; path=/; Secure;';");

   _controller.runJavaScript("startSync('$userId');");

}

  // Method to add a document via JavaScript (using WebView)
  Future<void> addDocumentToDB(Map<String, dynamic> document) async {
  // Convert the document to JSON
  String jsonDocument = jsonEncode(document);

  // JavaScript code to add the JSON-encoded document using PouchDB's `put` method
  String jsCode = '''
    addDocument($jsonDocument);
  ''';
  await _controller.runJavaScript(jsCode);

  }

  

  // Method to fetch documents via JavaScript (using WebView)
  Future<void> fetchDocuments() async {

    String jsCode = '''
      fetchDocuments().then(result => {
        FlutterChannel.postMessage(JSON.stringify(result));
      });
    ''';
    
    
    try {
      await _controller.runJavaScript(jsCode);
    } catch (e) {
      print("Error fetching documents: $e");
    }
  }

  //Updates the auth token (e.g. when Firebase detects a token change).
    Future<void> updateAuthToken(String token) async {
    await ensureInitialized();
    String jsCode = "document.cookie = 'authToken=$token; path=/; Secure;';";
    _controller.runJavaScript(jsCode);
    }
  
  

}