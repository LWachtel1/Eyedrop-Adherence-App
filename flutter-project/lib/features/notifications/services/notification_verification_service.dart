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
    
    try {
      // Skip if notifications are disabled
      if (!_notificationService.notificationsEnabled) return;
      
      // Get all enabled reminders
      final reminders = await _reminderService.getAllEnabledReminders(user.uid);
      if (reminders.isEmpty) {
        log('No enabled reminders found, skipping verification');
        return;
      }
      
      // Get all pending notifications
      final pendingNotifications = await _notificationService.getPendingNotificationRequests();
      
      // If there are no pending notifications but we have enabled reminders,
      // we definitely need to reschedule
      if (pendingNotifications.isEmpty) {
        log('No pending notifications found but there are enabled reminders. Rescheduling...');
        await _notificationController.rescheduleAllReminders();
        _lastVerificationDate = now;
        return;
      }
      
      // On day change or forced check, verify each reminder's notifications
      if (dayChanged || forcedDateCheck) {
        log('Performing full verification check');
        
        // Create a map of reminder IDs to their notification counts
        final notificationCounts = <String, int>{};
        for (final notification in pendingNotifications) {
          if (notification.payload != null) {
            final parts = notification.payload!.split('|');
            if (parts.isNotEmpty) {
              final reminderId = parts[0];
              notificationCounts[reminderId] = (notificationCounts[reminderId] ?? 0) + 1;
            }
          }
        }
        
        // Check each reminder's notifications
        final remindersToReschedule = <Map<String, dynamic>>[];
        for (final reminder in reminders) {
          final reminderId = reminder['id'];
          if (reminderId == null) continue;
          
          // Calculate expected notification count for this reminder
          int expectedCount = _calculateExpectedNotificationCount(reminder);
          int actualCount = notificationCounts[reminderId] ?? 0;
          
          // If the counts don't match, this reminder needs rescheduling
          if (actualCount < expectedCount) {
            remindersToReschedule.add(reminder);
          }
        }
        
        // Only reschedule reminders that need it
        if (remindersToReschedule.isNotEmpty) {
          log('Found ${remindersToReschedule.length} reminders needing rescheduling');
          for (final reminder in remindersToReschedule) {
            await _notificationController.scheduleReminderNotifications(reminder);
          }
        } else {
          log('All reminders have correct number of notifications');
        }
      } else {
        // For regular checks, just verify we have enough total notifications
        await _verifyPendingNotificationCount(user.uid);
      }
      
      _lastVerificationDate = now;
    } catch (e) {
      log('Error during notification verification: $e');
    }
  }
  
  /// Calculates how many notifications a reminder should have based on its schedule
  int _calculateExpectedNotificationCount(Map<String, dynamic> reminder) {
    final scheduleType = reminder['scheduleType']?.toString().toLowerCase() ?? 'daily';
    final frequency = reminder['frequency'] is int ? 
        reminder['frequency'] : 
        int.tryParse(reminder['frequency']?.toString() ?? '1') ?? 1;
    
    // For manual scheduling, use the timings list length
    if (reminder['smartScheduling'] == false && reminder['timings'] is List) {
      return reminder['timings'].length;
    }
    
    // For smart scheduling, use frequency
    switch (scheduleType) {
      case 'daily':
        return frequency;
      case 'weekly':
        return frequency;
      case 'monthly':
        return frequency;
      default:
        return frequency;
    }
  }
  
  /// Verifies the number of pending notifications matches
  /// the expected count from enabled reminders
  Future<void> _verifyPendingNotificationCount(String userId) async {
    try {
      // Get enabled reminders
      final reminders = await _reminderService.getAllEnabledReminders(userId);
      
      // Get pending notifications
      final pendingNotifications = await _notificationService.getPendingNotificationRequests();
      
      // Calculate total expected notifications
      int expectedTotal = 0;
      for (final reminder in reminders) {
        expectedTotal += _calculateExpectedNotificationCount(reminder);
      }
      
      // If we have significantly fewer notifications than expected,
      // trigger a full verification
      if (pendingNotifications.length < expectedTotal * 0.8) { // Allow for some variance
        log('Found ${pendingNotifications.length} notifications, but expected ~$expectedTotal. '
            'Performing full verification.');
        await _verifyNotifications(forcedDateCheck: true);
      } else {
        log('Notification count is within acceptable range '
            '(${pendingNotifications.length} vs expected $expectedTotal)');
      }
    } catch (e) {
      log('Error during notification count verification: $e');
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