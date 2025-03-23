import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  }) {
    try {
      // Basic validation
      if (userMedicationId.isEmpty) {
        throw FormatException('Medication ID cannot be empty');
      }
      
      if (medicationName.isEmpty) {
        throw FormatException('Medication name cannot be empty');
      }
      
      if (!isIndefinite) {
        if (durationLength == null || durationLength.isEmpty) {
          throw FormatException('Duration length is required for definite reminders');
        }
        if (durationUnits == null || durationUnits.isEmpty) {
          throw FormatException('Duration units are required for definite reminders');
        }
      }
      
      // Convert timings to a storable format if not using smart scheduling
      List<Map<String, int>>? timingsData;
      if (!smartScheduling && timings != null && timings.isNotEmpty) {
        timingsData = timings.map((time) => {
          'hour': time.hour,
          'minute': time.minute,
        }).toList();
      }
      
      // Create and return the data map
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
        'isEnabled': isEnabled, // Add enabled flag
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
  /// Returns a Future that completes when the operation is done
  Future<void> toggleReminderState(String userId, String reminderId, bool isEnabled) async {
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

  /// Deletes a reminder from FireStore.
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

      await firestoreService.deleteDoc(collectionPath: collectionPath, docId: reminder["id"]);
      log("Reminder deleted successfully");
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
        "medicationType": updatedMedDetails["medType"],
        "scheduleType": updatedMedDetails["scheduleType"],
        "frequency": updatedMedDetails["frequency"],
        "doseUnits": updatedMedDetails["doseUnits"],
        "doseQuantity": updatedMedDetails["doseQuantity"],
      };
      
      // Only add applicationSite if it's an eye medication
      if (updatedMedDetails["medType"] == "Eye Medication" && 
          updatedMedDetails.containsKey("applicationSite")) {
        reminderUpdates["applicationSite"] = updatedMedDetails["applicationSite"];
      }
      
      // Update each reminder
      int updatedCount = 0;
      for (var reminder in reminderDocs) {
        if (reminder.containsKey("id") && reminder["id"] != null) {
          final bool success = await firestoreService.updateDoc(
            collectionPath: "users/$userId/reminders",
            docId: reminder["id"],
            newData: reminderUpdates,
          );
          
          if (success) updatedCount++;
        }
      }
      
      log("Updated $updatedCount reminders for medication $medicationId");
      return updatedCount;
    } on FirebaseException catch (e) {
      log("Firestore error updating reminders: ${e.message}");
      throw Exception("Failed to update associated reminders: ${e.message}");
    } catch (e) {
      log("Error updating reminders: $e");
      throw Exception("Error updating associated reminders: $e");
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
}