import 'dart:developer';
import 'dart:async';
import 'package:eyedrop/main.dart' show navigatorKey;
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eyedrop/features/notifications/services/notification_service.dart';
import 'package:eyedrop/features/progress/services/progress_service.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/features/reminders/services/reminder_expiration_service.dart';

/// NotificationController manages the notification preferences and logic related to scheduling, rescheduling, and handling reminder notification taps.
/// 
/// It communicates between the UI and NotificationService/ReminderService.
class NotificationController extends ChangeNotifier {

  // Services used to handle notification logic and fetch reminder data.
  final NotificationService _notificationService;
  final ReminderService _reminderService;
  final ReminderExpirationService _expirationService;
  final ProgressService _progressService = ProgressService();

  Timer? _expirationCheckTimer;
  
  // Expose current user preferences to the UI.
  bool get notificationsEnabled => _notificationService.notificationsEnabled;
  bool get soundEnabled => _notificationService.soundEnabled;
  bool get vibrationEnabled => _notificationService.vibrationEnabled;
  
  // Constructor: initializes notification service, schedules all active reminders, and listens for taps.
  NotificationController({
    required NotificationService notificationService,
    required ReminderService reminderService,
    required ReminderExpirationService expirationService,
  }) : _notificationService = notificationService,
       _reminderService = reminderService,
       _expirationService = expirationService {
    // Initialises notification plugin when controller is created.
    _notificationService.initialize().then((_) {

      // Schedule all active medication reminders for the current user after successful initialisation of notification plugin. 
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _notificationService.scheduleAllReminders(user.uid, _reminderService);
        
        // Check for expired reminders immediately upon initialization
        _checkForExpiredReminders();
        
        // Then set up a periodic check (every 6 hours)
        _startExpirationCheckTimer();
      }
    });
    
    // Listen to tap events on notifications and respond.
    _notificationService.notificationStream.listen(_handleNotificationTap);
  }
  
  /// Handles notification tap by navigating to the ReminderDetailScreen.
  void _handleNotificationTap(notificationData) {
    if (notificationData == null) return;
    
    log('User tapped on notification: ${notificationData.medicationName}');
    
    // Record medication taken
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && notificationData.reminderId.isNotEmpty) {
    _recordMedicationTaken(user.uid, notificationData);

      // Gets the navigator state using global key from main.dart.
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator == null) return;
      
      // Navigates to reminder details screen if we have a reminder ID.
      if (notificationData.reminderId.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        
        // Fetch the full reminder data and navigate to the details screen.
        _reminderService.getReminderById(user.uid, notificationData.reminderId)
          .then((reminder) {
            if (reminder != null) {
              navigator.push(MaterialPageRoute(
                builder: (context) => ReminderDetailScreen(reminder: reminder)
              ));
            }
          });
      }
    }
  }
  // Add new method to record medication taken
  Future<void> _recordMedicationTaken(String userId, notificationData) async {
    try {
      // Extract scheduled time from notification ID or payload
      // For this implementation, we'll use the current time, but in practice
      // you would want to extract the exact scheduled time from the notification
      DateTime now = DateTime.now();
      
      // Get the reminder details to obtain the schedule type
      final reminder = await _reminderService.getReminderById(
        userId, 
        notificationData.reminderId
      );
      
      if (reminder != null) {
        // Record the medication as taken
        await _progressService.recordMedicationTaken(
          userId: userId,
          reminderId: notificationData.reminderId,
          medicationId: notificationData.medicationId,
          scheduledAt: now.subtract(Duration(minutes: 1)), // Approximate scheduled time
          respondedAt: now,
          scheduleType: reminder['scheduleType'] ?? 'daily',
        );
      }
    } catch (e) {
      log('Error recording medication taken: $e');
    }
  }
  
  /// Toggles global notification setting and reschedules reminders if enabled.
  Future<void> toggleNotifications(bool enabled) async {
    await _notificationService.setNotificationsEnabled(enabled);
    
    // If enabling notifications, reschedule all reminders.
    if (enabled) {
      await _rescheduleAllReminders();
    }
    
    notifyListeners();
  }
  
  /// Toggles notification sound on/off.
  Future<void> toggleSound(bool enabled) async {
    await _notificationService.setSoundEnabled(enabled);
    notifyListeners();
  }
  
  /// Toggle notification vibration on/off.
  Future<void> toggleVibration(bool enabled) async {
    await _notificationService.setVibrationEnabled(enabled);
    notifyListeners();
  }
  
  /// Schedules notifications for a specific reminder based on its settings.
  Future<void> scheduleReminderNotifications(Map<String, dynamic> reminder) async {
    if (!_notificationService.notificationsEnabled) return;
    
    // Add grace period tracking (60 minutes after notification)
  _scheduleMissedMedicationCheck(reminder, Duration(minutes: 60));

    final reminderId = reminder['id'];
    if (reminderId == null) {
      log('Cannot schedule notifications: reminder has no ID');
      return;
    }
    
    // Always cancel existing notifications for this reminder first
    await _notificationService.cancelReminderNotifications(reminderId);
    
    // Skip scheduling if the reminder is disabled
    if (reminder['isEnabled'] != true) {
      log('Reminder is disabled, not scheduling notifications');
      return;
    }
    
    final medicationId = reminder['userMedicationId'];
    final medicationName = reminder['medicationName'] ?? 'Medication';
    final doseQuantity = reminder['doseQuantity']?.toString() ?? '';
    final doseUnits = reminder['doseUnits'] ?? '';
    final doseInfo = '$doseQuantity $doseUnits'.trim();
    String? applicationSite;
    
    if (reminder['medicationType'] == 'Eye Medication') {
      applicationSite = reminder['applicationSite'];
    }
    
    // Check if using manual or smart scheduling
    if (reminder['smartScheduling'] == false && reminder['timings'] is List) {
      // Manual scheduling with specific times
      final timings = reminder['timings'] as List;
      
      await _notificationService.scheduleManualReminder(
        reminderId: reminderId,
        medicationId: medicationId,
        medicationName: medicationName,
        applicationSite: applicationSite,
        doseInfo: doseInfo,
        timings: timings,
      );
      
      log('Scheduled manual reminders for: $medicationName');
    } else {
      // Smart scheduling based on frequency and time range
      final frequency = reminder['frequency'] ?? 1;
      final scheduleType = reminder['scheduleType'] ?? 'daily'; // Get scheduleType
      final startTime = reminder['startTime'];
      final endTime = reminder['endTime'];
      
      await _notificationService.scheduleSmartReminder(
        reminderId: reminderId, 
        medicationId: medicationId,
        medicationName: medicationName,
        applicationSite: applicationSite,
        doseInfo: doseInfo,
        frequency: frequency,
        scheduleType: scheduleType, // Pass scheduleType
        startTime: startTime,
        endTime: endTime,
      );
      
      log('Scheduled smart reminders for: $medicationName');
    }
  }

  // Add new method to check for missed medications
