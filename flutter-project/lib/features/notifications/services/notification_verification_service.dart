import 'dart:async';
import 'dart:developer';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/notifications/services/notification_service.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service to verify notification scheduling is working properly
/// and perform periodic maintenance to ensure all active reminders
/// have properly scheduled notifications.
class NotificationVerificationService {
  final NotificationController _notificationController;
  final NotificationService _notificationService;
  final ReminderService _reminderService;
  
  // Timer for daily verification
  Timer? _dailyVerificationTimer;
  
  // Timer for midnight crossover check
  Timer? _midnightCrossoverTimer;
  
  // Track the last date when notifications were verified
  DateTime _lastVerificationDate = DateTime.now();
  
  NotificationVerificationService({
    required NotificationController notificationController,
    required NotificationService notificationService,
    required ReminderService reminderService,
  }) : _notificationController = notificationController,
       _notificationService = notificationService,
       _reminderService = reminderService {
    // Start the verification system
    _startVerification();
  }
  
  /// Start both verification timers
  void _startVerification() {
    _startDailyVerificationTimer();
    _startMidnightCrossoverCheck();
  }
  
  /// Starts a timer to perform verification every 4 hours
  void _startDailyVerificationTimer() {
    // Cancel any existing timer
    _dailyVerificationTimer?.cancel();
    
    // Verify every 4 hours
    _dailyVerificationTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => _verifyNotifications(),
    );
    
    log('Notification verification timer started - checking every 4 hours');
  }
  
  /// Checks if a day has passed and schedules a verification
  /// at midnight each day (specifically for date crossover)
  void _startMidnightCrossoverCheck() {
    // Cancel any existing timer
    _midnightCrossoverTimer?.cancel();
    
    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);
    
    // Schedule the one-time check at midnight
    _midnightCrossoverTimer = Timer(timeUntilMidnight, () {
      // Verify at midnight
      _verifyNotifications(forcedDateCheck: true);
      
      // Then restart the midnight timer for the next day
      _startMidnightCrossoverCheck();
    });
    
    log('Midnight crossover check scheduled for: $nextMidnight');
  }
  
  /// Verifies all notifications are properly scheduled
  Future<void> _verifyNotifications({bool forcedDateCheck = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final lastVerificationDay = DateTime(
      _lastVerificationDate.year,
      _lastVerificationDate.month,
      _lastVerificationDate.day
    );
    
    // Check if day has changed, or this is a forced check
    final dayChanged = currentDay.isAfter(lastVerificationDay);
    if (dayChanged || forcedDateCheck) {
      log('Day changed or forced check: rescheduling all notifications');
      
      // Only proceed if notifications are enabled
      if (_notificationService.notificationsEnabled) {
        await _notificationController.rescheduleAllReminders();
      }
      
      _lastVerificationDate = now;
    } else {
      // Perform a lighter check to verify pending notification count
      await _verifyPendingNotificationCount(user.uid);
    }
  }
  
  /// Verifies the number of pending notifications matches
  /// the expected count from enabled reminders
  Future<void> _verifyPendingNotificationCount(String userId) async {
    try {
      // Skip if notifications are disabled
      if (!_notificationService.notificationsEnabled) return;
      
      // Count enabled reminders
      final reminders = await _reminderService.getAllEnabledReminders(userId);
      
      // Get all pending notifications
      final pendingNotificationRequests = await _notificationService.getPendingNotificationRequests();
      final pendingNotifications = pendingNotificationRequests.length;
      
      // Calculate expected notification count (approximate)
      // This is a rough estimate as some reminders might have 
      // multiple notifications at different times
      int expectedMinCount = reminders.length;
      
      // If there are significantly fewer pending notifications than expected,
      // reschedule everything
      if (pendingNotifications < expectedMinCount) {
        log('Notification verification: found $pendingNotifications pending notifications, '
            'but expected at least $expectedMinCount. Rescheduling all notifications.');
        await _notificationController.rescheduleAllReminders();
      } else {
        log('Notification verification: found $pendingNotifications pending notifications, '
            'which meets the minimum expected count of $expectedMinCount');
      }
    } catch (e) {
      log('Error during notification verification: $e');
    }
  }
  
  /// Manually trigger a verification (for testing or if issues are suspected)
  Future<void> manuallyVerifyNotifications() async {
    await _verifyNotifications(forcedDateCheck: true);
  }
  
  /// Clean up resources
  void dispose() {
    _dailyVerificationTimer?.cancel();
    _midnightCrossoverTimer?.cancel();
  }
}