import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/notifications/widgets/notification_settings_tile.dart';
import 'package:eyedrop/features/progress/services/progress_service.dart';
import 'package:eyedrop/shared/widgets/custom_app_bar.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                
                SizedBox(height: 3.h),
                
                // Add Progress Simulator section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Text(
                    "Development Tools",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                _buildProgressSimulator(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds the progress simulator widget for testing and demonstration
  Widget _buildProgressSimulator(BuildContext context) {
    final TextEditingController jsonController = TextEditingController();
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Progress Entry Simulator",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              "Paste JSON-formatted progress entry data to simulate progress tracking",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: jsonController,
              maxLines: 8,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON progress entry here...',
                contentPadding: EdgeInsets.all(2.w),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    jsonController.clear();
                  },
                  child: Text("Clear"),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () => _uploadProgressEntry(context, jsonController.text),
                  child: Text("Upload"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Uploads a progress entry from JSON text
  void _uploadProgressEntry(BuildContext context, String jsonText) async {
    final progressService = ProgressService();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      _showSnackBar(context, "You must be logged in to upload progress entries", isError: true);
      return;
    }
    
    try {
      // Parse the JSON text
      final jsonData = json.decode(jsonText);
      
      // Validate essential fields
      if (!_validateProgressEntry(jsonData)) {
        _showSnackBar(context, "Invalid progress entry format - missing required fields", isError: true);
        return;
      }
      
      // Convert timestamps to DateTime objects if they are strings
      final scheduledAt = _parseDateTime(jsonData['scheduledAt']);
      final respondedAt = jsonData['respondedAt'] != null ? _parseDateTime(jsonData['respondedAt']) : null;
      
      // Call the appropriate method based on whether the medication was taken
      if (jsonData['taken'] == true && respondedAt != null) {
        await progressService.recordMedicationTaken(
          userId: user.uid,
          reminderId: jsonData['reminderId'],
          medicationId: jsonData['medicationId'],
          scheduledAt: scheduledAt,
          respondedAt: respondedAt,
          scheduleType: jsonData['scheduleType'] ?? 'daily',
        );
      } else {
        await progressService.recordMedicationMissed(
          userId: user.uid,
          reminderId: jsonData['reminderId'],
          medicationId: jsonData['medicationId'],
          scheduledAt: scheduledAt,
          scheduleType: jsonData['scheduleType'] ?? 'daily',
        );
      }
      
      _showSnackBar(context, "Progress entry uploaded successfully");
    } catch (e) {
      _showSnackBar(context, "Error uploading progress entry: ${e.toString()}", isError: true);
    }
  }
  
  /// Validates that a progress entry has all required fields
  bool _validateProgressEntry(Map<String, dynamic> entry) {
    return entry.containsKey('reminderId') && 
           entry.containsKey('medicationId') && 
           entry.containsKey('scheduledAt') &&
           entry.containsKey('taken');
  }
  
  /// Parses a datetime string or timestamp into a DateTime object
  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else if (dateValue is Map && dateValue.containsKey('_seconds')) {
      // Handle Firestore timestamp format
      return DateTime.fromMillisecondsSinceEpoch(
        (dateValue['_seconds'] * 1000 + (dateValue['_nanoseconds'] ?? 0) / 1000000).round()
      );
    } else {
      throw FormatException("Invalid date format");
    }
  }
  
  /// Shows a snackbar message
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}