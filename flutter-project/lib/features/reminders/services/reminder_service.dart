import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/progress/services/progress_service.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

/// Service class for handling reminder-related operations with FireStore.
/// 
/// Operations:
/// - Creates a map storing reminder data (to be passed to a Firestore document).
/// - Adds a new reminder to Firestore.
/// - Checks for duplicate reminders.
/// - Manages reminder streams and deletions.
/// - Toggles reminder enabled/disabled state.
class ReminderService {
  final FirestoreService firestoreService;

  ReminderService(this.firestoreService);

  /// Creates reminder data map to be stored in FireStore.
  /// 
  /// Parameters:
  /// - `userMedicationId`: The ID of the associated user medication
  /// - `medicationType`: Whether it's an eye or non-eye medication - must always be 'eye'.
  /// - `medicationName`: The name of the medication
  /// - `startDate`: When to start the reminder
  /// - `isIndefinite`: Whether the reminder runs indefinitely
  /// - `durationUnits`: The units of the duration
  /// - `durationLength`: The length of the duration
  /// - `smartScheduling`: Whether to use smart scheduling
  /// - `timings`: List of specific timings if not using smart scheduling
  /// - `scheduleType`: Type of schedule (daily, weekly, monthly)
  /// - `frequency`: How often the medication should be taken
  /// - `doseUnits`: Units of the dose (e.g., drops, tablets)
  /// - `doseQuantity`: Amount of medication per dose
  /// - `applicationSite`: Where to apply the medication (for eye medications)
  Map<String, dynamic> createReminderData({
    required String userMedicationId,
    required String medicationType,
    required String medicationName,
    required DateTime startDate,
    required bool isIndefinite,
    String? durationUnits,
    String? durationLength,
    required bool smartScheduling,
    required List<TimeOfDay>? timings,
    // Add additional medication details fields
    required String scheduleType,
    required int frequency,
    required String doseUnits,
    required double doseQuantity,
    String? applicationSite,
    bool isEnabled = true, // Default to enabled
    bool isExpired = false, // Default to not expired
  }) {
    try {
      List<Map<String, int>>? timingsData;
      if (!smartScheduling && timings != null && timings.isNotEmpty) {
        timingsData = timings.map((time) => {
          'hour': time.hour,
          'minute': time.minute,
        }).toList();
      }
      
      return {
        'userMedicationId': userMedicationId,
        'medicationType': medicationType,
        'medicationName': medicationName,
        'startDate': Timestamp.fromDate(startDate),
        'isIndefinite': isIndefinite,
        'durationUnits': isIndefinite ? '' : durationUnits,
        'durationLength': isIndefinite ? '' : durationLength,
        'smartScheduling': smartScheduling,
        'timings': timingsData ?? [],
        'createdAt': Timestamp.fromDate(DateTime.now()),
        // Add additional medication details
        'scheduleType': scheduleType,
        'frequency': frequency,
        'doseUnits': doseUnits,
        'doseQuantity': doseQuantity,
        'applicationSite': applicationSite,
        'isEnabled': isEnabled, 
        "isExpired": isExpired, 
      };
    } catch (e) {
      log("Error creating reminder data: $e");
      throw Exception("Invalid reminder data: ${e.toString()}");
    }
  }

  /// Toggles a reminder's enabled state in Firestore
  /// 
  /// Parameters:
  /// - `userId`: The ID of the user who owns the reminder
  /// - `reminderId`: The ID of the reminder to toggle
  /// - `isEnabled`: The new state (enabled or disabled)
  /// 
  /// Returns a Future that completes when the operation is done.
  Future<void> toggleReminderState(String userId, String reminderId, bool isEnabled, {Function(Map<String, dynamic>)? onToggled}) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      if (reminderId.isEmpty) {
        throw Exception('Reminder ID cannot be empty');
      }
      
      // Update the reminder in Firestore
      await firestoreService.updateDoc(
        collectionPath: "users/$userId/reminders",
        docId: reminderId,
        newData: {'isEnabled': isEnabled},
      );
      
      // Get the updated reminder to pass to the notification controller.
      final updatedReminder = await getReminderById(userId, reminderId);
      if (updatedReminder != null && onToggled != null) {
        onToggled(updatedReminder);
      }
      
