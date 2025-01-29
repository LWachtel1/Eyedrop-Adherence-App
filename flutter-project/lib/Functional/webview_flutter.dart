import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; //for android 
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; //for iOS

 

class PouchDBBackground extends StatefulWidget {
  @override
  _PouchDBBackgroundState createState() => _PouchDBBackgroundState();
}

class _PouchDBBackgroundState extends State<PouchDBBackground> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('assets/database/pouchdb_connect.html'));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Visibility(
        visible: false, // WebView will not be visible
        child: WebViewWidget(controller: _controller)
      ),
    );
  }

  // Method to add a document via JavaScript (using WebView)
  void addDocumentToDB(Map<String, dynamic> document) {
  // Convert the document to JSON
  String jsonDocument = jsonEncode(document);
  // JavaScript code to add the document using PouchDB's `put` method
  String jsCode = '''
    addDocument($document);
  ''';
  _controller.runJavaScriptReturningResult(jsCode);
  }

  // Method to fetch documents via JavaScript (using WebView)
  Future<void> fetchDocuments() async {
    String jsCode = '''
      fetchDocuments();
    ''';

    // Evaluating JS code and handling the response
     Object result = await _controller.runJavaScriptReturningResult(jsCode);
  }
}