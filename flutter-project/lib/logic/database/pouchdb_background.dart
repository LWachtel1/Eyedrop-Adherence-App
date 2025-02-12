import 'dart:convert';

import 'package:eyedrop/logic/database/doc_templates.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; //for android 
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; //for iOS

//Used to fetch the current user's authentication token
import 'package:firebase_auth/firebase_auth.dart';
import 'pouchdb_service.dart'; // Import the service
 
///THe hidden WebView that continuously runs the actual PouchDB database in the background
///
///Loads pouchdb_connect.html, which contains the actual PouchDB logic.
class PouchDBBackground extends StatefulWidget {
  @override
  _PouchDBBackgroundState createState() => _PouchDBBackgroundState();
}

class _PouchDBBackgroundState extends State<PouchDBBackground> {
  //controller to manage the web view
  late WebViewController _controller; 
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _listenForTokenChanges(); //ensuring that token change listener starts as soon as  widget is created
    
    /*late final PlatformWebViewControllerCreationParams params;

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
    */
    

  }

  void _initializeWebView() {
       _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) //enables JavaScript to run inside webview
      
      //creates JS channel to send messages from JS inside webview to flutter
      //FlutterChannel.postMessage("Sync completed successfully");

      ..addJavaScriptChannel(
      'FlutterChannel',
      onMessageReceived: (JavaScriptMessage message) {
        handleJavaScriptMessage(message.message);
      },

      ) 
      //sets up navigation delegate that listens for page navigation-related events inside WebView
       ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isWebViewReady = true; //executes when the WebView completes loading the page.
            });
            //registers _controller once with PouchDBService
            PouchDBService().initialize(_controller);   

          },
        ),
      )
      //loads the JS code to interact with PouchDB
      //..loadRequest(Uri.parse('assets/database/pouchdb_connect.html'));
      ..loadFlutterAsset('assets/database/pouchdb_connect.html'); 

  } 

  void handleJavaScriptMessage(String message) {
    print("Received from WebView: $message"); //prints message to standard output

    // Parse message from JavaScript
    final Map<String, dynamic> response = jsonDecode(message);

    if (response.containsKey('exists') && response['exists'] == false) {
      // User document doesn't exist, create it
        print("User document not found. Creating user document...");
      createUserDocument();
    } else if (response.containsKey('exists') && response['exists'] == true) {
    print("User document already exists.");
  }
  }

 

Future<void> createUserDocument() async {
  final pouchDBService = PouchDBService();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  Map<String, dynamic> userDoc = createUserDocTemplate(user.uid);

  // Use the service to add the document.
  await pouchDBService.addDocumentToDB(userDoc);

  print("User document created for user: ${user.uid}");

}



 
  void _listenForTokenChanges() {
    //Whenever the token expires or becomes invalid
    //the Firebase SDK will detect it and trigger the idTokenChanges() listener
    FirebaseAuth.instance.idTokenChanges().listen((User? user) async {
      if (user != null) {
        String? token = await user.getIdToken(true);
        //When the listener is triggered, getIdToken(true) will force 
        //a refresh of the token, and it will be updated in the WebView using updateAuthToken() 
        if (token != null && _isWebViewReady) {
          PouchDBService().updateAuthToken(token);
        }
      }
    });
  }

  //Builds the hidden webview
    @override
  Widget build(BuildContext context) {
    // Using Offstage ensures the widget remains in the widget tree
    // even though it is not visible.
    return Offstage(
      offstage: true,
      child: WebViewWidget(controller: _controller),
    );
  }
  /*
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
  }*/

}

