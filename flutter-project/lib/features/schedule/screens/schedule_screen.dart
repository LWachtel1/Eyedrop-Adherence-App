import 'dart:developer';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/notifications/services/notification_service.dart';
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/features/schedule/screens/daily_schedule_screen.dart';
import 'package:eyedrop/features/schedule/screens/monthly_schedule_screen.dart';
import 'package:eyedrop/features/schedule/screens/weekly_schedule_screen.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

class ScheduleScreen extends StatefulWidget {
  static const String id = '/schedule';

  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // For pending notifications data
  List<Map<String, dynamic>> _pendingNotifications = [];
  Map<String, Map<String, dynamic>> _reminderDataById = {};
  Map<String, int> _pendingCountByReminder = {};
  bool _isLoading = true;
  String _errorMessage = '';
  
  // For grouping notifications
  final Map<String, List<ScheduledReminder>> _scheduledRemindersByDay = {};
  
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Set up a timer to refresh the data every minute
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Update the UI to reflect passed times
        });
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to view your schedule';
        });
        return;
      }
      
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final reminderService = Provider.of<ReminderService>(context, listen: false);

      await notificationService.scheduleAllReminders(user.uid, reminderService);
      
      // Get all pending notifications
      final pendingNotifications = await notificationService.getAllScheduledNotifications();

      // Get all reminders to match with notifications
      final allReminders = await reminderService.getAllReminders(user.uid);
      final reminderDataById = {
        for (var reminder in allReminders) 
          reminder['id'] as String: reminder
      };
      
      // Count pending notifications per reminder
      final pendingCountByReminder = <String, int>{};
      
      // Group notifications by day
      final scheduledRemindersByDay = <String, List<ScheduledReminder>>{};
      
      for (var notification in pendingNotifications) {
        // Parse the payload to extract reminder ID
        final payload = notification['payload'];
        if (payload == null || payload.isEmpty) continue;
        
        final parts = payload.split('|');
        if (parts.length < 2) continue;
        
        final reminderId = parts[0];
        final reminderData = reminderDataById[reminderId];
        if (reminderData == null) continue;
        
        // Count this notification for the reminder
        pendingCountByReminder[reminderId] = (pendingCountByReminder[reminderId] ?? 0) + 1;
        
        // Extract scheduled time directly from the notification object
        DateTime scheduledTime = notification['scheduledDateTime'] ?? DateTime.now();
        
        final dayString = DateFormat('yyyy-MM-dd').format(scheduledTime);
        
        // Create scheduled reminder object
        final scheduledReminder = ScheduledReminder(
          id: notification['id'] ?? 0,
          reminderId: reminderId,
          medicationId: parts.length > 1 ? parts[1] : '',
          medicationName: parts.length > 2 ? parts[2] : 'Medication',
          scheduledTime: scheduledTime,
          reminderData: reminderData,
        );
        
        // Add to day group
        if (!scheduledRemindersByDay.containsKey(dayString)) {
          scheduledRemindersByDay[dayString] = [];
        }
        scheduledRemindersByDay[dayString]!.add(scheduledReminder);
      }
      
      // Sort each day's reminders by time
      for (var dayString in scheduledRemindersByDay.keys) {
        scheduledRemindersByDay[dayString]!.sort((a, b) => 
          a.scheduledTime.compareTo(b.scheduledTime)
        );
      }
      
      // Get a sorted list of days (for day view)
      final sortedDays = scheduledRemindersByDay.keys.toList()..sort();
      
      setState(() {
        _pendingNotifications = pendingNotifications;
        _reminderDataById = reminderDataById;
        _pendingCountByReminder = pendingCountByReminder;
        _scheduledRemindersByDay.clear();
        _scheduledRemindersByDay.addAll(scheduledRemindersByDay);
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading schedule data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedule data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Text(
                  'Schedule Overview',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20.sp),
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40.sp),
                      SizedBox(height: 2.h),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_scheduledRemindersByDay.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: _buildScheduleTypeButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 40.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 2.h),
              Text(
                "No upcoming reminders found",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                "You don't have any active reminders scheduled at this time. Create a new reminder to see it in your schedule.",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTypeButtons() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "View By Schedule Type",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            "Choose the type of schedule you want to view:",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 3.h),
          
          // Daily button - larger and more prominent
          _buildLargeScheduleButton(
            title: "Daily Reminders",
            description: "View medications scheduled on a daily basis",
            icon: Icons.today,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, DailyScheduleScreen.id),
          ),
          
          SizedBox(height: 2.h),
          
          // Weekly button
          _buildLargeScheduleButton(
            title: "Weekly Reminders",
            description: "View medications scheduled weekly",
            icon: Icons.view_week,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, WeeklyScheduleScreen.id),
          ),
          
          SizedBox(height: 2.h),
          
          // Monthly button
          _buildLargeScheduleButton(
            title: "Monthly Reminders",
            description: "View medications scheduled monthly",
            icon: Icons.calendar_month,
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, MonthlyScheduleScreen.id),
          ),
          
          SizedBox(height: 4.h),
          
         
        ],
      ),
    );
  }

  Widget _buildLargeScheduleButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26.sp,
                  color: color,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  
}

/// Helper class to represent a scheduled reminder
class ScheduledReminder {
  final int id;
  final String reminderId;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final Map<String, dynamic> reminderData;
  final List<ScheduledReminder>? scheduledNotifications;
  
  ScheduledReminder({
    required this.id,
    required this.reminderId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.reminderData,
    this.scheduledNotifications,
  });
  
  /// Creates a copy of this reminder with some fields changed
  ScheduledReminder copyWith({
    int? id,
    String? reminderId,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    Map<String, dynamic>? reminderData,
    List<ScheduledReminder>? scheduledNotifications,
  }) {
    return ScheduledReminder(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      reminderData: reminderData ?? this.reminderData,
      scheduledNotifications: scheduledNotifications ?? this.scheduledNotifications,
    );
  }
}