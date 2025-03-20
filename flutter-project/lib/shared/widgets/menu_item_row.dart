import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eyedrop/core/navigation/navigation_utils.dart';
import 'package:sizer/sizer.dart';

/// Dropdown menu item

class MenuItemRow extends StatelessWidget {
  final String label;
  final String iconPath;
  final Widget destinationScreen;

  const MenuItemRow({required this.label, required this.iconPath, 
  required this.destinationScreen, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(       
    onTap: () => safeNavigate(context, destinationScreen), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures equal spacing.
      crossAxisAlignment: CrossAxisAlignment.center, // Aligns vertically.      
      children: [
        Text(label, style:  TextStyle(fontSize:20.sp)),
        SizedBox(width: 15.w),
        SvgPicture.asset(iconPath, height: 3.h, width: 3.w, ),
      ],
    ));
  }

  
}