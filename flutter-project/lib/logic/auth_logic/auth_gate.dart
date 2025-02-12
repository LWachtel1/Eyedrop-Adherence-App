
import 'package:eyedrop/screens/base_layout.dart';
import 'package:eyedrop/logic/database/pouchdb_service.dart';

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


///The implementation of user authentication 
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

Future<void> _checkAndCreateUserDoc(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Safeguard: if no user, do nothing.

  // Get the PouchDBService from Provider.
  final pouchDBService = Provider.of<PouchDBService>(context, listen: false);

  // Call the service method which will send the JS command to check for the document.
  await pouchDBService.checkUserDoc(user.uid);
}

  /// Builds the UI for the home Route depending on user auth state (logged in/logged out)
  /// 
  /// Returns widget that listens for auth state changes and returns screen based on these changes  
  @override
  Widget build(BuildContext context) {

    //StreamBuilder listens to stream and (re)builds the UI based on latest snapshot of stream 
    // "User?" means stream will return User object if logged in and null if logged out
    return StreamBuilder<User?>(

      //singleton FirebaseAuth instance's method call returns stream detailing auth state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        //checks if snapshot of stream contains a User object
        if (!snapshot.hasData) {
          //no User object i.e., null results in SignInScreen widget being returned
          return SignInScreen(
            providers: [EmailAuthProvider()], 
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to [AppName], please sign in!')
                    : const Text('Welcome to [AppName], please sign up!'),
              );
              },
              footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        }

        // User is logged in: Check user document and load app
        return FutureBuilder<void>(
          future: _checkAndCreateUserDoc(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            //User object i.e., user is logged in results in base layout of app being returned
            return BaseLayout(child: null);
          },
        );

     
      },
    );
  }
}