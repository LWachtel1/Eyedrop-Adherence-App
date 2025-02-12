import 'package:eyedrop/logic/auth_logic/auth_gate.dart';
import 'package:eyedrop/screens/base_layout.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

///The user's in-app account page 
///
///Allows user to sign out of or delete account
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  /// Builds the UI following user clicking account icon on bottom navigation bar
  /// 
  /// Returns ProfileScreen wrapped inside BaseLayout
  /// Upon sign-out, user is directed to user auth flow, ultimately returning them to login screen
  @override
  Widget build(BuildContext context) {
    return BaseLayout(child:  ProfileScreen(
      actions: [SignedOutAction((context) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthGate())); 
      })
      ]));
    
    
  }
}

