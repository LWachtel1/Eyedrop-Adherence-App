import 'package:flutter/material.dart';
import 'package:eyedrop/Pages/base_layout.dart';
import 'package:eyedrop/Pages/onetime_intro.dart';

void main() {
  runApp(const MyApp());
}

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
      '/home': (BuildContext context) => BaseLayout(),
    },
    );
  }
}

