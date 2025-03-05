/* 
    TO DO:
    - handle potential unknown route error
*/

import 'dart:developer';

import 'package:eyedrop/logic/auth_logic/auth_checker.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:eyedrop/logic/auth_logic/auth_gate.dart';
import 'package:eyedrop/screens/onetime_intro_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

///Provides the entry point for the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialises Firebase before running app to ensure its services are available.
    // Uses Firebase config settings for app's specific platform as defined in firebase_options.dart.    
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, stackTrace) {
    log("Firebase failed to initialize: $e", stackTrace: stackTrace);
    return; // Prevents app from running if Firebase fails.
  }

  //Registers AuthChecker & FirestoreService globally, so all widgets can check auth state and run CRUD operations with Cloud FireStore.
  runApp(ChangeNotifierProvider(
    create: (context) => AuthChecker(),
    child: MultiProvider(
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MyApp(),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Builds root widget of entire application.
  ///
  /// It provides routes which allows display of the screens defined by route-associated widgets.
  ///
  /// Parameters:
  /// `context`: A reference to the widget's location in the widget tree.
  ///
  /// Returns:
  /// The route-associated widget.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      //The initial route is the first-time user welcome screen.
      initialRoute: IntroScreen.id,

      routes: <String, WidgetBuilder>{
        IntroScreen.id: (BuildContext context) => IntroScreen(),

        //The home route, which triggers authentication via AuthGate widget.
        //If the user is signed in, the base layout is displayed, otherwise a sign-in/registration screen is shown.
        '/home': (BuildContext context) => AuthGate(),
        
      },
      builder: (context, child) {
        return Stack(
          children: [
            // The app's actual content.
            child ?? const Center(child: Text("Something went wrong!")),
          ],
        );
      },
    );
  }
}
