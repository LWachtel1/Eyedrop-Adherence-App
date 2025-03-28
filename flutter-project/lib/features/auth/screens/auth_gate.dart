import 'dart:developer';
import 'package:eyedrop/features/schedule/screens/schedule_screen.dart';
import 'package:eyedrop/shared/models/doc_templates.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
// Does not import EmailAuthProvider from firebase_auth to prevent conflict with firebase_ui_auth's EmailAuthProvider already in use
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The manager for user authentication state.
///
/// This widget listens for authentication changes using a StreamBuilder
/// and determines whether to display the sign-in screen (`SignInScreen`) or main app layout (`BaseLayout`).
///
/// It also ensures that an authenticated user's Firestore document is created before
/// proceeding to the main app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Ensures a user document exists for an authenticated user.
  Future<void> _checkAndCreateUserDoc(BuildContext context) async {
    
    try{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log("No authenticated user found. Skipping Firestore setup.");
      return; // Safeguard: if no user, do nothing.
    } 

    // Gets the FirestoreService from Provider to allow CRUD operations within class.
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    /*
  if(!(await firestoreService.checkDocExists(collectionPath: "users", docId: user.uid)) ) {
    await firestoreService.addDoc(collectionPath: "users", prefix: " ", data: {});
  }
  */

    //Uses merge: true so that if user document already exists, it is updated instead of being overwritten.
    Map<String, dynamic> userData = createUserDocTemplate();
    await firestoreService.addDoc(
        path: "users", data: userData, merge: true, useAuthUid: true);
    
    log("Firestore user document exists for ${user.uid}");

    } catch (e) {
      log("Error ensuring Firestore user document exists: $e");
    }

  }

  /// Builds the UI for the 'home' route based on the user's authentication state.
  ///
  /// This function uses a `StreamBuilder<User?>` to listen for authentication changes
  /// from `FirebaseAuth.instance.authStateChanges()`.
  ///
  /// Depending on the authentication state:
  ///
  /// If **no user is logged in** (`snapshot.hasData == false`), it displays a `SignInScreen`
  /// from `firebase_ui_auth`, allowing the user to sign in or register.
  ///
  /// If a **user is logged in**, a `FutureBuilder<void>` ensures their Firestore document
  /// exists before proceeding to `BaseLayout`.
  /// - A **loading spinner (`CircularProgressIndicator`)** is shown while the Firestore document is being checked.
  ///
  /// This function ensures that the UI dynamically updates whenever authentication changes.
  ///
  /// Returns:
  /// - `SignInScreen` if no user is logged in.
  /// - `BaseLayout` if the user is logged in and Firestore setup is complete.
  /// - A loading indicator if Firestore document creation is still in progress.
  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to stream and (re)builds the UI based on latest snapshot of stream
    // "User?" means stream will return User object if logged in and null if logged out
    return StreamBuilder<User?>(
      // Singleton FirebaseAuth instance's method call returns stream detailing auth state changes.
      stream: FirebaseAuth.instance.authStateChanges().handleError((error) {
        log("Firebase Auth Stream Error: $error");
      }),
      builder: (context, snapshot) {
        // Checks if snapshot of stream contains a User object.
        if (!snapshot.hasData) {
          // No User object causes SignInScreen widget to be returned.
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

        // Existing User object triggers ensuring user document exists then return of main application UI
        return FutureBuilder<void>(
          future: _checkAndCreateUserDoc(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              log("Error in FutureBuilder: ${snapshot.error}");
              return const Scaffold(
                body: Center(child: Text("Error loading data. Please try again.")),
              );
            }

            return ScheduleScreen();
            
          },
        );
      },
    );
  }
}
