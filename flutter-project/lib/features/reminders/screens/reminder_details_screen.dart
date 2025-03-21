import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Screen for viewing reminder details
class ReminderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reminder;

  const ReminderDetailScreen({
    required this.reminder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reminderService = Provider.of<ReminderService>(context, listen: false);

    return BaseLayoutScreen(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                "Reminder Details",
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // Main content in a scrollable area.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication section
                    _buildDetailSection(
                      title: "Medication",
                      children: [
                        _buildDetailRow("Name", reminder["medicationName"] ?? "N/A"),
                        _buildDetailRow("Type", reminder["medicationType"] ?? "N/A"),
                      ],
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Timing section
                    _buildDetailSection(
                      title: "Schedule",
                      children: [
                        _buildDetailRow(
                          "Start Date", 
                          _formatDate(reminder["startDate"]),
                        ),
                        _buildDetailRow(
                          "Duration",
                          _formatDuration(
                            reminder["isIndefinite"], 
                            reminder["durationLength"], 
                            reminder["durationUnits"],
                          ),
                        ),
                        _buildDetailRow(
                          "Smart Scheduling",
                          reminder["smartScheduling"] == true ? "Enabled" : "Disabled",
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Timings section (if not using smart scheduling).
                    if (reminder["smartScheduling"] != true && 
                        reminder["timings"] != null) ...[
                      _buildDetailSection(
                        title: "Reminder Times",
                        children: [
                          ..._buildTimingsList(reminder["timings"]),
                        ],
                      ),
                      
                      SizedBox(height: 2.h),
                    ],
                    
                    // Created date
                    if (reminder["createdAt"] != null)
                      _buildDetailRow(
                        "Created On", 
                        _formatDate(reminder["createdAt"]),
                      ),
                  ],
                ),
              ),
            ),
            
            // Back and delete buttons.
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    label: Text("Back"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context, reminderService),
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section with a title and multiple detail rows.
  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Divider(thickness: 1.5),
        ...children,
      ],
    );
  }

  /// Builds a simple label-value row.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15.sp),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list of timing widgets.
  List<Widget> _buildTimingsList(List<dynamic>? timings) {
    if (timings == null || timings.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Text(
            "No specific times set",
            style: TextStyle(fontSize: 15.sp, fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    return timings.asMap().entries.map((entry) {
      final index = entry.key;
      final timing = entry.value;
      
      if (timing is Map<String, dynamic> && 
          timing.containsKey('hour') && 
          timing.containsKey('minute')) {
        final timeStr = _formatTimeFromHourMinute(
          timing['hour'], 
          timing['minute'],
        );
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.5.h),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 15.sp, color: Colors.grey[600]),
              SizedBox(width: 2.w),
              Text(
                "Time ${index + 1}: $timeStr",
                style: TextStyle(fontSize: 15.sp),
              ),
            ],
          ),
        );
      }
      
      return SizedBox.shrink();
    }).toList();
  }

  /// Formats a FireStore timestamp or DateTime to a readable date string.
  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return "Invalid date";
    }
    
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Formats duration information into a readable string.
  String _formatDuration(bool? isIndefinite, dynamic length, dynamic units) {
    if (isIndefinite == true) return "Indefinite";
    
    if (length == null || units == null || 
        length.toString().isEmpty || units.toString().isEmpty) {
      return "N/A";
    }
    
    return "$length ${units.toString()}";
  }

  /// Formats hour and minute into a readable time string.
  String _formatTimeFromHourMinute(int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    
    // Use 12-hour format with AM/PM
    final hourValue = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteValue = time.minute.toString().padLeft(2, '0');
    
    return "$hourValue:$minuteValue $period";
  }

  /// Shows a confirmation dialog before deleting the reminder.
  Future<void> _confirmDelete(BuildContext context, ReminderService reminderService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Reminder?"),
        content: Text(
          "Are you sure you want to delete the reminder for ${reminder["medicationName"]}? This action cannot be undone."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await reminderService.deleteReminder(reminder);
        
        if (context.mounted) {
          Navigator.pop(context); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Reminder deleted successfully")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete reminder: $e")),
          );
        }
      }
    }
  }
}