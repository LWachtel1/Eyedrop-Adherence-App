import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

///The implementation that checks whether to show user introduction to app or direct them to home route
///
///The introduction to app is only ever shown to users the very first time they open the app after download
class IntroScreen extends StatefulWidget {
  static const String id = "/intro";
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {

  ///Checks if this is the very first time user has opened app
  Future checkFirstTime() async {

    //SharedPreferences instance stores persistent data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //await prefs.clear(); - uncomment this line to simulate first time welcome screen

    //'isNotFirst' key will be missing on first-time launch so this bool will be false
    bool isNotFirst = (prefs.getBool('isNotFirst') ?? false);


    //if this is NOT first-time launch, 'isNotFirst' key will have been created and been set to true
    //so user is direct to home route via method call

    if (isNotFirst) {
      _handleStartScreen();
    } 
    //erroneous code as this redirects user back to intro screen -> should just stay on this page 
    //instead of redirecting back to it - see fixed version below
    else { 
     
        await prefs.setBool('isNotFirst', true);
        if (context.mounted) Navigator.popAndPushNamed(context, IntroScreen.id); 
    }
  }

  //allows 
  @override
  void initState() {
    super.initState();
    checkFirstTime();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  //Directs user to home route
  void _handleStartScreen() {
    Navigator.popAndPushNamed(context, '/home');

  }

}

//Stateless widget version without else statement problem
/**import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatelessWidget {
  static const String id = "/intro";

  const IntroScreen({super.key});

  Future<bool> checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isNotFirst = prefs.getBool('isNotFirst') ?? false;

    if (!isNotFirst) {
      await prefs.setBool('isNotFirst', true);
    }

    return isNotFirst;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkFirstTime(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/home'));
          return const SizedBox.shrink();
        }

        return const Scaffold(
          body: Center(child: Text("Welcome to the App!")),
        );
      },
    );
  }
} */