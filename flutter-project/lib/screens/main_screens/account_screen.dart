/*
  TO DO:
  - add FireStore user data deletion to AccountDeletedAction
*/

import 'package:eyedrop/logic/auth_logic/auth_gate.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

/// The user's account page
///
/// It is accessed by clicking the account icon in the right corner of the bottom navigation bar.
/// This page allows user to sign out  or to delete their account.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override

  /// Builds the account screen with a user profile interface and account management actions.
  ///
  /// The screen includes:
  /// * A sign-out action that returns the user to [AuthGate], which displays the login screen.
  /// * An account deletion action
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
        child: ProfileScreen(actions: [
      SignedOutAction((context) {

        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthGate()));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
        );
        }

      }),
      AccountDeletedAction((context, user) {})
    ]));
  }
}
