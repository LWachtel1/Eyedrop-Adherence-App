import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthChecker extends ChangeNotifier {
  String? uid;

  AuthChecker() {
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      uid = user?.uid;
      notifyListeners(); // Notify all listening widgets
    });
  }

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => user != null;

  /**Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }**/
}