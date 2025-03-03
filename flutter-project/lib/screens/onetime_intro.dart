/* 
    TO DO:
    - add content to IntroScreen widget (add to build method)
*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A page that introduces a first-time user to the application.
///
/// This widget uses SharedPreferences to track whether the user has previously opened the app.
/// If it is the user's first time, the welcome screen is displayed.
/// If the user has opened the app before, they are redirected to the home screen.
class IntroScreen extends StatefulWidget {
  static const String id = "/intro";
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  /// Checks if this is the first time user has opened the app or whether they have opened it previously.
  ///
  ///
  Future<void> checkFirstTime() async {
    // SharedPreferences instance is used to store persistent data.
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //Uncommenting the line below simulates a first time user.
    //await prefs.clear();

    // Whether or not the user has opened the app before i.e., whether they are a first-time user.
    bool isNotFirst = (prefs.getBool('isNotFirst') ?? false);
    // on first launch, 'isNotFirst' key stored with SharedPreferences will be missing, so the bool will default to false.

    //if this is NOT first-time launch, 'isNotFirst' key will have been created and been set to true
    //so user is direct to home route via method call

    if (isNotFirst) {
      //Established users are directed to the home screen instead of being shown the introductory screen.

      // Checks if the widget is still attached to the widget tree; needed because of earlier await call.
      if (context.mounted) {
        _handleStartScreen();
      }
    } else {
      await prefs.setBool('isNotFirst', true);
    }
  }

  @override

  /// Performs initialisation checks before the IntroScreen widget is built.
  ///
  /// It initiates the check to determine whether the user is a first-time user.
  void initState() {
    super.initState();
    checkFirstTime();
  }

  @override

  /// Displays the introductory onboarding screen for a first-time user.
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Welcome to the App!")),
    );
  }

  /// Directs user to route for the home screen.
  void _handleStartScreen() {
    Navigator.popAndPushNamed(context, '/home');
  }
}
