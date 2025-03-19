import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
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
  /// - `medType`: The type of medication; either "Eye Medication" or "Non-Eye Medication".
  /// - `medicationName`: The name of the medication.
  /// - `prescriptionDate`: The date-time at which the medication was prescribed.
  /// - `isIndefinite`: Whether the medication is taken indefinitely.
  /// - `durationUnits`: The units of the duration.
  /// - `durationLength`: The length of the duration.
  /// - `scheduleType`: The type of schedule.
  /// - `frequency`: The frequency of the medication.
  /// - `doseUnits`: The units of the dose.
  /// - `doseQuantity`: The quantity of the dose.
  /// - `applicationSite`: The site of application (for eye medications).
  /// 
  /// Returns:
  /// - A `Map<String, dynamic>` containing the user medication data.
  /// 
  /// Throws:
  /// - `FormatException` if the frequency is less than 1 or the dose quantity is negative.
  /// - `Exception` if any other error occurs during the creation of the medication data.
  Map<String, dynamic> createMedicationData({
    required String medType,
    required String medicationName,
    required DateTime prescriptionDate,
    required bool isIndefinite,
    required String durationUnits,
    required String durationLength,
    required String scheduleType,
    required String frequency,
    required String doseUnits,
    required String doseQuantity,
    required String applicationSite
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

      if(medType == "Eye Medication" && applicationSite.isNotEmpty) {
        return {
          "medType": medType,
          //"isEyeMedication": true,
          "medicationName": medicationName,
          "prescriptionDate": prescriptionDate,
          "isIndefinite": isIndefinite,
          "durationUnits": isIndefinite ? null : durationUnits,
          "durationLength": isIndefinite ? null : durationLength,
          "scheduleType": scheduleType,
          "frequency": int.tryParse(frequency) ?? 1,
          "doseUnits": doseUnits,
          "doseQuantity": double.tryParse(doseQuantity) ?? 0.0,
          "applicationSite": applicationSite
        };
      } else {
        return {
          "medType": medType,
          "medicationName": medicationName,
          //"isEyeMedication": false,
          "prescriptionDate": prescriptionDate,
          "isIndefinite": isIndefinite,
          "durationUnits": isIndefinite ? null : durationUnits,
          "durationLength": isIndefinite ? null : durationLength,
          "scheduleType": scheduleType,
          "frequency": int.tryParse(frequency) ?? 1,
          "doseUnits": doseUnits,
          "doseQuantity": double.tryParse(doseQuantity) ?? 0.0,
        };
      }
    } catch (e) {
      log("Error creating medication data: $e");
      throw Exception("Invalid medication data: ${e.toString()}");
    }

  }

  /// Checks if the user medication already exists in FireStore.
  ///  
  /// 
  /// Parameters:
  /// - `userId`: The ID of the user.
  /// - `medData`: The medication data to check for duplication.
  /// - `isEyeMedication`: Whether the medication is an eye medication.
  /// 
  /// Returns:
  /// - `true` if the medication already exists in FireStore
  /// - `false` if the medication does not exist in FireStore.
  /// 
  /// 
  /// Throws:
  /// - `Exception` if the user does not have permission to check for duplicates.
  /// - `Exception` if any other error occurs during the check for duplicates.
  Future<bool> isDuplicateMedication(String userId, Map<String, dynamic> medData , 
    bool isEyeMedication) async {
    try {
      
      bool isDuplicate = false;
      if(isEyeMedication) {
          isDuplicate  = await firestoreService.checkExactDuplicateDoc(collectionPath: "users/$userId/eye_medications", data: medData);

      } else {
        isDuplicate  = await firestoreService.checkExactDuplicateDoc(collectionPath: "users/$userId/noneye_medications", data: medData);

      }

      return isDuplicate;


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
  /// - `isEyeMedication`: Whether the medication is an eye medication.
  /// 
  /// Throws:
  /// - `Exception` if the user does not have permission to add medications.
  /// - `Exception` if any other error occurs during the addition of the medication.
  Future<void> addMedication(String userId, Map<String, dynamic> medData, bool isEyeMedication) async {
    try {
      if (isEyeMedication) {
                await firestoreService.addDoc(
            path: "users/$userId/eye_medications",
            data: medData,
          );

      } else {
            await firestoreService.addDoc(
            path: "users/$userId/noneye_medications",
            data: medData,
          );
      }

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


  /// Deletes a medication from Firestore.
  ///
  /// Parameters:
  /// - `medication`: A `Map<String, dynamic>` containing the details of the medication.
  ///   - Must contain a `"medType"` key to determine the collection path.
  ///   - Must contain an `"id"` key representing the document ID in Firestore.
  ///
  /// Behavior:
  /// - If the user is not authenticated (`FirebaseAuth.instance.currentUser` returns `null`), 
  ///   the function exits early.
  /// - If the medication does not contain a valid `"id"`, an error is logged, and the function exits.
  /// - Deletes the document from Firestore using the `FirestoreService.deleteDoc` method.
  /// - Logs any errors encountered during deletion and throws an exception.
  Future<void> deleteMedication(Map<String, dynamic> medication) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String collectionPath = medication["medType"] == "Eye Medication"
          ? "users/${user.uid}/eye_medications"
          : "users/${user.uid}/noneye_medications";

      if (!medication.containsKey("id") || medication["id"] == null) {
        log("Error: Medication does not have an ID.");
        return;
      }

      await firestoreService.deleteDoc(collectionPath: collectionPath, docId: medication["id"]);
    } catch (e) {
      log("Error deleting medication: $e");
      throw Exception("Error deleting medication");
    }
  }

  
  /// Creates a stream that combines both eye and non-eye medication data.
  ///
  /// This method listens to Firestore collections for the logged-in user and 
  /// merges the streams of eye medications and non-eye medications into a single stream.
  /// Each medication document will include its document ID in an "id" field.
  Stream<List<Map<String, dynamic>>> buildMedicationsStream(FirestoreService firestoreService, String userId) {
    // Get streams with document IDs included
    Stream<List<Map<String, dynamic>>> eyeStream = 
        firestoreService.getCollectionStreamWithIds("users/$userId/eye_medications");
    Stream<List<Map<String, dynamic>>> nonEyeStream = 
        firestoreService.getCollectionStreamWithIds("users/$userId/noneye_medications");
        
    return _combineStreams(eyeStream, nonEyeStream);
  }
  
  /// Combines two medication data streams into a single stream.
  ///
  /// This method merges two Firestore collection streams (`stream1` and `stream2`) into 
  /// a single real-time stream using RxDart's `combineLatest2`. It ensures that the UI 
  /// always has the latest medication data from both collections.
  ///
  /// Parameters:
  /// - `stream1`: A `Stream<List<Map<String, dynamic>>>` representing the first collection (e.g., eye medications).
  /// - `stream2`: A `Stream<List<Map<String, dynamic>>>` representing the second collection (e.g., non-eye medications).
  ///
  /// Behavior:
  /// - Whenever either of the two streams emits new data, `combineLatest2` merges their latest values.
  /// - The result is a combined list of medications from both collections.
  ///
  /// Returns:
  /// - A `Stream<List<Map<String, dynamic>>>` containing the merged medication list.
  Stream<List<Map<String, dynamic>>> _combineStreams(
      Stream<List<Map<String, dynamic>>> stream1, 
      Stream<List<Map<String, dynamic>>> stream2) {
    return Rx.combineLatest2(
      stream1, 
      stream2,
      (List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
        return [...list1, ...list2];
      }
    );
  }

}
