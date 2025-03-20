import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Controller class responsible for business logic related to medication details.
///
/// This class separates UI from data operations and provides methods
/// for fetching, updating, and manipulating medication data.
class MedicationDetailsController {
  final FirestoreService _firestoreService;
  
  // State variables
  bool isEditing = false;
  bool isLoading = true;
  Map<String, dynamic> editableMedication = {};
  final Map<String, dynamic> originalMedication;
  
  MedicationDetailsController({
    required FirestoreService firestoreService,
    required this.originalMedication,
  }) : _firestoreService = firestoreService {
    // Initialize editable medication with a deep copy of original data
    editableMedication = Map<String, dynamic>.from(originalMedication);
  }
  
  /// Fetches the latest medication data from Firestore.
  Future<void> fetchMedicationData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      String collectionPath = originalMedication["medType"] == "Eye Medication"
          ? "users/$uid/eye_medications"
          : "users/$uid/noneye_medications";
      String docId = originalMedication["id"];
      // print(originalMedication["id"]);

      final fetchedData = await _firestoreService.readDoc(
        collectionPath: collectionPath, 
        docId: docId
      );

      if (fetchedData != null) {
        editableMedication = fetchedData;
        editableMedication["id"] = docId;
      }
      isLoading = false;
      
    } catch (e) {
      log("Error fetching medication: $e");
      isLoading = false;
      rethrow;
    }
  }
  
  /// Saves edited medication data back to Firestore.
  Future<void> saveEdits() async {
    // Prepare data before saving
    _prepareDataForSaving();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("No authenticated user found. Cannot edit medication.");
        throw Exception("No authenticated user found");
      }

      String uid = user.uid;
      String collectionPath = editableMedication["medType"] == "Eye Medication"
          ? "users/$uid/eye_medications"
          : "users/$uid/noneye_medications";
      String docId = editableMedication["id"];

      Map<String, dynamic> updatedData = Map.from(editableMedication);
      updatedData.remove("id"); // Remove the ID field before saving
      
      await _firestoreService.updateDoc(
        collectionPath: collectionPath,
        docId: docId,
        newData: updatedData,
      );

      isEditing = false; // Exit edit mode after saving
    } catch (e) {
      log("Error saving medication: $e");
      rethrow;
    }
  }
  
  /// Prepares the medication data before saving to Firestore.
  void _prepareDataForSaving() {
    // Create a copy of the data to manipulate
    Map<String, dynamic> preparedData = Map<String, dynamic>.from(editableMedication);
    // Ensure data types are correct - convert values that might be null
    try {
      // Handle indefinite duration
      if (preparedData["isIndefinite"] == true) {
        preparedData["durationLength"] = ""; // Force empty string for indefinite
        preparedData["durationUnits"] = ""; // Force empty string for indefinite
      } else {
        // For definite meds, ensure we have actual values, not nulls
        var durationLength = preparedData["durationLength"];
        if (durationLength == null) {
          preparedData["durationLength"] = "1";
        } else if (durationLength is int || durationLength is double) {
          preparedData["durationLength"] = durationLength.toString();
        }
        
        if (preparedData["durationUnits"] == null) {
          preparedData["durationUnits"] = "Days";
        }
      }
      
      // Handles frequency field - ensure it's properly formatted.
      var frequency = preparedData["frequency"];
      if (frequency == null) {
        preparedData["frequency"] = "1";
      } else if (frequency is int || frequency is double) {
        preparedData["frequency"] = frequency.toString();
      }
      
      // Handles doseQuantity field - ensure it's properly formatted.
      var doseQuantity = preparedData["doseQuantity"];
      if (doseQuantity == null) {
        preparedData["doseQuantity"] = "1";
      } else if (doseQuantity is int || doseQuantity is double) {
        preparedData["doseQuantity"] = doseQuantity.toString();
      }
      
      // Remove applicationSite if not an eye medication
      if (preparedData["medType"] != "Eye Medication") {
        preparedData.remove("applicationSite");
      } else if (!preparedData.containsKey("applicationSite") || 
                preparedData["applicationSite"] == null) {
        // Ensure applicationSite exists for eye medications
        preparedData["applicationSite"] = "Both";
      }
      
      // Updates the editable medication with the prepared data.
      editableMedication = preparedData;
    
    } catch (e) {
      print("Error preparing data for saving: $e");
      // Log detailed info about the problematic fields
      print("isIndefinite: ${preparedData["isIndefinite"]} (${preparedData["isIndefinite"]?.runtimeType})");
      print("durationLength: ${preparedData["durationLength"]} (${preparedData["durationLength"]?.runtimeType})");
      print("durationUnits: ${preparedData["durationUnits"]} (${preparedData["durationUnits"]?.runtimeType})");
      print("frequency: ${preparedData["frequency"]} (${preparedData["frequency"]?.runtimeType})");
      print("doseQuantity: ${preparedData["doseQuantity"]} (${preparedData["doseQuantity"]?.runtimeType})");
      rethrow;
    }
  }
  
  /// Updates medication type and handles related fields.
  void updateMedicationType(String type) {
    editableMedication["medType"] = type;
    
    if (type == "Eye Medication") {
      // Ensure applicationSite exists when selecting Eye Medication
      if (!editableMedication.containsKey("applicationSite")) {
        editableMedication["applicationSite"] = "Both";
      }
    } else {
      // Remove applicationSite when switching to Non-Eye Medication
      editableMedication.remove("applicationSite");
    }
  }
  
  /// Updates the indefinite duration flag and related fields.
