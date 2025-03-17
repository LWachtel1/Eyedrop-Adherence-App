import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'custom_popup_menu.dart';
import 'menu_item_row.dart';


/// Dropdown Menu for linking app to wearables, user's calendar or device location.
/// 
/// Displayed as child widget within top navigation bar.
class LinkExternalMenu extends StatelessWidget {
  const LinkExternalMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      iconPath: 'assets/icons/linkExternalMenu_icon.svg',
      iconSize: 12.w,
      items: [
        PopupMenuItem(
          value: '/wearable_link',
          child: Center( // Ensures menu items are centered.
            child: MenuItemRow(
              label: 'Link wearable',
              iconPath: 'assets/icons/linkWearable_icon.svg',
              destinationScreen: BaseLayoutScreen(child: null)

            )),
        ),
        PopupMenuItem(
          value: '/calendar_link',
          child: Center( 
              child: MenuItemRow(
            label: 'Link calendar',
            iconPath: 'assets/icons/linkCalendar_icon.svg',
            destinationScreen: BaseLayoutScreen(child: null)
            )),
        ),
        PopupMenuItem(
          value: '/location_link',
          child: Center (child: MenuItemRow(
            label: 'Link location',
            iconPath: 'assets/icons/linkLocation_icon.svg',
            destinationScreen: BaseLayoutScreen(child: null)
          )),
        ),
      ],
    );
  }
}
