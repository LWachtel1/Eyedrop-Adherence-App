import 'dart:developer';
import 'package:eyedrop/features/medications/screens/medication_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eyedrop/features/medications/controllers/medication_service.dart';

/// Manages form logic for adding a new medication.
///
/// Responsibilities:
/// - Handles input validation.
/// - Manages state for form fields.
/// - Handles date/time selection.
/// - Supports increment/decrement functionality for numeric fields.
/// - Ensures no duplicate medications are added.
/// - Submits valid medication data to Firestore.
class MedicationFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final MedicationService medicationService;

  MedicationFormController({required this.medicationService});

  // Form state variables (store the state of the form).
  String medType = '';
  DateTime? prescriptionDate;
  TimeOfDay? prescriptionTime;
  bool isIndefinite = false;
  String _durationUnit = '';
  String scheduleType = '';
  String doseUnits = '';
  String applicationSite = "";


  // Controllers for text input fields within form.
  final TextEditingController medicationController = TextEditingController();
  final TextEditingController durationController = TextEditingController(text: '1');
  final TextEditingController frequencyController = TextEditingController(text: '1');
  final TextEditingController doseQuantityController = TextEditingController(text: '0.0');

  @override
  /// Disposes of the controllers when the form is no longer in use.
  void dispose() {
    medicationController.dispose();
    durationController.dispose();
    frequencyController.dispose();
    doseQuantityController.dispose();
    super.dispose();
  }

  /// Getter for duration units.
  String get durationUnit => _durationUnit;

  /// Setter for duration units (ensures state update).
  set durationUnit(String value) {
    _durationUnit = value;
    notifyListeners();
  }

  /// Opens a selection screen for common eye medications.
  ///
  /// - Only applicable if the medication type is "Eye Medication".
  /// - Updates the medication name field when a selection is made.
  Future<void> selectMedicationFromFirestore(BuildContext context) async {
    if (medType == "Eye Medication") {
      try {
        final selectedMedication = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MedicationSelectionScreen()),
        );

        if (selectedMedication != null) {
          medicationController.text = selectedMedication as String;
          notifyListeners();
        }
      } catch (e) {
          if(context.mounted) {
            _showErrorSnackBar(context, "Failed to select medication.");
          }
          log("Error selecting medication: $e");
      }
    }
  }


  

  /// Opens a date picker for selecting the prescription date.
  ///
  /// - Ensures the date is between the year 2000 and 2100.
  /// - Updates the `prescriptionDate` field upon selection.
  Future<void> selectPrescriptionDate(BuildContext context) async {
    try {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        prescriptionDate = pickedDate;
        notifyListeners();
      }
    } catch (e) {

      if (context.mounted) {
        _showErrorSnackBar(context, "Failed to select date.");
      }

      log("Error selecting date: $e");
    }
  }

  /// Opens a time picker for selecting the prescription time.
  ///
  /// - If no time is selected, the default is midnight (00:00).
  Future<void> selectPrescriptionTime(BuildContext context) async {
    try {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: prescriptionTime ?? TimeOfDay.now(),
      );

      if (pickedTime != null) {
        prescriptionTime = pickedTime;
        notifyListeners();
      }
    }  catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, "Failed to select time.");
        }
        log("Error selecting time: $e");
    }
  }

  /// Toggles whether the medication duration is indefinite.
  ///
  /// - If `isIndefinite` is true, the duration fields are cleared.
  void toggleIndefinite(bool value) {
    isIndefinite = value;
    if (isIndefinite) {
      durationUnit = ''; // Clears duration units and duration length if medication is taken indefinitely.
      durationController.text = '';
    }
    notifyListeners();
  }

  /// Sets the selected schedule type.
  void setScheduleType(String? value) {
    if (value != null) {
      scheduleType = value;
      notifyListeners();
    }
  }

  /// Sets the selected dose unit.
  void setDoseUnits(String? value) {
    if (value != null) {
      doseUnits = value;
      notifyListeners();
    }
  }

  /// Combines the selected date and time into a single `DateTime` object.
  ///
  /// - If no date is selected, defaults to today.
  /// - If no time is selected, defaults to midnight (00:00).
  DateTime getFinalPrescriptionDateTime() {
    return DateTime(
      prescriptionDate?.year ?? DateTime.now().year,
      prescriptionDate?.month ?? DateTime.now().month,
      prescriptionDate?.day ?? DateTime.now().day,
      prescriptionTime?.hour ?? 0,
      prescriptionTime?.minute ?? 0,
    );
  }

  /// Increments dose quantity by 0.1.
  void incrementDoseQuantity() {
    double currentValue = double.tryParse(doseQuantityController.text) ?? 0.0;
    currentValue += 0.1;
    doseQuantityController.text = currentValue.toStringAsFixed(1);
    notifyListeners();
  }

  ///  Decrements dose quantity by 0.1 (minimum 0.0).
  void decrementDoseQuantity() {
    double currentValue = double.tryParse(doseQuantityController.text) ?? 0.0;
    if (currentValue > 0.0) {
      currentValue -= 0.1;
      doseQuantityController.text = currentValue.toStringAsFixed(1);
      notifyListeners();
    }
  }

  /// Increments frequency by 1.
  void incrementFrequency() {
    int currentValue = int.tryParse(frequencyController.text) ?? 1;
    currentValue++;
    frequencyController.text = '$currentValue';
    notifyListeners();
  }

  /// Decrements frequency by 1 (minimum 1).  
  void decrementFrequency() {
    int currentValue = int.tryParse(frequencyController.text) ?? 1;
    if (currentValue > 1) {
      currentValue--;
      frequencyController.text = '$currentValue';
      notifyListeners();
    }
  }

  /// Increments duration length by 1.
  void incrementDurationLength() {
    int currentValue = int.tryParse(durationController.text) ?? 1;
    currentValue++;
    durationController.text = '$currentValue';
    notifyListeners();
  }

 /// Decrements duration length by 1 (minimum 1).
  void decrementDurationLength() {
    int currentValue = int.tryParse(durationController.text) ?? 1;
    if (currentValue > 1) {
      currentValue--;
      durationController.text = '$currentValue';
      notifyListeners();
    }
  }

  /// Resets all form fields to their default values
  void resetForm() {
    // Reset text controllers
    medicationController.text = '';
    durationController.text = '1';
    frequencyController.text = '1';
    doseQuantityController.text = '0.0';
    
    // Reset form state variables
    medType = '';
    prescriptionDate = null;
    prescriptionTime = null;
    isIndefinite = false;
    _durationUnit = '';
    scheduleType = '';
    doseUnits = '';
    applicationSite = '';
    
    notifyListeners();
  }


  /// Submits the form and saves the medication to FireStore.
  ///
  /// - Ensures required fields are filled before submission.
  /// - Prevents duplicate medications from being added.
  /// - Saves the medication in the correct FireStore subcollection.
  Future<void> submitForm(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar(context, "Authentication error. Please log in.");
        return;
      }

      final medData = medicationService.createMedicationData(
        medType: medType,
        medicationName: medicationController.text,
        prescriptionDate: getFinalPrescriptionDateTime(),
        isIndefinite: isIndefinite,
        durationUnits: isIndefinite ? "Indefinite" : durationUnit,
        durationLength: isIndefinite ? "Indefinite" : durationController.text,
        scheduleType: scheduleType,
        frequency: frequencyController.text,
        doseUnits: doseUnits,
        doseQuantity: doseQuantityController.text,
        applicationSite: applicationSite
      );

      final isDuplicate = await medicationService.isDuplicateMedication(user.uid, medData, medType == "Eye Medication");

      if (isDuplicate) {
        if(context.mounted) {
          _showErrorSnackBar(context, "This medication already exists.");
        }
      } else {


        await medicationService.addMedication(user.uid, medData, medType == "Eye Medication");
        resetForm();

        
        if (context.mounted){
          Navigator.pop(context);
        }
      }
    } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, "Unexpected error. Please try again.");
        }
        log("Error adding medication: $e");
    }
  }

  /// Displays an error snackbar.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

}