void updateIndefiniteDuration(bool value) {
  editableMedication["isIndefinite"] = value;
  
  if (value) {
    // When switching to indefinite, set default values instead of null
    editableMedication["durationLength"] = ""; // Empty string instead of null
    editableMedication["durationUnits"] = ""; // Empty string instead of null
  } else {
    // When switching to definite, set default values if they don't exist
    if (editableMedication["durationLength"] == null || editableMedication["durationLength"] == "") {
      editableMedication["durationLength"] = "1";
    }
    if (editableMedication["durationUnits"] == null || editableMedication["durationUnits"] == "") {
      editableMedication["durationUnits"] = "Days";
    }
  }
}

  
 /// Updates a medication field with the given value.
void updateField(String fieldKey, dynamic value) {
  // Handle null values for string fields
  if (value == null && (fieldKey == "durationUnits" || fieldKey == "durationLength")) {
    editableMedication[fieldKey] = ""; // Use empty string instead of null
  } else {
    editableMedication[fieldKey] = value;
  }
}
  
  /// Cancels editing and reverts changes.
  void cancelEditing() {
    isEditing = false;
    // Reset to original data
    editableMedication = Map<String, dynamic>.from(originalMedication);
  }
  
  /// Updates the date component of a DateTime field.
  Future<DateTime?> updateDateField(BuildContext context, String fieldKey) async {
    DateTime originalDateTime = extractDateTime(editableMedication[fieldKey]);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: originalDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // Retain the existing time and update only the date
      DateTime updatedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        originalDateTime.hour,
        originalDateTime.minute,
      );

      // Store back as Firestore Timestamp
      editableMedication[fieldKey] = Timestamp.fromDate(updatedDateTime);
      return updatedDateTime;
    }
    return null;
  }
  
  /// Updates the time component of a DateTime field.
  Future<DateTime?> updateTimeField(BuildContext context, String fieldKey) async {
    DateTime originalDateTime = extractDateTime(editableMedication[fieldKey]);

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: originalDateTime.hour, minute: originalDateTime.minute),
    );

    if (pickedTime != null) {
      // Create a new DateTime with the updated time
      DateTime updatedDateTime = DateTime(
        originalDateTime.year,
        originalDateTime.month,
        originalDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Store back as Firestore Timestamp
      editableMedication[fieldKey] = Timestamp.fromDate(updatedDateTime);
      return updatedDateTime;
    }
    return null;
  }
  
  // NOT ACTUALLY USED!!!
  /// Validates a field value to ensure it's not empty and has correct format.
  String? validateField(String fieldKey, String? value, {bool isNumeric = false}) {
    if (value == null || value.isEmpty) return "This field cannot be empty";
    
    // Field-specific validation
  switch (fieldKey) {
    case "doseQuantity":
      double? numValue = double.tryParse(value);
      if (numValue == null) return "Please enter a valid number";
      if (numValue <= 0) return "Dose quantity must be greater than 0";
      break;
    
    case "frequency":
      double? numValue = double.tryParse(value);
      if (numValue == null) return "Please enter a valid number";
      if (numValue < 1) return "Frequency must be at least 1";
      break;
    
    case "durationLength":
      if (editableMedication["isIndefinite"] == true) return null; // Skip validation for indefinite meds
      double? numValue = double.tryParse(value);
      if (numValue == null) return "Please enter a valid number";
      if (numValue < 1) return "Duration must be at least 1";
      break;
  }
    return null;
  }
  
  /// Formats date-time values from Firestore for display.
  String formatDateTime(dynamic date) {
    if (date == null) return "N/A";

    // Extract DateTime from various possible types
    DateTime dateTime = extractDateTime(date);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }
  
  /// Formats only the date component from Firestore values.
  String formatDateOnly(dynamic date) {
    if (date == null) return "N/A";

    // Extract DateTime from various possible types
    DateTime dateTime = extractDateTime(date);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }
  
  /// Formats only the time component from Firestore values.
  String formatTimeOnly(dynamic date) {
    if (date == null) return "N/A";

    // Extract DateTime from various possible types
    DateTime dateTime = extractDateTime(date);
    return DateFormat('HH:mm').format(dateTime);
  }
  
  /// Extracts DateTime from a Firestore Timestamp or DateTime object.
  DateTime extractDateTime(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    return DateTime.now(); // Fallback in case of null or invalid type
  }
  
  /// Starts editing mode
  void startEditing() {
    isEditing = true;
  }

  /// Ensures dropdown values are valid by checking if the current value exists in the options list.
  /// If not, it sets the value to the first option in the list or null if the list is empty.
  String? ensureValidDropdownValue(String? currentValue, List<String> options) {
    if (currentValue == null || options.isEmpty) {
      return options.isNotEmpty ? options[0] : null;
    }
    
    // Check if current value exists in options
    if (!options.contains(currentValue)) {
      return options[0]; // Default to first option if current value is invalid
    }
    
    return currentValue; // Current value is valid
  }
}