// Import the background widget that creates the offstage webview.
import 'package:eyedrop/logic/database/pouchdb_background.dart';

import 'package:eyedrop/logic/auth_logic/auth_checker.dart';
import 'package:eyedrop/screens/onetime_intro.dart';
import 'package:eyedrop/logic/auth_logic/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:eyedrop/logic/database/pouchdb_service.dart'; // Import your PouchDB service

import 'package:provider/provider.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //initiliases Firebase before running app to ensure its services are avialable
  //uses Firebae config settings for app platform (as defined in firebase_options.dart)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Registers AuthChecker globally so all widgets in app can check auth state using it
  runApp(ChangeNotifierProvider(
    create: (context) => AuthChecker(),
    child: MultiProvider(
      providers: [
        //Register PouchDBService globally
        Provider<PouchDBService>(create: (_) => PouchDBService()),
      ],
      child: MyApp(),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Builds widget that is root for application 
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      //first route to show, which is the first-time user welcome screen 
      initialRoute:  IntroScreen.id, 
      routes: <String, WidgetBuilder>{
      IntroScreen.id: (BuildContext context) => IntroScreen(),
      //home route triggers authentication via AuthGate widget which returns either 
      //sign in screen or base layout (logged in vs logged out)
      '/home': (BuildContext context) => AuthGate(),
    }, builder: (context, child) {
        return Stack(
          children: [
            // The actual app's content.
            child!,
            // The hidden PouchDB background webview is included globally.
            PouchDBBackground(),
          ],
        );
      },
    );
  }
}

