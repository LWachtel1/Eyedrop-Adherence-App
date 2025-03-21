import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/features/medications/screens/medications_screen.dart';
import 'package:eyedrop/features/reminders/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'drawer_item.dart';

/// Slide-out drawer implementation customised to act as slide-out navigation menu for app.
class CustomSlideOutMenu extends StatelessWidget {
  const CustomSlideOutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea( // Prevents overlap with status bar.
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(child: DrawerItem(label: 'Schedule', iconPath: 'assets/icons/schedule_icon.svg', destinationScreen: BaseLayoutScreen(child: null))),
                  Expanded(child: DrawerItem(label: 'Medications', iconPath: 'assets/icons/medications_icon.svg', destinationScreen: MedicationsScreen())),
                  Expanded(child: DrawerItem(label: 'Reminders', iconPath: 'assets/icons/reminders_icon.svg', destinationScreen: RemindersScreen())),
                  Expanded(child: DrawerItem(label: 'Education', iconPath: 'assets/icons/education_icon.svg', destinationScreen: BaseLayoutScreen(child: null))),
                  Expanded(child: DrawerItem(label: 'Aim', iconPath: 'assets/icons/aim_icon.svg', destinationScreen: BaseLayoutScreen(child: null))),
                  Expanded(child: DrawerItem(label: 'Progress & Tracking', iconPath: 'assets/icons/progress+tracking_icon.svg', destinationScreen: BaseLayoutScreen(child: null))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
