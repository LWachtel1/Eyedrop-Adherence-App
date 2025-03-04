import 'package:flutter/material.dart';
import 'custom_popup_menu.dart';
import 'common/menu_item_row.dart';

/// Dropdown Menu for Adding Reminders and Medications
/// 
/// Displayed as child widget within top navigation bar.
class AddFormMenu extends StatelessWidget {
  const AddFormMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      iconPath: 'assets/icons/addFormMenu_icon.svg',
      items: [
        PopupMenuItem(
          value: '/reminder_form',
          child: MenuItemRow(
            label: 'Add reminder',
            iconPath: 'assets/icons/addReminder_icon.svg',
          ),
        ),
        PopupMenuItem(
          value: '/medication_form',
          child: MenuItemRow(
            label: 'Add medication',
            iconPath: 'assets/icons/addMedication_icon.svg',
          ),
        ),
      ],
    );
  }
}