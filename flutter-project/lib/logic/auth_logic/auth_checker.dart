import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The authentication state checker.
///
/// This class notifies any listeners of changes in authentication state.
class AuthChecker extends ChangeNotifier {
  String? uid;
  late final StreamSubscription<User?> _authSubscription;

  AuthChecker() {
    // Listens to stream returned by authStateChanges and returns StreamSubscription object.
    // StreamSubscription object provides a callback function whenever value changes.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // Updates app's stored user id given that a change in authentication state has occurred.
      // If a user is logged in, it assigns their Firebase uid.
      // If no user is logged in (user == null), uid is set to null.
      uid = user?.uid;

      // Tells all listening widgets to rebuild to reflect the changed authentication state.
      notifyListeners();
    }, 
    onError: (error) {
          log("Firebase Auth Error: $error");
          uid = null; // Reset authentication state on error.
          notifyListeners();
    },);
  }

  /// Gets the current [User] from Firebase Authentication.
  User? get user {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      log("Error getting current user: $e");
      return null;
    }
  }

  /// Indicates whether a user is currently logged in.
  bool get isLoggedIn => user != null;

  /// Properly cancels the Firebase auth subscription to prevent memory leaks.
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

}
