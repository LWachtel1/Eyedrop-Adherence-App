import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The authentication state checker.
///
/// This class notifies any listeners of changes in authentication state.
class AuthChecker extends ChangeNotifier {
  String? uid;

  AuthChecker() {
    //Listens to stream returned by authStateChanges and returns StreamSubscription object.
    //StreamSubscription object provides a callback function whenever value changes.
    FirebaseAuth.instance.authStateChanges().listen((User? user) {

      //Updates app's stored user id given that a change in authentication state has occurred.
      //If a user is logged in, it assigns their Firebase uid.
      //If no user is logged in (user == null), uid is set to null.
      uid = user?.uid;

      //Tells all listening widgets to rebuild to reflect the changed authentication state.
      notifyListeners(); 
    });
  }

  User? get user => FirebaseAuth.instance.currentUser;
  bool get isLoggedIn => user != null;


}