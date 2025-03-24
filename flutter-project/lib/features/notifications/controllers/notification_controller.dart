import 'dart:developer';
import 'dart:async';
import 'package:eyedrop/main.dart' show navigatorKey;
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eyedrop/features/notifications/services/notification_service.dart';
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
      final startTime = reminder['startTime'];
      final endTime = reminder['endTime'];
      
      await _notificationService.scheduleSmartReminder(
        reminderId: reminderId, 
        medicationId: medicationId,
        medicationName: medicationName,
        applicationSite: applicationSite,
        doseInfo: doseInfo,
        frequency: frequency,
        startTime: startTime,
        endTime: endTime,
      );
      
      log('Scheduled smart reminders for: $medicationName');
    }
  }
  
  /// Helper to reschedule all reminders for the current user.
  Future<void> _rescheduleAllReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _notificationService.scheduleAllReminders(user.uid, _reminderService);
  }

  /// Reschedules all reminders: cancels existing, then schedules fresh.
  Future<void> rescheduleAllReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('No authenticated user found');
        return;
      }
      
      await _notificationService.cancelAllNotifications();
      await _notificationService.scheduleAllReminders(user.uid, _reminderService);
      
      log('All reminders rescheduled successfully');
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


