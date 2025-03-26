import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EducationScreen extends StatefulWidget {
  static const String id = 'education_screen';

  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.moorfields.nhs.uk/eye-conditions'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
