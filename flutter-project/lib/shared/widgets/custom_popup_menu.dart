import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';



/// Reusable Popup Menu
class CustomPopupMenu extends StatelessWidget {
  final String iconPath;
  final List<PopupMenuEntry> items;
  final double iconSize;

  const CustomPopupMenu({
    required this.iconPath,
    required this.items,
    required this.iconSize,
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: Offset(0, iconSize + 2.h), //Offsets dropdown downwards so it doesn’t overlap the button.
      constraints: BoxConstraints(minWidth: 50.w), // Ensures dropdown width is min 50% of screen width.
      child: Padding(
        padding: EdgeInsets.only(right: 5.w),
        child: Center( // Ensures  dropdown icon is centered within the button.
          child: SvgPicture.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
          ),
        ),
      ),
      itemBuilder: (BuildContext context) => items,
    );
  }
}
