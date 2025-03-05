import 'package:flutter/material.dart';
import 'common/drawer_item.dart';

/// Slide-out drawer implementation customised to act as slide-out navigation menu for app.
class CustomSlideOutMenu extends StatelessWidget {
  const CustomSlideOutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                DrawerItem(label: 'Schedule', iconPath: 'assets/icons/schedule_icon.svg'),
                DrawerItem(label: 'Medications', iconPath: 'assets/icons/medications_icon.svg'),
                DrawerItem(label: 'Reminders', iconPath: 'assets/icons/reminders_icon.svg'),
                DrawerItem(label: 'Education', iconPath: 'assets/icons/education_icon.svg'),
                DrawerItem(label: 'Aim', iconPath: 'assets/icons/aim_icon.svg'),
                DrawerItem(label: 'Progress & Tracking', iconPath: 'assets/icons/progress+tracking_icon.svg'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}