Future<void> _scheduleMissedMedicationCheck(Map<String, dynamic> reminder, Duration gracePeriod) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  final reminderId = reminder['id'];
  final medicationId = reminder['userMedicationId'];
  
  if (reminderId == null || medicationId == null) return;
  
  // Get the current time as an approximation of when the notification was scheduled
  final scheduledTime = DateTime.now();
  
  // Schedule a delayed check for the reminder response
  Future.delayed(gracePeriod, () async {
    // Check if this notification has already been handled
    bool hasEntry = await _progressService.hasProgressEntryForScheduledTime(
      userId: user.uid,
      reminderId: reminderId,
      scheduledTime: scheduledTime,
    );
    
    if (!hasEntry) {
      // No progress entry means no response - record as missed
      await _progressService.recordMedicationMissed(
        userId: user.uid,
        reminderId: reminderId,
        medicationId: medicationId,
        scheduledAt: scheduledTime,
        scheduleType: reminder['scheduleType'] ?? 'daily',
      );
    }
  });
}
  
  /// Helper to reschedule all reminders for the current user.
  Future<void> _rescheduleAllReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _notificationService.scheduleAllReminders(user.uid, _reminderService);
  }

  /// Reschedules all reminders: preserves future notifications when possible.
  Future<void> rescheduleAllReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('No authenticated user found');
        return;
      }
      
      // Get all enabled reminders
      final reminders = await _reminderService.getAllEnabledReminders(user.uid);
      if (reminders.isEmpty) {
        await _notificationService.cancelAllNotifications();
        log('No active reminders found, cancelled all notifications');
        return;
      }
      
      // Get pending notifications
      final pendingNotifications = await _notificationService.getPendingNotificationRequests();
      
      // Determine which reminders are missing notifications
      final Set<String> reminderIdsWithNotifications = {};
      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          final payloadParts = notification.payload!.split('|');
          if (payloadParts.isNotEmpty) {
            reminderIdsWithNotifications.add(payloadParts[0]);
          }
        }
      }
      
      // Check which reminders need rescheduling
      final remindersToReschedule = <Map<String, dynamic>>[];
      for (final reminder in reminders) {
        final reminderId = reminder['id'];
        if (reminderId != null && !reminderIdsWithNotifications.contains(reminderId)) {
          // This reminder has no active notifications, needs rescheduling
          remindersToReschedule.add(reminder);
        }
      }
      
      // If all reminders need rescheduling, it's more efficient to just reset everything
      if (remindersToReschedule.length == reminders.length) {
        await _notificationService.cancelAllNotifications();
        await _notificationService.scheduleAllReminders(user.uid, _reminderService);
        log('All reminders rescheduled from scratch');
      } else if (remindersToReschedule.isNotEmpty) {
        // Schedule just the missing reminders
        for (final reminder in remindersToReschedule) {
          await scheduleReminderNotifications(reminder);
        }
        log('Selectively rescheduled ${remindersToReschedule.length} reminders with missing notifications');
      } else {
        log('All reminders already have active notifications, nothing to reschedule');
      }
    } catch (e) {
      log('Error rescheduling reminders: $e');
    }
  }

  /// Add methods for handling reminder expiration
  void _startExpirationCheckTimer() {
    // Cancel any existing timer
    _expirationCheckTimer?.cancel();
    
    // Check every 6 hours (21600000 milliseconds)
    _expirationCheckTimer = Timer.periodic(
      const Duration(hours: 6), 
      (_) => _checkForExpiredReminders()
    );
  }

  Future<void> _checkForExpiredReminders() async {
    final count = await _expirationService.checkAndDisableExpiredReminders(
      notificationController: this
    );
    
    if (count > 0) {
      log('$count reminders were automatically disabled due to expiration');
    }
  }

  /// Override dispose to clean up the timer
  @override
  void dispose() {
    _expirationCheckTimer?.cancel();
    super.dispose();
  }

  /// Add a public method to manually check for expired reminders
  Future<int> checkForExpiredReminders() async {
    return await _expirationService.checkAndDisableExpiredReminders(
      notificationController: this
    );
  }
  
}


