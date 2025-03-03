//UNUSED 

/*
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TokenChecker {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authListener;
  String? _currentToken;

  //Start Listening for Token Changes
  void startListeningForTokenChanges(Function(String) onTokenRefresh) {
    _authListener = _auth.idTokenChanges().listen((User? user) async {
      if (user != null) {
        String? token = await user.getIdToken(true);
        _currentToken = token;
        onTokenRefresh(token!); // Send the updated token to WebView
      }
    });
  }

  //Manually Refresh Token if Needed
  Future<void> refreshToken(Function(String) onTokenRefresh) async {
    User? user = _auth.currentUser;
    if (user != null) {
      String? newToken = await user.getIdToken(true);
      _currentToken = newToken;
      onTokenRefresh(newToken!);
    }
  }

  //Get Latest Token
  Future<String?> getCurrentToken() async {
    return _currentToken ?? await _auth.currentUser?.getIdToken();
  }

  //Stop Listening When No Longer Needed
  void dispose() {
    _authListener?.cancel();
  }
}
*/