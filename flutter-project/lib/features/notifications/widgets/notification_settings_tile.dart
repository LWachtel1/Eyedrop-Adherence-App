import 'package:eyedrop/features/notifications/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:sizer/sizer.dart';

/// A UI card widget for managing notification preferences.
/// 
/// It uses `NotificationController` to store and manage the current notification settings, 
/// and to reactively update the UI when those settings change.
/// 
/// `NotificationService` handles actual notification logic
/// i.e., scheduling, showing, vibrating, building notification details, and saving user preferences.
/// 
/// The UI card widget manages:
/// - enabling/disabling notifications.
/// - toggling sound and vibration.
/// - sending a test notifications.
/// - rescheduling all reminders.

class NotificationSettingsTile extends StatelessWidget {
  const NotificationSettingsTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NotificationController>(context);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [

            // Toggle switch for enabling/disbaling notifications globally.
            ListTile(
              title: Text(
                "Notifications",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              subtitle: Text(
                "Receive reminders for your medications",
                style: TextStyle(fontSize: 12.sp),
              ),

              trailing: Switch(
                value: controller.notificationsEnabled, // Current value from controller.
                onChanged: controller.toggleNotifications, // Toggle logic.
              ),
            ),
            // If notifications are enabled, show additional settings.
            if (controller.notificationsEnabled) ...[
              Divider(),
              
              // Toggle for notification sound.
              ListTile(
                leading: Icon(Icons.volume_up),
                title: Text("Sound", style: TextStyle(fontSize: 14.sp)),
                trailing: Switch(
                  value: controller.soundEnabled,
                  onChanged: controller.toggleSound,
                ),
              ),

              // Toggle for notification vibration.
              ListTile(
                leading: Icon(Icons.vibration),
                title: Text("Vibration", style: TextStyle(fontSize: 14.sp)),
                trailing: Switch(
                  value: controller.vibrationEnabled,
                  onChanged: controller.toggleVibration,
                ),
              ),
              Divider(),

              // Button to trigger a test notification.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.notifications_active),
                  label: Text("Test Notification"),
                  onPressed: () {
                    // Calls showTestNotification from the NotificationService.
                    final service = Provider.of<NotificationService>(context, listen: false);
                    service.showTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Test notification sent. Check your device's notifications."))
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                ),
              ),

              // Button to reschedule all active reminders.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                child: TextButton.icon(
                  icon: Icon(Icons.restart_alt),
                  label: Text("Reschedule All Reminders"),
                  onPressed: () {
                    controller.rescheduleAllReminders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("All reminders rescheduled"))
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}