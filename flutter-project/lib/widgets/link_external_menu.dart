import 'package:flutter/material.dart';
import 'custom_popup_menu.dart';
import 'common/menu_item_row.dart';

/// Dropdown Menu for linking app to wearables, user's calendar or device location.
/// 
/// Displayed as child widget within top navigation bar.
class LinkExternalMenu extends StatelessWidget {
  const LinkExternalMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      iconPath: 'assets/icons/linkExternalMenu_icon.svg',
      iconSize: 50,
      items: [
        PopupMenuItem(
          value: '/wearable_link',
          child: MenuItemRow(
            label: 'Link wearable',
            iconPath: 'assets/icons/linkWearable_icon.svg',
          ),
        ),
        PopupMenuItem(
          value: '/calendar_link',
          child: MenuItemRow(
            label: 'Link calendar',
            iconPath: 'assets/icons/linkCalendar_icon.svg',
          ),
        ),
        PopupMenuItem(
          value: '/location_link',
          child: MenuItemRow(
            label: 'Link location',
            iconPath: 'assets/icons/linkLocation_icon.svg',
          ),
        ),
      ],
    );
  }
}
