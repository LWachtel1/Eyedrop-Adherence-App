import 'dart:developer';
import 'dart:async';
import 'package:eyedrop/features/notifications/services/notification_service.dart';
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

abstract class ScheduleTypeBaseScreen extends StatefulWidget {
  const ScheduleTypeBaseScreen({Key? key}) : super(key: key);
}

abstract class ScheduleTypeBaseState<T extends ScheduleTypeBaseScreen> extends State<T> {
  // View options
  bool _showDayView = true;
  
  // For pending notifications data
  List<Map<String, dynamic>> _pendingNotifications = [];
  Map<String, Map<String, dynamic>> _reminderDataById = {};
  Map<String, int> _pendingCountByReminder = {};
  bool _isLoading = true;
  String _errorMessage = '';
  
  // For grouping notifications
  final Map<String, List<ScheduledReminder>> _scheduledRemindersByDay = {};
  
  Timer? _refreshTimer;

  // To be implemented by subclasses
  String get scheduleType;
  String get screenTitle;
  Color get themeColor;
  IconData get screenIcon;

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
      
      // Filter reminders to only include those with the specified schedule type
      final filteredReminderDataById = <String, Map<String, dynamic>>{};
      for (var entry in reminderDataById.entries) {
        if (entry.value['scheduleType']?.toString().toLowerCase() == scheduleType.toLowerCase()) {
          filteredReminderDataById[entry.key] = entry.value;
        }
      }
      
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
        final reminderData = filteredReminderDataById[reminderId];
        if (reminderData == null) continue; // Skip if reminder is not of the specified schedule type
        
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
        _reminderDataById = filteredReminderDataById;
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
          // Header with title and back button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: themeColor.withOpacity(0.2), width: 0.5) // Fix excessive width
              )
            ),
            child: Row(
              children: [
                Icon(screenIcon, color: themeColor, size: 20.sp),
                SizedBox(width: 2.w),
                Expanded( // Add Expanded to make title take available space, not fixed size
                  child: Text(
                    screenTitle,
                    style: TextStyle(
                      fontSize: 16.sp, // Slightly reduced font size
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                    overflow: TextOverflow.ellipsis, // Add overflow handling
                  ),
                ),
                // View selector button - now these won't overflow
                IconButton(
                  padding: EdgeInsets.all(1.w), // Smaller padding
                  constraints: BoxConstraints(), // Remove default constraints
                  icon: Icon(
                    _showDayView ? Icons.view_day : Icons.view_module,
                    color: themeColor,
                    size: 18.sp, // Slightly smaller icon
                  ),
                  onPressed: () {
                    setState(() {
                      _showDayView = !_showDayView;
                    });
                  },
                  tooltip: _showDayView ? 'Switch to card view' : 'Switch to day view',
                ),
                IconButton(
                  padding: EdgeInsets.all(1.w), // Smaller padding
                  constraints: BoxConstraints(), // Remove default constraints
                  icon: Icon(Icons.refresh, color: themeColor, size: 18.sp),
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                ),
                IconButton(
                  padding: EdgeInsets.all(1.w), // Smaller padding
                  constraints: BoxConstraints(), // Remove default constraints
                  icon: Icon(Icons.arrow_back, color: themeColor, size: 18.sp),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back to all reminders',
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                        ),
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
              child: _showDayView
                  ? _buildDayView()
                  : _buildReminderCardView(),
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
                screenIcon,
                size: 40.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 2.h),
              Text(
                "No $scheduleType reminders found",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                "You don't have any active $scheduleType reminders scheduled at this time. Create a new reminder to see it in your schedule.",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_back),
                label: Text("Back to All Reminders"),
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayView() {
    // Get sorted days
    final sortedDays = _scheduledRemindersByDay.keys.toList()..sort();
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final dayString = sortedDays[index];
        
        // Ensure all reminders for this day are properly sorted by time
        final reminders = _scheduledRemindersByDay[dayString]!;
        reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        
        // Format day string for display
        final date = DateFormat('yyyy-MM-dd').parse(dayString);
        final now = DateTime.now();
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        final isTomorrow = date.year == now.year && date.month == now.month && date.day == now.day + 1;
        
        String dayLabel = DateFormat('EEEE, MMMM d').format(date);
        if (isToday) {
          dayLabel = 'Today - $dayLabel';
        } else if (isTomorrow) {
          dayLabel = 'Tomorrow - $dayLabel';
        }
        
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(isToday ? Icons.today : Icons.calendar_today, 
                         color: themeColor, size: 16.sp),
                    SizedBox(width: 2.w),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isToday ? themeColor : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  children: reminders.map((reminder) => _buildReminderTimeRow(reminder)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildReminderTimeRow(ScheduledReminder reminder) {
    final now = DateTime.now();
    final isPast = reminder.scheduledTime.isBefore(now);
    final timeString = DateFormat('h:mm a').format(reminder.scheduledTime);
    
    return InkWell(
      onTap: () => _navigateToReminderDetails(reminder.reminderData),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            Container(
              width: 18.w,
              child: Text(
                timeString,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isPast ? Colors.grey : themeColor,
                  decoration: isPast ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.medicationName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isPast ? Colors.grey[600] : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reminder.reminderData['doseQuantity'] != null && 
                      reminder.reminderData['doseUnits'] != null)
                    Text(
                      '${_formatDoseQuantity(reminder.reminderData['doseQuantity'])} ${reminder.reminderData['doseUnits']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
            if (reminder.reminderData['medicationType'] == 'Eye Medication' &&
                reminder.reminderData['applicationSite'] != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  reminder.reminderData['applicationSite'],
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: themeColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReminderCardView() {
    // Group notifications by medication+reminder ID combination
    final reminderGroups = <String, List<ScheduledReminder>>{};
    final now = DateTime.now();

    // First, group all scheduled reminders by their reminder ID
    _scheduledRemindersByDay.forEach((day, reminders) {
      for (var reminder in reminders) {
        final key = reminder.reminderId;
        if (!reminderGroups.containsKey(key)) {
          reminderGroups[key] = [];
        }
        reminderGroups[key]!.add(reminder);
      }
    });
    
    // Sort each group by time (ascending order)
    reminderGroups.forEach((reminderId, reminders) {
      reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    });
    
    final medicationReminders = reminderGroups.entries.map((entry) {
      final group = entry.value;

      // Sort by scheduled time
      group.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      // Pick the next upcoming or fallback to the earliest past one
      final upcoming = group.firstWhere(
        (r) => r.scheduledTime.isAfter(now),
        orElse: () => group.first,
      );

      return upcoming.copyWith(scheduledNotifications: group);
    }).toList();
    
    return GridView.builder(
      padding: EdgeInsets.all(3.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: medicationReminders.length,
      itemBuilder: (context, index) {
        final reminder = medicationReminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(ScheduledReminder reminder) {
    final reminderData = reminder.reminderData;
    final isEnabled = reminderData['isEnabled'] ?? true;
    final isExpired = reminderData['isExpired'] == true;
    
    // Format next time
    final now = DateTime.now();
    final isPast = reminder.scheduledTime.isBefore(now);
    final nextTimeString = DateFormat('h:mm a').format(reminder.scheduledTime);
    final nextDateString = DateFormat('E, MMM d').format(reminder.scheduledTime);
    
    // Count upcoming reminders for this medication
    final upcomingCount = _pendingCountByReminder[reminder.reminderId] ?? 0;
    
    // Count total scheduled notifications for today and future
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayNotifications = reminder.scheduledNotifications?.where(
      (r) => DateFormat('yyyy-MM-dd').format(r.scheduledTime) == today
    )?.toList() ?? [];
    
    final futureNotifications = reminder.scheduledNotifications?.where(
      (r) => r.scheduledTime.isAfter(now) && 
             DateFormat('yyyy-MM-dd').format(r.scheduledTime) != today
    )?.toList() ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isExpired ? Colors.red[50] : (isEnabled ? null : Colors.grey[100]),
      child: InkWell(
        onTap: () => _navigateToReminderDetails(reminder.reminderData),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      size: 16.sp,
                      color: themeColor,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      reminder.medicationName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              Divider(),
              
              // Next dose
              Text(
                "Next Reminder:",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(Icons.access_time, 
                       size: 14.sp, 
                       color: isPast ? Colors.grey : themeColor),
                  SizedBox(width: 1.w),
                  Text(
                    nextTimeString,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.grey : themeColor,
                      decoration: isPast ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              Text(
                nextDateString,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: 1.h),
              
              // Show all scheduled times for today
              if (todayNotifications.isNotEmpty) ...[
                Text(
                  "Today's Times:",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Wrap(
                  spacing: 1.w,
                  children: todayNotifications.map((r) {
                    final timeStr = DateFormat('h:mm a').format(r.scheduledTime);
                    final isPast = r.scheduledTime.isBefore(now);
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 0.5.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w, 
                        vertical: 0.3.h
                      ),
                      decoration: BoxDecoration(
                        color: isPast ? Colors.grey[200] : themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isPast ? Colors.grey[600] : themeColor,
                          decoration: isPast ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              Spacer(),
              
              // Dosage info
              if (reminderData['doseQuantity'] != null && reminderData['doseUnits'] != null)
                Row(
                  children: [
                    Icon(Icons.medication, size: 14.sp, color: Colors.grey[700]),
                    SizedBox(width: 1.w),
                    Text(
                      '${_formatDoseQuantity(reminderData['doseQuantity'])} ${reminderData['doseUnits']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              
              // Application site for eye medications
              if (reminderData['medicationType'] == 'Eye Medication' && 
                  reminderData['applicationSite'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 14.sp, color: Colors.grey[700]),
                      SizedBox(width: 1.w),
                      Text(
                        reminderData['applicationSite'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 1.h),
              
              // Upcoming count
              if (futureNotifications.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${futureNotifications.length} more upcoming",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: themeColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReminderDetails(Map<String, dynamic> reminderData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailScreen(reminder: reminderData),
      ),
    );
  }
  
  String _formatDoseQuantity(dynamic quantity) {
    if (quantity == null) return '';
    
    if (quantity is int) return quantity.toString();
    if (quantity is double) {
      // Format to remove trailing zeros if it's a whole number
      return quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1);
    }
    
    return quantity.toString();
  }
}

// Include the same ScheduledReminder class
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