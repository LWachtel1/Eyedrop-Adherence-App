import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/progress/services/progress_service.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';



/// Service class for handling user medication-related operations relevant for FireStore.
/// 
/// Operations:
/// - creates a map storing user medication data (to be passed to a Firestore document).
/// - checks if a user medication already exists in Firestore.
/// - adds a new user medication to Firestore.
class MedicationService {
  final FirestoreService firestoreService;

  MedicationService(this.firestoreService);

/// Fetches common medications from Firestore.
///
/// - Retrieves all documents from the `medications` collection.
/// - Handles Firestore and network-related errors.
///
/// Returns:
/// - `List<Map<String, dynamic>>` whcih provides a list of medications.
/// 
/// Throws:
/// - `Exception` if an error occurs while fetching the medications e.g., network issue.
Future<List<Map<String, dynamic>>> fetchCommonMedications() async {
  try {
    log("Fetching common medications...");

    List<Map<String, dynamic>> meds = await firestoreService.getAllDocs(collectionPath: "medications");

    if (meds.isEmpty) {
      throw Exception("No medications found in the database.");
    }

    // Sort medications alphabetically by name
    meds.sort((a, b) {
      String nameA = (a["medicationName"] ?? "").toString().toLowerCase();
      String nameB = (b["medicationName"] ?? "").toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    return meds;
  } on FirebaseException catch (e) {
    log("Firestore error while fetching medications: ${e.message}");
    throw Exception("Failed to fetch medications. Check your internet connection.");
  } catch (e) {
    log("Unexpected error fetching medications: $e");
    throw Exception("Something went wrong. Please try again later.");
  }
}

  /// Creates a user medication data map to be stored in FireStore.
  /// 
  /// Parameters:
  /// - `medicationName`: The name of the medication.
  /// - `prescriptionDate`: The date-time at which the medication was prescribed.
  /// - `isIndefinite`: Whether the medication is taken indefinitely.
  /// - `durationUnits`: The units of the duration.
  /// - `durationLength`: The length of the duration.
  /// - `scheduleType`: The type of schedule.
  /// - `frequency`: The frequency of the medication.
  /// - `doseUnits`: The units of the dose.
  /// - `doseQuantity`: The quantity of the dose.
  /// - `applicationSite`: The site of application.
  /// - `notes`: Additional notes about the medication.
  /// 
  /// Returns:
  /// - A `Map<String, dynamic>` containing the user medication data.
  /// 
  /// Throws:
  /// - `FormatException` if the frequency is less than 1 or the dose quantity is negative.
  /// - `Exception` if any other error occurs during the creation of the medication data.
  Map<String, dynamic> createMedicationData({
    required String medicationName,
    required DateTime prescriptionDate,
    required bool isIndefinite,
    required String durationUnits,
    required String durationLength,
    required String scheduleType,
    required String frequency,
    required String doseUnits,
    required String doseQuantity,
    required String applicationSite,
    String? notes,
  }) {
    try {
      int parsedFrequency = int.tryParse(frequency) ?? 1;
      double parsedDoseQuantity = double.tryParse(doseQuantity) ?? 0.0;

      if (parsedFrequency < 1) {
        throw FormatException("Frequency must be at least 1.");
      }
      if (parsedDoseQuantity < 0.0) {
        throw FormatException("Dose quantity cannot be negative.");
      }

      return {
        "medType": "Eye Medication",
        "medicationName": medicationName,
        "prescriptionDate": prescriptionDate,
        "isIndefinite": isIndefinite,
        "durationUnits": isIndefinite ? null : durationUnits,
        "durationLength": isIndefinite ? null : durationLength,
        "scheduleType": scheduleType,
        "frequency": int.tryParse(frequency) ?? 1,
        "doseUnits": doseUnits,
        "doseQuantity": double.tryParse(doseQuantity) ?? 0.0,
        "applicationSite": applicationSite,
        "reminderSet": false,
        "notes": notes?.trim(),
      };
    } catch (e) {
      log("Error creating medication data: $e");
      throw Exception("Invalid medication data: ${e.toString()}");
    }
  }

  /// Checks if the user medication already exists in FireStore.
  ///  
  /// Parameters:
  /// - `userId`: The ID of the user.
  /// - `medData`: The medication data to check for duplication.
  /// 
  /// Returns:
  /// - `true` if the medication already exists in FireStore
  /// - `false` if the medication does not exist in FireStore.
  /// 
  /// Throws:
  /// - `Exception` if the user does not have permission to check for duplicates.
  /// - `Exception` if any other error occurs during the check for duplicates.
  Future<bool> isDuplicateMedication(String userId, Map<String, dynamic> medData) async {
    try {
      return await firestoreService.checkExactDuplicateDoc(
        collectionPath: "users/$userId/eye_medications", 
        data: medData
      );
    } on FirebaseException catch (e) {
      log("Firestore Error checking duplicate: ${e.message}");
      if (e.code == "permission-denied") {
        throw Exception("You do not have permission to check for duplicates.");
      }
      return false;
    } catch (e) {
      log("Unexpected error checking duplicate: $e");
      return false;
    }
  }

  /// Adds a new user medication to FireStore.
  /// 
  /// Parameters:
  /// - `userId`: The ID of the user.
  /// - `medData`: The medication data to add.
  /// 
  /// Throws:
  /// - `Exception` if the user does not have permission to add medications.
  /// - `Exception` if any other error occurs during the addition of the medication.
  Future<void> addMedication(String userId, Map<String, dynamic> medData) async {
    try {
      await firestoreService.addDoc(
        path: "users/$userId/eye_medications",
        data: medData,
      );

      log("Medication successfully added.");
    } on FirebaseException catch (e) {
      log("Firestore Error adding medication: ${e.message}");

      if (e.code == "permission-denied") {
        throw Exception("You do not have permission to add medications.");
      }

      throw Exception("Failed to add medication: ${e.message}");
    } on PlatformException catch (e) {
      log("Platform Error adding medication: ${e.message}");
      throw Exception("Platform error while adding medication. Try again.");
    } catch (e) {
      log("Unexpected error adding medication: $e");
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  /// Deletes a medication from Firestore along with any associated reminders.
  ///
  /// Parameters:
  /// - `medication`: A `Map<String, dynamic>` containing the details of the medication.
  ///   - Must contain a `"medType"` key to determine the collection path.
  ///   - Must contain an `"id"` key representing the document ID in Firestore.
  ///
  /// Behavior:
  /// - If the user is not authenticated, the function exits early.
  /// - If the medication does not contain a valid `"id"`, an error is logged and the function exits.
  /// - Deletes the medication document from Firestore.
  /// - Finds and deletes any associated reminders for this medication.
  /// - Logs any errors encountered during deletion and throws an exception.
  Future<void> deleteMedication(Map<String, dynamic> medication) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No authenticated user found");
      }

      String collectionPath = medication["medType"] == "Eye Medication"
          ? "users/${user.uid}/eye_medications"
          : "users/${user.uid}/noneye_medications";

      if (!medication.containsKey("id") || medication["id"] == null) {
        log("Error: Medication does not have an ID.");
        throw Exception("Medication does not have an ID");
      }

      // First, find any associated reminders
      final remindersToDelete = await _findAssociatedReminders(user.uid, medication["id"]);
      
      // Delete the medication document
      await firestoreService.deleteDoc(collectionPath: collectionPath, docId: medication["id"]);
      
      // Delete associated reminders
      if (remindersToDelete.isNotEmpty) {
        final progressService = ProgressService();
        
        for (var reminder in remindersToDelete) {
          // First delete the progress entries
          try {
            await progressService.deleteProgressEntriesForReminder(
              userId: user.uid,
              reminderId: reminder["id"],
            );
          } catch (e) {
            log("Warning: Error deleting progress entries for reminder ${reminder["id"]}: $e");
            // Continue with reminder deletion even if progress deletion fails
          }
          
          // Then delete the reminder document
          await firestoreService.deleteDoc(
            collectionPath: "users/${user.uid}/reminders", 
            docId: reminder["id"]
          );
        }
        log("Deleted ${remindersToDelete.length} associated reminder(s) and their progress history");
      }
      
      log("Medication deleted successfully");
    } on FirebaseException catch (e) {
      log("Firestore error deleting medication: ${e.message}");
      throw Exception("Failed to delete medication: ${e.message}");
    } catch (e) {
      log("Error deleting medication: $e");
      throw Exception("Error deleting medication: $e");
    }
  }

  /// Finds reminders associated with a specific medication
  ///
  /// Parameters:
  /// - `userId`: User ID to search within
  /// - `medicationId`: ID of the medication to find reminders for
  ///
  /// Returns a list of reminder documents that are associated with the given medication
  /// Each document will include its Firestore ID in the "id" field
  Future<List<Map<String, dynamic>>> _findAssociatedReminders(String userId, String medicationId) async {
    try {
      // Use the queryCollectionWithIds method instead which adds document IDs
      final results = await firestoreService.queryCollectionWithIds(
        collectionPath: "users/$userId/reminders",
        filters: [
          {"field": "userMedicationId", "operator": "==", "value": medicationId}
        ],
      );
      
      log("Found ${results.length} reminders associated with medication $medicationId");
      return results;
    } catch (e) {
      log("Error finding associated reminders: $e");
      // Return empty list but don't fail the whole operation
      return [];
    }
  }

  
  /// Creates a stream that combines both eye and non-eye medication data.
  ///
  /// This method listens to Firestore collections for the logged-in user and 
  /// merges the streams of eye medications and non-eye medications into a single stream.
  /// Each medication document will include its document ID in an "id" field.
  Stream<List<Map<String, dynamic>>> buildMedicationsStream(FirestoreService firestoreService, String userId) {
    return firestoreService.getCollectionStreamWithIds("users/$userId/eye_medications");
  }

  /// Gets all medications for a user
  Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    try {
      return await firestoreService.getAllDocsWithIds(
        collectionPath: "users/$userId/eye_medications"
      );
    } catch (e) {
      log("Error getting medications: $e");
      return [];
    }
  }

}
