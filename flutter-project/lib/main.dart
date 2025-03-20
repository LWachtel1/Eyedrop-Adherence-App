/* 
    TO DO:
    - handle potential unknown route error
*/

import 'dart:developer';

import 'package:eyedrop/features/auth/controllers/auth_checker.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/features/auth/screens/auth_gate.dart';
import 'package:eyedrop/features/medications/controllers/medication_form_controller.dart';
import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/features/onboarding/screens/onetime_intro_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'core/firebase_options.dart';

/// Application Entry Point.
/// 
/// This function initializes Firebase and runs the application.
/// 
/// - Ensures Firebase services are available before launching the app.
/// - Uses `Provider` for dependency injection.
/// - Sets up authentication state management.
/// - Handles database services using Firestore.
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

  //Registers providers globally, so all widgets can check use their functionalities.
  runApp(ChangeNotifierProvider(
    create: (context) => AuthChecker(),
    child: MultiProvider( // Groups Providers together to be used by the app.
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ProxyProvider<FirestoreService, MedicationService>(
              update: (_, firestoreService, __) => MedicationService(firestoreService),
            ),    
            // ProxyProvider is a provider that builds a value based on other providers.    
        ChangeNotifierProvider(create: (context) => MedicationFormController(medicationService: context.read<MedicationService>())),
      ],
      child: Sizer( // Wraps the app in Sizer.
          builder: (context, orientation, deviceType) {
            return const MyApp();
          }),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  /// Builds Root Application Widget.
  /// 
  /// This widget is responsible for:
  /// - Navigation routes to different screens.
  /// - UI setup.
  /// - Authentication handling.
  /// 
  /// Parameters:
  /// - `context`: A reference to the widget's location in the widget tree.
  ///
  /// Returns:
  /// - The route-associated widget.
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
