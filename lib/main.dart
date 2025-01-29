import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:eyedrop/Pages/onetime_intro.dart';
import 'package:eyedrop/Pages/auth_gate.dart';

import 'package:provider/provider.dart';
import 'package:eyedrop/Functional/auth_checker.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ChangeNotifierProvider(
      create: (context) => AuthChecker(),
      child: MyApp(),
    ),);
}

//https://stackoverflow.com/questions/70486658/no-firebase-app-has-been-created-call-firebase-initializeapp 
//https://dart.dev/libraries/async/async-await

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute:  IntroScreen.id,
      routes: <String, WidgetBuilder>{
      IntroScreen.id: (BuildContext context) => IntroScreen(),
      '/home': (BuildContext context) => AuthGate(),
    },
    );
  }
}

