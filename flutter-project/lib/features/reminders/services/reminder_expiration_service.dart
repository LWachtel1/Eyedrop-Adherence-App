import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle automatic expiration of time-limited reminders.
class ReminderExpirationService {
  final ReminderService _reminderService;
  
  ReminderExpirationService(this._reminderService);
  
  /// Checks all reminders for the current user and disables any that have expired.
  ///
  /// Returns the number of reminders that were disabled due to expiration.
  Future<int> checkAndDisableExpiredReminders({
    required NotificationController notificationController
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('No authenticated user found for checking expired reminders');
        return 0;
      }
      
      // Get all reminders (including both enabled and disabled)
      final reminders = await _reminderService.getAllReminders(user.uid);
      final now = DateTime.now();
      int expiredCount = 0;
      
      for (final reminder in reminders) {
        // Skip if the reminder is already disabled or indefinite
        if (reminder['isEnabled'] != true || reminder['isIndefinite'] == true) {
          continue;
        }
        
        // Get start date
        final startDateRaw = reminder['startDate'];
        if (startDateRaw == null) continue;
        
        DateTime startDate;
        if (startDateRaw is Timestamp) {
          startDate = startDateRaw.toDate();
        } else if (startDateRaw is DateTime) {
          startDate = startDateRaw;
        } else {
          continue; // Invalid date format
        }
        
        // Get duration information
        final durationLength = int.tryParse(reminder['durationLength']?.toString() ?? '0') ?? 0;
        final durationUnits = reminder['durationUnits']?.toString() ?? '';
        
        if (durationLength <= 0 || durationUnits.isEmpty) continue;
        
        // Calculate end date
        DateTime endDate;
        switch (durationUnits.toLowerCase()) {
          case 'days':
            endDate = startDate.add(Duration(days: durationLength));
            break;
          case 'weeks':
            endDate = startDate.add(Duration(days: durationLength * 7));
            break;
          case 'months':
            // Approximate months as 30 days
            endDate = startDate.add(Duration(days: durationLength * 30));
            break;
          case 'years':
            // Approximate years as 365 days
            endDate = startDate.add(Duration(days: durationLength * 365));
            break;
          default:
            continue; // Unknown duration unit
        }
        
        // If the reminder has expired, mark it as expired
        if (now.isAfter(endDate)) {
          log('Disabling expired reminder: ${reminder['medicationName']} (ID: ${reminder['id']})');
          
          await _reminderService.markReminderAsExpired(
            user.uid, 
            reminder['id'],
            onExpired: (updatedReminder) {
              // This will also cancel any scheduled notifications
              notificationController.scheduleReminderNotifications(updatedReminder);
            }
          );
          
          expiredCount++;
        }
      }
      
      log('Checked reminders for expiration: $expiredCount reminders disabled');
      return expiredCount;
    } catch (e) {
      log('Error checking for expired reminders: $e');
      return 0;
    }
  }
}