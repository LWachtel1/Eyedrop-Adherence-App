import 'package:eyedrop/core/navigation/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';

/// Reusable Drawer Item for slide-out menus
class DrawerItem extends StatelessWidget {
  final String label;
  final String iconPath;
  final Widget destinationScreen;


  const DrawerItem({required this.label, required this.iconPath,  required this.destinationScreen, 
  super.key});


  /// Builds slide-out menu drawer item with dynamically adapting icon and text sizing.
  /// 
  ///  The sizing is calculated as a percentage of screen widht or screen height.
  @override
  Widget build(BuildContext context) {
        return ListTile(
          dense: true,
          leading: SvgPicture.asset(
            iconPath,
            height: 8.h, 
            width: 8.w,  
          ),
          title: Text(
            label,
            style: TextStyle(fontSize: 20.sp), 
          ),
        onTap: () => safeNavigate(context, destinationScreen), 
        );
      
  }

  /*
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: SvgPicture.asset(iconPath, height: 50, width: 50),
      title: Text(label, style: const TextStyle(fontSize: 24)),
      onTap: () {},
    );
  }
  */

}