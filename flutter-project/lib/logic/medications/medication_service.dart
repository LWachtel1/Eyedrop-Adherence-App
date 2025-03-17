import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:flutter/services.dart';



/// Service class for handling user medication-related operations relevant for FireStore.
/// 
/// Operations:
/// - creates a map storing user medication data (to be passed to a Firestore document).
/// - checks if a user medication already exists in Firestore.
/// - adds a new user medication to Firestore.
class MedicationService {
  final FirestoreService firestoreService;

  MedicationService(this.firestoreService);

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
}
