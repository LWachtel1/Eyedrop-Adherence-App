import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

///Checker of auth state
///
///Extends from ChangeNotifier class which notifies any listeners of changes
class AuthChecker extends ChangeNotifier {
  String? uid;

  AuthChecker() {
    // Listens to stream returned by authStateChanges and returns StreamSubscription object, which
    //provides a callback function whenever value changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      //firebase_auth user object's unique id 
      uid = user?.uid;
      //This calls tells listeners about change
      notifyListeners(); 
    });
  }

  User? get user => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => user != null;


}