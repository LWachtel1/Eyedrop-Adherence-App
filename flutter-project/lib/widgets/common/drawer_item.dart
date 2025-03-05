import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable Drawer Item for slide-out menus
class DrawerItem extends StatelessWidget {
  final String label;
  final String iconPath;

  const DrawerItem({required this.label, required this.iconPath, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: SvgPicture.asset(iconPath, height: 50, width: 50),
      title: Text(label, style: const TextStyle(fontSize: 24)),
      onTap: () {},
    );
  }

}