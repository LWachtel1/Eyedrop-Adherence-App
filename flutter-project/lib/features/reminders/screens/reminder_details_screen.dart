import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/confirmation_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

/// Screen for viewing reminder details
class ReminderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reminder;

  const ReminderDetailScreen({
    required this.reminder,
    Key? key,
  }) : super(key: key);

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  // Store the reminder data in state so we can update the UI when toggled
  late Map<String, dynamic> _reminder;
  bool _isLoading = false;
  // Stream subscription for real-time updates
  StreamSubscription<Map<String, dynamic>?>? _reminderSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed reminder data
    _reminder = Map.from(widget.reminder);
    
    // Set up real-time updates using a stream
    _setupReminderStream();
  }

  /// Sets up a real-time stream to listen for changes to this reminder
  void _setupReminderStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_reminder.containsKey("id")) return;
    
    final reminderId = _reminder["id"];
    final reminderService = Provider.of<ReminderService>(context, listen: false);
    
    _reminderSubscription = reminderService
        .getReminderDocumentStream(user.uid, reminderId)
        .listen((updatedReminder) {
      if (updatedReminder != null && mounted) {
        setState(() {
          // Merge updated data with existing reminder
          // Keep the ID since it might not be included in the stream
          final id = _reminder["id"];
          _reminder = updatedReminder;
          _reminder["id"] = id;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the stream subscription when the screen is disposed
    _reminderSubscription?.cancel();
    super.dispose();
  }

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
            
            SizedBox(height: 2.h),
            
            // Status toggle with loading indicator
            _buildStatusToggle(reminderService),
            
            SizedBox(height: 2.h),
            
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
                        _buildDetailRow("Name", _reminder["medicationName"] ?? "N/A"),
                        _buildDetailRow("Type", _reminder["medicationType"] ?? "N/A"),
                      ],
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Timing section
                    _buildDetailSection(
                      title: "Schedule",
                      children: [
                        _buildDetailRow(
                          "Start Date", 
                          _formatDate(_reminder["startDate"]),
                        ),
                        _buildDetailRow(
                          "Duration",
                          _formatDuration(
                            _reminder["isIndefinite"], 
                            _reminder["durationLength"], 
                            _reminder["durationUnits"],
                          ),
                        ),
                        _buildDetailRow(
                          "Smart Scheduling",
                          _reminder["smartScheduling"] == true ? "Enabled" : "Disabled",
                        ),
                        // Schedule type and frequency
                        _buildDetailRow(
                          "Schedule Type",
                          _formatScheduleType(_reminder["scheduleType"]),
                        ),
                        _buildDetailRow(
                          "Frequency",
                          _formatFrequency(_reminder["frequency"], _reminder["scheduleType"]),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Dosage section
                    _buildDetailSection(
                      title: "Dosage",
                      children: [
                        _buildDetailRow(
                          "Dose Quantity",
                          _formatDoseQuantity(_reminder["doseQuantity"]),
                        ),
                        _buildDetailRow(
                          "Dose Units",
                          _reminder["doseUnits"] ?? "N/A",
                        ),
                        // Only show application site for eye medications
                        if (_reminder["medicationType"] == "Eye Medication" && 
                            _reminder["applicationSite"] != null)
                          _buildDetailRow(
                            "Application Site",
                            _reminder["applicationSite"] ?? "N/A",
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Timings section (if not using smart scheduling).
                    if (_reminder["smartScheduling"] != true && 
                        _reminder["timings"] != null) ...[
                      _buildDetailSection(
                        title: "Reminder Times",
                        children: [
                          ..._buildTimingsList(_reminder["timings"]),
                        ],
                      ),
                      
                      SizedBox(height: 2.h),
                    ],
                    
                    // Created date
                    if (_reminder["createdAt"] != null)
                      _buildDetailRow(
                        "Created On", 
                        _formatDate(_reminder["createdAt"]),
                      ),
                  ],
                ),
              ),
            ),
            
            // Progress management buttons
            SizedBox(height: 2.h),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red.shade100),
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Progress History",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      "Manage the progress history for this reminder",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _confirmDeleteProgress(context),
                      icon: _isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.delete_forever, color: Colors.red),
                      label: Text(
                        "Delete All Progress History",
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            
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
  
  /// Builds the toggle switch for enabling/disabling the reminder
  Widget _buildStatusToggle(ReminderService reminderService) {
    // Default to true if not present
    bool isEnabled = _reminder["isEnabled"] ?? true;
    bool isExpired = _reminder["isExpired"] == true;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reminder Status",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_isLoading)
                      Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.only(right: 2.w),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    Switch(
                      value: isEnabled,
                      onChanged: isExpired || _isLoading 
                          ? null  // Disable the switch if the reminder is expired
                          : (value) => _toggleReminderState(reminderService, value),
                      activeColor: Colors.blue,
                    ),
                    Text(
                      isExpired 
                          ? "Expired" 
                          : (isEnabled ? "Enabled" : "Disabled"),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isExpired 
                            ? Colors.red 
                            : (isEnabled ? Colors.blue : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Show expiration message if reminder is expired
            if (isExpired)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16.sp),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        "This reminder has expired because it reached the end of its duration.",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Add a renew button if the reminder is expired
            if (isExpired)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Renew Reminder"),
                  onPressed: () => _renewReminder(reminderService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Toggles the reminder's enabled state in Firestore
  Future<void> _toggleReminderState(ReminderService reminderService, bool newValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar("You must be logged in to perform this action");
      return;
    }
    
    if (!_reminder.containsKey("id") || _reminder["id"] == null) {
      _showErrorSnackBar("Cannot update reminder: missing ID");
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await reminderService.toggleReminderState(
        user.uid, 
        _reminder["id"], 
        newValue,
        onToggled: (updatedReminder) {
          // Reschedule notifications when the reminder state changes
          final notificationController = Provider.of<NotificationController>(context, listen: false);
          notificationController.scheduleReminderNotifications(updatedReminder);
        }
      );
      
      // Update local state after successful Firestore update
      setState(() {
        _reminder["isEnabled"] = newValue;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder ${newValue ? 'enabled' : 'disabled'}"),
          backgroundColor: newValue ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Failed to update reminder: $e");
    }
  }
  
  /// Shows an error message to the user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Formats the schedule type into a readable string
  String _formatScheduleType(dynamic scheduleType) {
    if (scheduleType == null) return "N/A";
    
    String type = scheduleType.toString().toLowerCase();
    // Capitalize first letter
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }

  /// Formats the frequency into a readable string based on schedule type
  String _formatFrequency(dynamic frequency, dynamic scheduleType) {
    if (frequency == null) return "N/A";
    
    int freq = frequency is int ? frequency : int.tryParse(frequency.toString()) ?? 1;
    String type = (scheduleType ?? "daily").toString().toLowerCase();
    
    if (type == "daily") {
      return freq == 1 ? "Once daily" : "$freq times daily";
    } else if (type == "weekly") {
      return freq == 1 ? "Once weekly" : "$freq times per week";
    } else if (type == "monthly") {
      return freq == 1 ? "Once monthly" : "$freq times per month";
    }
    
    return "$freq times per $type";
  }

  /// Formats the dose quantity to a readable string
  String _formatDoseQuantity(dynamic quantity) {
    if (quantity == null) return "N/A";
    
    if (quantity is int) return quantity.toString();
    if (quantity is double) {
      // Format to remove trailing zeros if it's a whole number
      return quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1);
    }
    
    return quantity.toString();
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
          "Are you sure you want to delete the reminder for ${_reminder["medicationName"]}? This action cannot be undone."
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
        await reminderService.deleteReminder(_reminder);
        
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

  // Add this method to handle renewing an expired reminder
  Future<void> _renewReminder(ReminderService reminderService) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar("You must be logged in to perform this action");
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final newReminderId = await reminderService.renewReminder(user.uid, _reminder["id"]);
      
      if (newReminderId != null) {
        // Get the new reminder data
        final newReminder = await reminderService.getReminderById(user.uid, newReminderId);
        
        if (newReminder != null) {
          // Schedule notifications for the new reminder
          final notificationController = Provider.of<NotificationController>(context, listen: false);
          notificationController.scheduleReminderNotifications(newReminder);
        }
        
        setState(() => _isLoading = false);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reminder renewed successfully")),
        );
        
        // Navigate back to the reminders list
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Failed to renew reminder");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Error renewing reminder: $e");
    }
  }

  // Add this method to the _ReminderDetailScreenState class
  void _confirmDeleteProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Progress History",
        message: "Are you sure you want to delete all progress history for this reminder? This action cannot be undone.",
        onConfirm: () async {
          setState(() => _isLoading = true);
          
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              _showSnackBar("You must be logged in to delete progress data", isError: true);
              setState(() => _isLoading = false);
              return;
            }
            
            final progressController = Provider.of<ProgressController>(context, listen: false);
            await progressController.deleteProgressForReminder(_reminder['id']);
            
            setState(() => _isLoading = false);
            _showSnackBar("Progress history deleted successfully");
          } catch (e) {
            setState(() => _isLoading = false);
            _showSnackBar("Failed to delete progress history: ${e.toString()}", isError: true);
          }
        },
      ),
    );
  }

  // Add this helper method to the _ReminderDetailScreenState class
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
        action: isError 
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }
}