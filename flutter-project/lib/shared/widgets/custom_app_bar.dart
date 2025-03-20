import 'package:eyedrop/shared/widgets/add_form_menu.dart';
import 'package:eyedrop/shared/widgets/link_external_menu.dart';
import 'package:flutter/material.dart';

/// App bar implementation customised to provide top navigation bar for application.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
    const CustomAppBar({super.key});

    /// Tells Flutter the height of the CustomAppBar.
    /// 
    /// The height is the standard height for an AppBar as defined by the kToolbarHeight constant
    @override
    Size get preferredSize => const Size.fromHeight(kToolbarHeight);

    @override
    Widget build(BuildContext context) {
      return AppBar(automaticallyImplyLeading: false, actions: [
    Expanded(
        child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            textDirection: TextDirection.rtl,
            children: const [AddFormMenu(), LinkExternalMenu()]))
  ]);
    }

}