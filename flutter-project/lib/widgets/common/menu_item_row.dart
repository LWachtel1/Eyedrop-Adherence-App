import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class MenuItemRow extends StatelessWidget {
  final String label;
  final String iconPath;

  const MenuItemRow({required this.label, required this.iconPath, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        SvgPicture.asset(iconPath),
      ],
    );
  }
}