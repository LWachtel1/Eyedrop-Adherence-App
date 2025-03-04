import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


/// Reusable Popup Menu
class CustomPopupMenu extends StatelessWidget {
  final String iconPath;
  final List<PopupMenuEntry> items;
  final double iconSize;

  const CustomPopupMenu({
    required this.iconPath,
    required this.items,
    this.iconSize = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: SvgPicture.asset(iconPath, width: iconSize, height: iconSize),
      ),
      itemBuilder: (BuildContext context) => items,
    );
  }
}
