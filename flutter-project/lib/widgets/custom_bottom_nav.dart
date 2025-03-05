import 'package:eyedrop/screens/account_screen.dart';
import 'package:flutter/material.dart';


/// Bottom Navigation Bar customised for application.
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              iconSize: 40,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const Spacer(),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.person),
              iconSize: 40,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}