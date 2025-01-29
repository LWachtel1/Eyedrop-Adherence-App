import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class IntroScreen extends StatefulWidget {
  static const String id = "/intro";
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {

  Future checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //await prefs.clear(); - uncomment this line to simulate first time welcome screen
    bool isNotFirst = (prefs.getBool('isNotFirst') ?? false);

    if (isNotFirst) {
      _handleStartScreen();
    } else {
        await prefs.setBool('isNotFirst', true);
        if (context.mounted) Navigator.popAndPushNamed(context, IntroScreen.id); //fix this error
    }
  }


  @override
  void initState() {
    super.initState();
    checkFirstTime();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  void _handleStartScreen() {
    Navigator.popAndPushNamed(context, '/home');

  }

}