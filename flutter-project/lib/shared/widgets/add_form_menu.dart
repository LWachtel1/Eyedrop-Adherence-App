import 'package:eyedrop/features/medications/screens/medication_form.dart';
import 'package:eyedrop/features/reminders/screens/reminder_form.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'custom_popup_menu.dart';
import 'menu_item_row.dart';

/// Dropdown Menu for Adding Reminders and Medications
/// 
/// Displayed as child widget within top navigation bar.
class AddFormMenu extends StatelessWidget {
  const AddFormMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      iconPath: 'assets/icons/addFormMenu_icon.svg',
      iconSize: 8.w,
       items: [
        PopupMenuItem(
          value: '/reminder_form',
          child: Center( // Ensures menu items are centered.
            child: MenuItemRow(
              label: 'Add reminder',
              iconPath: 'assets/icons/addReminder_icon.svg',
              destinationScreen: ReminderForm(),
            ),
          ),
        ),
        PopupMenuItem(
          value: '/medication_form',
          child: Center(
            child: MenuItemRow(
              label: 'Add medication',
              iconPath: 'assets/icons/addMedication_icon.svg',
              destinationScreen: MedicationForm(),
            ),
          ),
        ),
      ],
    );
  }
}