      log("Reminder ${isEnabled ? 'enabled' : 'disabled'} successfully");
    } on FirebaseException catch (e) {
      log("Firestore Error toggling reminder state: ${e.message}");
      throw Exception("Failed to update reminder state: ${e.message}");
    } catch (e) {
      log("Unexpected error toggling reminder state: $e");
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  /// Checks if a reminder with the same medication already exists
  Future<bool> isDuplicateReminder(String userId, String medicationId) async {
    try {
      // Use the FirestoreService queryCollection method instead of direct Firestore access
      final results = await firestoreService.queryCollection(
        collectionPath: "users/$userId/reminders",
        filters: [
          {"field": "userMedicationId", "operator": "==", "value": medicationId}
        ]
      );
      
      return results.isNotEmpty;
    } on FirebaseException catch (e) {
      log("Firestore Error checking duplicate reminder: ${e.message}");
      if (e.code == "permission-denied") {
        throw Exception("You do not have permission to check for duplicates.");
      }
      return false;
    } catch (e) {
      log("Unexpected error checking duplicate reminder: $e");
      return false;
    }
  }

  /// Adds a new reminder to FireStore.
  Future<void> addReminder(String userId, Map<String, dynamic> reminderData) async {
    try {
      await firestoreService.addDoc(
        path: "users/$userId/reminders",
        data: reminderData,
      );

      // Update the medication's reminderSet field if it's an eye medication
      if (reminderData.containsKey("userMedicationId")) {
        await updateMedicationReminderStatus(userId, reminderData["userMedicationId"], true);
      }

      log("Reminder successfully added.");
    } on FirebaseException catch (e) {
      log("Firestore Error adding reminder: ${e.message}");
      if (e.code == "permission-denied") {
        throw Exception("You do not have permission to add reminders.");
      }
      throw Exception("Failed to add reminder: ${e.message}");
    } on PlatformException catch (e) {
      log("Platform Error adding reminder: ${e.message}");
      throw Exception("Platform error while adding reminder. Try again.");
    } catch (e) {
      log("Unexpected error adding reminder: $e");
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  /// Soft-deletes a reminder by marking it as deleted instead of removing it
  Future<void> deleteReminder(Map<String, dynamic> reminder) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No authenticated user found");
      }

      String collectionPath = "users/${user.uid}/reminders";

      if (!reminder.containsKey("id") || reminder["id"] == null) {
        log("Error: Reminder does not have an ID.");
        throw Exception("Reminder does not have an ID");
      }

      final reminderId = reminder["id"];
      
      // Check if this was the last reminder for this medication
      final medicationId = reminder["userMedicationId"];
      if (medicationId != null) {
        final remainingReminders = await firestoreService.queryCollection(
          collectionPath: collectionPath,
          filters: [
            {"field": "userMedicationId", "operator": "==", "value": medicationId}
          ],
        );
        
        // If this is the only reminder, update the medication's reminderSet field
        if (remainingReminders.length <= 1) {
          await updateMedicationReminderStatus(user.uid, medicationId, false);
        }
      }

      // First, delete all associated progress entries
      try {
        final progressService = ProgressService();
        await progressService.deleteProgressEntriesForReminder(
          userId: user.uid,
          reminderId: reminderId,
        );
        log("Progress entries for reminder deleted successfully");
      } catch (e) {
        log("Warning: Error deleting progress entries: $e");
        // Continue with deletion even if progress deletion fails
      }

      // Then delete the reminder document
      await firestoreService.deleteDoc(
        collectionPath: collectionPath, 
        docId: reminderId
      );
      
      log("Reminder and associated progress entries deleted successfully");
    } on FirebaseException catch (e) {
      log("Firestore error deleting reminder: ${e.message}");
      throw Exception("Failed to delete reminder: ${e.message}");
    } catch (e) {
      log("Error deleting reminder: $e");
      throw Exception("Error deleting reminder: $e");
    }
  }

  /// Creates a stream for all reminders.
  Stream<List<Map<String, dynamic>>> buildRemindersStream(String userId) {
    return firestoreService.getCollectionStreamWithIds("users/$userId/reminders");
  }

  /// Updates all reminders associated with a modified medication
  /// 
  /// When a medication is edited, this ensures all associated reminders are updated
  /// with the new medication details (name, type, dosage, etc.)
  /// Note: Duration-related fields are not automatically synced to preserve
  /// reminders that may have different durations
  ///
  /// Parameters:
  /// - `userId`: User ID whose reminders to update
  /// - `medicationId`: ID of the medication that was modified
  /// - `updatedMedDetails`: Map containing the updated medication details
  ///
  /// Returns: Number of reminders that were updated
  Future<int> updateRemindersForMedication(
    String userId, 
    String medicationId, 
    Map<String, dynamic> updatedMedDetails
  ) async {
    try {
      if (userId.isEmpty) {
        throw Exception("User ID cannot be empty");
      }
      
      if (medicationId.isEmpty) {
        throw Exception("Medication ID cannot be empty");
      }
      
      // Find all reminders associated with this medication
      final reminderDocs = await firestoreService.queryCollectionWithIds(
        collectionPath: "users/$userId/reminders",
        filters: [
          {"field": "userMedicationId", "operator": "==", "value": medicationId}
        ],
      );
      
      if (reminderDocs.isEmpty) {
        // No associated reminders found
        return 0;
      }
      
      log("Found ${reminderDocs.length} reminders to update for medication $medicationId");
      
      // Fields to sync from medication to reminders
      // Note: We intentionally don't sync duration-related fields to maintain reminder-specific durations
      final Map<String, dynamic> reminderUpdates = {
        "medicationName": updatedMedDetails["medicationName"],
      };
      
      // Copy medication type if present
      if (updatedMedDetails.containsKey("medType")) {
        reminderUpdates["medicationType"] = updatedMedDetails["medType"];
      }
      
      // Copy scheduling-related fields
      if (updatedMedDetails.containsKey("scheduleType")) {
        reminderUpdates["scheduleType"] = updatedMedDetails["scheduleType"];
      }
      
      if (updatedMedDetails.containsKey("frequency")) {
        reminderUpdates["frequency"] = updatedMedDetails["frequency"];
      }
      
      // Copy dosage information
      if (updatedMedDetails.containsKey("doseUnits")) {
        reminderUpdates["doseUnits"] = updatedMedDetails["doseUnits"];
      }
      
      if (updatedMedDetails.containsKey("doseQuantity")) {
        reminderUpdates["doseQuantity"] = updatedMedDetails["doseQuantity"];
      }
      
      // Handle eye-medication specific fields
      if (updatedMedDetails["medType"] == "Eye Medication" && 
          updatedMedDetails.containsKey("applicationSite")) {
        reminderUpdates["applicationSite"] = updatedMedDetails["applicationSite"];
      } else if (updatedMedDetails["medType"] != "Eye Medication") {
        // Remove applicationSite if medication is not for eyes
        reminderUpdates["applicationSite"] = null;
      }
      
      // Update all associated reminders
      int updatedCount = 0;
      for (final reminder in reminderDocs) {
        try {
          // Make sure we're passing a proper Map<String, dynamic>
          Map<String, dynamic> safeUpdates = Map<String, dynamic>.from(reminderUpdates);
          
          bool success = await firestoreService.updateDoc(
            collectionPath: "users/$userId/reminders",
            docId: reminder["id"],
            newData: safeUpdates,
          );
          
          if (success) updatedCount++;
        } catch (e) {
          log("Error updating reminder ${reminder["id"]}: $e");
          // Continue with other reminders even if one fails
        }
      }
      
      log("Updated $updatedCount reminders for medication $medicationId");
      return updatedCount;
    } on FirebaseException catch (e) {
      log("Firestore Error updating reminders: ${e.message}");
      throw Exception("Failed to update associated reminders: ${e.message}");
    } catch (e) {
      log("Unexpected error updating reminders: $e");
      throw Exception("An unexpected error occurred while updating reminders: $e");
    }
  }

  /// Gets a stream for a specific reminder document.
  /// 
  /// This allows real-time updates for a single reminder.
  /// 
  /// Parameters:
  /// - `userId`: The user ID for the reminder
  /// - `reminderId`: The ID of the reminder to stream
  /// 
  /// Returns:
  /// A stream of the reminder document as a Map, including the document ID
  Stream<Map<String, dynamic>?> getReminderDocumentStream(String userId, String reminderId) {
    if (userId.isEmpty || reminderId.isEmpty) {
      log("Error: User ID or reminder ID is empty");
      return Stream.value(null);
    }

    return firestoreService.getDocumentStream(
      collectionPath: "users/$userId/reminders", 
      docId: reminderId
    );
  }

  /// Updates the reminderSet field on the associated medication when creating a reminder
  Future<void> updateMedicationReminderStatus(String userId, String medicationId, bool hasReminder) async {
    try {
      // Get the medication to check if it's an eye medication
      final medicationDoc = await firestoreService.readDoc(
        collectionPath: "users/$userId/eye_medications", 
        docId: medicationId
      );
      
      // Only update eye medications
      if (medicationDoc != null) {
        await firestoreService.updateDoc(
          collectionPath: "users/$userId/eye_medications",
          docId: medicationId,
          newData: {"reminderSet": hasReminder},
        );
        log("Updated reminderSet status to $hasReminder for eye medication $medicationId");
      }
    } catch (e) {
      log("Error updating medication reminder status: $e");
      // Don't throw - this is a secondary operation that shouldn't fail the main process
    }
  }

  /// Get all enabled reminders for a user.
  /// 
  /// Provides all active reminders to NotificationService.scheduleAllReminders(), 
  /// which creates actual notifications.
  Future<List<Map<String, dynamic>>> getAllEnabledReminders(String userId) async {
    try {
      final reminders = await firestoreService.queryCollection(
        collectionPath: 'users/$userId/reminders',
        filters: [
          {"field": "isEnabled", "operator": "==", "value": true}
        ],
      );
      
      for (final reminder in reminders) {
        // Add additional fields if not present
        reminder['id'] ??= reminder['id'];
      }
      
      return reminders;
    } catch (e) {
      log('Error getting enabled reminders: $e');
      return [];
    }
  }
  
  /// Gets a specific reminder by ID.
  /// 
  /// E.g., enables notification tap to take user to reminder details screen.
  Future<Map<String, dynamic>?> getReminderById(String userId, String reminderId) async {
    try {
      final reminder = await firestoreService.readDoc(
        collectionPath: 'users/$userId/reminders',
        docId: reminderId,
      );
      
      if (reminder != null) {
        // Add ID to the map if not present
        reminder['id'] ??= reminderId;
      }
      
      return reminder;
    } catch (e) {
      log('Error getting reminder by ID: $e');
      return null;
    }
  }

  /// Get the most recently created reminder for a medication.
  /// 
  /// E.g., enables scheduling of a newly created reminder.
  Future<Map<String, dynamic>?> getCreatedReminder(String userId, String medicationId) async {
    try {
      // Check your FirestoreService.queryCollection implementation
      // Option 1: If it accepts a list of filters (based on your FirestoreService implementation)
      final reminders = await firestoreService.queryCollection(
        collectionPath: "users/$userId/reminders",
        filters: [
          {"field": "userMedicationId", "operator": "==", "value": medicationId}
        ],
        orderBy: {"field": "createdAt", "descending": true},
        limit: 1
      );
      
      if (reminders.isNotEmpty) {
        return reminders.first;
      }
      return null;
    } catch (e) {
      log("Error getting created reminder: $e");
      return null;
    }
  }

  /// Get all reminders for a user (both enabled and disabled)
  Future<List<Map<String, dynamic>>> getAllReminders(String userId) async {
    try {
      final reminders = await firestoreService.queryCollection(
        collectionPath: 'users/$userId/reminders',
      );
      
      for (final reminder in reminders) {
        // Add ID to the map if not present
        reminder['id'] ??= reminder['id'];
      }
      
      return reminders;
    } catch (e) {
      log('Error getting all reminders: $e');
      return [];
    }
  }

  /// Marks a reminder as expired in Firestore
  Future<void> markReminderAsExpired(String userId, String reminderId, {Function(Map<String, dynamic>)? onExpired}) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      if (reminderId.isEmpty) {
        throw Exception('Reminder ID cannot be empty');
      }
      
      // Update the reminder in Firestore
      await firestoreService.updateDoc(
        collectionPath: "users/$userId/reminders",
        docId: reminderId,
        newData: {
          'isEnabled': false,
          'isExpired': true,
          'expiredAt': Timestamp.fromDate(DateTime.now()),
        },
      );
      
      // Get the updated reminder to pass to the notification controller
      final updatedReminder = await getReminderById(userId, reminderId);
      if (updatedReminder != null && onExpired != null) {
        onExpired(updatedReminder);
      }
      
      log("Reminder marked as expired successfully");
    } on FirebaseException catch (e) {
      log("Firestore Error marking reminder as expired: ${e.message}");
      throw Exception("Failed to mark reminder as expired: ${e.message}");
    } catch (e) {
      log("Unexpected error marking reminder as expired: $e");
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  /// Renews an expired reminder with a fresh duration
  Future<String?> renewReminder(String userId, String oldReminderId) async {
    try {
      // Get the old reminder data
      final oldReminder = await getReminderById(userId, oldReminderId);
      if (oldReminder == null) return null;
      
      // Create new reminder data with reset duration
      final now = DateTime.now();
      
      // Copy most settings from the old reminder
      final newReminderData = Map<String, dynamic>.from(oldReminder);
      
      // Update key fields
      newReminderData.remove('id'); // Let Firestore generate a new ID
      newReminderData['isEnabled'] = true;
      newReminderData['isExpired'] = false;
      newReminderData['startDate'] = Timestamp.fromDate(now);
      newReminderData['createdAt'] = FieldValue.serverTimestamp();
      newReminderData['renewedFrom'] = oldReminderId; // Track origin
      
      // Add the new reminder
      final documentRef = await FirebaseFirestore.instance
          .collection('users/$userId/reminders')
          .add(newReminderData);
      
      final newReminderId = documentRef.id;
      
      // Optionally, mark the old one as renewed
      await firestoreService.updateDoc(
        collectionPath: "users/$userId/reminders",
        docId: oldReminderId,
        newData: {'renewedTo': newReminderId},
      );
      
      log("Renewed reminder $oldReminderId → $newReminderId");
      return newReminderId;
    } catch (e) {
      log("Error renewing reminder: $e");
      return null;
    }
  }
}