import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/notifications/widgets/notification_settings_tile.dart';
import 'package:eyedrop/shared/widgets/custom_app_bar.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:sizer/sizer.dart';

/// Screen for managing application settings
class SettingsScreen extends StatelessWidget {
  static const String id = 'settings_screen';

  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                const NotificationSettingsTile(),
                
                SizedBox(height: 3.h),
                
                // Add more settings sections as needed
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Text(
                    "About",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: ListTile(
                      title: Text(
                        "App Version",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      subtitle: Text(
                        "1.0.0",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}