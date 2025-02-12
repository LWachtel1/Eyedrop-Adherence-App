import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; //for android 
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; //for iOS

//Used to fetch the current user's authentication token
import 'package:firebase_auth/firebase_auth.dart';

 
///UNUSED
class PouchDBBackground extends StatefulWidget {
  @override
  _PouchDBBackgroundState createState() => _PouchDBBackgroundState();
}

class _PouchDBBackgroundState extends State<PouchDBBackground> {
  //controller to manage the web view
  late WebViewController _controller; 

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;

    //checking the platform type to set platform specific parameters
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      //iOS
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      //android
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller  = WebViewController.fromPlatformCreationParams(params);

    
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) //enables JavaScript to run inside webview
      
      //creates JS channel to send messages from JS inside webview to flutter
      //FlutterChannel.postMessage("Sync completed successfully");

      ..addJavaScriptChannel(
      'FlutterChannel',
      onMessageReceived: (JavaScriptMessage message) {
        handleJavaScriptMessage(message.message);
      },

      ) 
      ..loadRequest(Uri.parse('assets/database/pouchdb_connect.html')); 
      //loads the JS code to interact with PouchDB


  }

  void handleJavaScriptMessage(String message) {
  print("Received from WebView: $message"); //prints message to standard output

  }

  //Builds the hidden webview
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Visibility(
        visible: false, // hides webview so it can run without disrupting user interface

        //if _controller has not be assigned properly i.e., is null, handles this error
        //while avoiding program crash
        child: _controller != null
            ? WebViewWidget(controller: _controller)
            : SizedBox(), 
  
      ),
    );
  }


//Retrieves the Firebase authentication token of the logged-in user.
//The token will be sent to the WebView for authentication purposes in database synchronization.
Future<String?> getAuthToken() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return null; //handles case where user is null
  return await user.getIdToken();
}



void startPouchDBSync() async {
  //Fetches Firebase authentication token and user ID.
  String? token = await getAuthToken();
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  if (token == null || userId == null) {
    print("User is not authenticated");
    return;
  }

  String jsCode = '''
    startSync('$userId');
  ''';
  
  // Set a custom HTTP header with the Firebase token to send it securely
  _controller.runJavaScript(jsCode);
  _controller.runJavaScript(
    "document.cookie = 'authToken=$token; path=/; Secure; HttpOnly';"
  );
}



  // Method to add a document via JavaScript (using WebView)
  void addDocumentToDB(Map<String, dynamic> document) {
  // Convert the document to JSON
  String jsonDocument = jsonEncode(document);

  // JavaScript code to add the JSON-encoded document using PouchDB's `put` method
  String jsCode = '''
    addDocument($jsonDocument);
  ''';
  _controller.runJavaScript(jsCode);
  }

  

  // Method to fetch documents via JavaScript (using WebView)
  Future<void> fetchDocuments() async {

    String jsCode = '''
      fetchDocuments().then(result => {
        FlutterChannel.postMessage(JSON.stringify(result));
      });
    ''';
    
    
    try {
      _controller.runJavaScript(jsCode);
    } catch (e) {
      print("Error fetching documents: $e");
    }
  }
  

}

