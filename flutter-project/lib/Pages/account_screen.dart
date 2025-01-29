import 'package:eyedrop/Pages/auth_gate.dart';
import 'package:eyedrop/Pages/base_layout.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(child:  ProfileScreen(
      actions: [SignedOutAction((context) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthGate())); 
      })
      ]));
    
    
  }
}

