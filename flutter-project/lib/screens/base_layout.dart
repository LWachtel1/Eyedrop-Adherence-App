import 'package:eyedrop/screens/account_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

/// The base layout of application's user interface.
///
/// Provides top and bottom navigation bars surrounding the body of a page.
/// Contains child widget that exists with the body of a page, displaying feature-specific content.
class BaseLayout extends StatelessWidget {
  // A child widget, which may be equal to null if there is no content to display in page body.
  final Widget? child;

  // Constructor.
  const BaseLayout({
    required this.child, // This ensures 'child' must be provided when creating an instance.
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(),
        bottomNavigationBar: bottomAppBar(),
        drawer: slideOutMenu(),
        body: child);
  }
}

/// Provides the top navigation bar.
AppBar appBar() {
  return AppBar(automaticallyImplyLeading: false, actions: [
    Expanded(
        child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            textDirection: TextDirection.rtl,
            children: [addFormMenu(), linkExternalMenu()]))
  ]);
}

/// Provides the dropdown menu for adding reminders and medications.
///
/// Displayed as child widget within top navigation bar.
PopupMenuButton addFormMenu() {
  return PopupMenuButton(
      child: Container(
          padding: EdgeInsets.only(right: 20),
          child: SvgPicture.asset('assets/icons/addFormMenu_icon.svg')),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
              value: '/reminder_form',
              child: Row(
                children: [
                  Text('Add reminder', style: TextStyle(fontSize: 24)),
                  Container(
                      padding: EdgeInsets.only(left: 10),
                      child:
                          SvgPicture.asset('assets/icons/addReminder_icon.svg'))
                ],
              )),
          PopupMenuItem(
              value: '/medication_form',
              child: Row(
                children: [
                  Text('Add medication', style: TextStyle(fontSize: 24)),
                  Container(
                      padding: EdgeInsets.only(left: 10),
                      child: SvgPicture.asset(
                          'assets/icons/addMedication_icon.svg'))
                ],
              )),
        ];
      });
}

/// Provides the dropdown menu for linking app to a wearable device, a user's calendar or device location.
///
/// Displayed as child widget within top navigation bar.
PopupMenuButton linkExternalMenu() {
  return PopupMenuButton(
      child: Container(
          padding: EdgeInsets.only(right: 20),
          child: SvgPicture.asset('assets/icons/linkExternalMenu_icon.svg',
              width: 50, height: 50)),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
              value: '/wearable_link',
              child: Row(
                children: [
                  Text('Link wearable', style: TextStyle(fontSize: 24)),
                  Container(
                      padding: EdgeInsets.only(left: 10),
                      child: SvgPicture.asset(
                          'assets/icons/linkWearable_icon.svg'))
                ],
              )),
          PopupMenuItem(
              value: '/calendar_link',
              child: Row(
                children: [
                  Text('Link calendar', style: TextStyle(fontSize: 24)),
                  Container(
                      padding: EdgeInsets.only(left: 15),
                      child: SvgPicture.asset(
                          'assets/icons/linkCalendar_icon.svg',
                          width: 30,
                          height: 30))
                ],
              )),
          PopupMenuItem(
              value: '/location_link',
              child: Row(
                children: [
                  Text('Link location', style: TextStyle(fontSize: 24)),
                  Container(
                      padding: EdgeInsets.only(left: 23),
                      child: SvgPicture.asset(
                          'assets/icons/linkLocation_icon.svg',
                          height: 30,
                          width: 30))
                ],
              )),
        ];
      });
}

/// Provides the bottom navigation bar.
BottomAppBar bottomAppBar() {
  return BottomAppBar(
      child: Row(children: [
    Builder(builder: (context) {
      return IconButton(
          icon: const Icon(Icons.menu),
          iconSize: 40,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          });
    }),
    Spacer(),
    Builder(builder: (context) {
      return IconButton(
          icon: Icon(Icons.person),
          iconSize: 40,
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AccountScreen()));

            /*
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const 
            AccountScreen()));
            might cause navigating back bugs as it replaces current navigation stack page so 
            popping back will not take me to previous page but instead any pages under that in stack
            */
          });
    }),
  ]));
}

/// Provides the slide-out menu with links to the main feature-providing pages of the app.
Drawer slideOutMenu() {
  return Drawer(
      child: Column(children: [
    Expanded(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      ListTile(
        dense: true,
        leading: SvgPicture.asset('assets/icons/schedule_icon.svg',
            height: 50, width: 50),
        title: Text('Schedule', style: TextStyle(fontSize: 24)),
        onTap: () => {},
      ),
      ListTile(
        dense: true,
        leading: SvgPicture.asset('assets/icons/medications_icon.svg',
            height: 50, width: 50),
        title: Text('Medications', style: TextStyle(fontSize: 24)),
        onTap: () => {},
      ),
      ListTile(
        dense: true,
        leading: SvgPicture.asset('assets/icons/reminders_icon.svg',
            height: 50, width: 50),
        title: Text('Reminders', style: TextStyle(fontSize: 24)),
        onTap: () => {},
      ),
      ListTile(
        dense: true,
        leading: SvgPicture.asset('assets/icons/education_icon.svg',
            height: 50, width: 50),
        title: Text('Education', style: TextStyle(fontSize: 24)),
        onTap: () => {},
      ),
      ListTile(
        dense: true,
        leading: SvgPicture.asset('assets/icons/aim_icon.svg',
            height: 50, width: 50),
        title: Text('Aim', style: TextStyle(fontSize: 24)),
        onTap: () => {},
      ),
      ListTile(
        dense: true,
        leading: SvgPicture.asset('assets/icons/progress+tracking_icon.svg',
            height: 50, width: 50),
        title: Text('Progress & Tracking', style: TextStyle(fontSize: 24)),
        onTap: () => {},
      )
    ]))
  ]));
}
