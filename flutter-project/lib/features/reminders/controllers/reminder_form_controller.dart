import 'dart:developer';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Controller for the reminder form
/// 
/// Manages form state and business logic for creating reminders
class ReminderFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ReminderService reminderService;

  // Selected medication data.
  Map<String, dynamic>? selectedMedication;
  String userMedicationId = '';
  String medicationType = '';
  String medicationName = '';

  // Form state variables.
  DateTime? startDate;
  TimeOfDay? startTime;
  bool isIndefinite = false;
  String _durationUnit = '';
  bool smartScheduling = true;
  List<TimeOfDay> timings = [];

  // Additional medication details from the selected medication
  String scheduleType = '';
  int frequency = 1;
  String doseUnits = '';
  double doseQuantity = 0.0;
  String applicationSite = '';

  // Controllers for text input fields.
  final TextEditingController durationController = TextEditingController(text: '1');
  
  ReminderFormController({required this.reminderService});

  /// Getter for duration units.
  String get durationUnit => _durationUnit;

  /// Setter for duration units.
  set durationUnit(String value) {
    _durationUnit = value;
    notifyListeners();
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  /// Sets the selected medication from the medication selection screen.
  void setSelectedMedication(Map<String, dynamic> medication) {
    selectedMedication = medication;
    userMedicationId = medication['id'] ?? '';
    medicationType = medication['medType'] ?? '';
    medicationName = medication['medicationName'] ?? '';
    
    // Extract medication details needed for reminder
    scheduleType = medication['scheduleType'] ?? 'daily';
    frequency = medication['frequency'] is int ? 
        medication['frequency'] : 
        int.tryParse(medication['frequency']?.toString() ?? '1') ?? 1;
    doseUnits = medication['doseUnits'] ?? '';
    doseQuantity = medication['doseQuantity'] is double ? 
        medication['doseQuantity'] : 
        double.tryParse(medication['doseQuantity']?.toString() ?? '0.0') ?? 0.0;
    applicationSite = medication['applicationSite'] ?? '';
    
    // If prescription date exists in medication, default start date to that.
    if (medication.containsKey('prescriptionDate')) {
      final prescriptionDate = medication['prescriptionDate'];
      if (prescriptionDate is DateTime) {
        startDate = prescriptionDate;
      } else if (prescriptionDate != null) {
        // Handle Firestore timestamp.
        try {
          startDate = prescriptionDate.toDate();
        } catch (e) {
          log("Error converting prescription date: $e");
          startDate = DateTime.now();
        }
      } else {
        startDate = DateTime.now();
      }
      startTime = TimeOfDay.fromDateTime(startDate!);
    } else {
      startDate = DateTime.now();
      startTime = TimeOfDay.now();
    }
    
    // Default the duration to match the medication if available.
    if (medication.containsKey('isIndefinite')) {
      isIndefinite = medication['isIndefinite'] == true;
    }
    
    if (!isIndefinite && medication.containsKey('durationUnits')) {
      _durationUnit = medication['durationUnits'] ?? '';
    }
    
    if (!isIndefinite && medication.containsKey('durationLength')) {
      final durationLength = medication['durationLength'];
      if (durationLength != null) {
        durationController.text = durationLength.toString();
      }
    }
    
    notifyListeners();
  }

  /// Toggles whether the reminder duration is indefinite.
  void toggleIndefinite(bool value) {
    isIndefinite = value;
    if (isIndefinite) {
      durationUnit = '';
      durationController.text = '';
    } else if (durationController.text.isEmpty) {
      durationController.text = '1';
      if (durationUnit.isEmpty && selectedMedication != null) {
        durationUnit = selectedMedication!['durationUnits'] ?? 'Days';
      } else if (durationUnit.isEmpty) {
        durationUnit = 'Days';
      }
    }
    notifyListeners();
  }

  /// Opens a date picker for selecting the start date.
  Future<void> selectStartDate(BuildContext context) async {
    try {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: startDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        startDate = pickedDate;
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Failed to select date.");
      }
      log("Error selecting date: $e");
    }
  }

  /// Opens a time picker for selecting the start time.
  Future<void> selectStartTime(BuildContext context) async {
    try {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: startTime ?? TimeOfDay.now(),
      );

      if (pickedTime != null) {
        startTime = pickedTime;
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Failed to select time.");
      }
      log("Error selecting time: $e");
    }
  }

  /// Combines the selected date and time into a single DateTime object.
  DateTime getFinalStartDateTime() {
    return DateTime(
      startDate?.year ?? DateTime.now().year,
      startDate?.month ?? DateTime.now().month,
      startDate?.day ?? DateTime.now().day,
      startTime?.hour ?? 0,
      startTime?.minute ?? 0,
    );
  }

  /// Toggles the smart scheduling option.
  void toggleSmartScheduling(bool value) {
    smartScheduling = value;
    notifyListeners();
  }

  /// Adds a timing to the list.
  void addTiming(TimeOfDay timing) {
    timings.add(timing);
    notifyListeners();
  }

  /// Removes a timing from the list.
  void removeTiming(int index) {
    if (index >= 0 && index < timings.length) {
      timings.removeAt(index);
      notifyListeners();
    }
  }

  /// Selects a specific timing.
  Future<void> selectTiming(BuildContext context, int index) async {
    try {
      TimeOfDay initialTime = index < timings.length 
          ? timings[index] 
          : TimeOfDay.now();
          
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        if (index < timings.length) {
          timings[index] = pickedTime;
        } else {
          timings.add(pickedTime);
        }
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Failed to select time.");
      }
      log("Error selecting time: $e");
    }
  }

  /// Increments the duration length.
  void incrementDurationLength() {
    int currentValue = int.tryParse(durationController.text) ?? 1;
    currentValue++;
    durationController.text = '$currentValue';
    notifyListeners();
  }

  /// Decrements the duration length.
  void decrementDurationLength() {
    int currentValue = int.tryParse(durationController.text) ?? 1;
    if (currentValue > 1) {
      currentValue--;
      durationController.text = '$currentValue';
      notifyListeners();
    }
  }

  /// Resets the form to default values.
  void resetForm() {
    selectedMedication = null;
    userMedicationId = '';
    medicationType = '';
    medicationName = '';
    startDate = null;
    startTime = null;
    isIndefinite = false;
    _durationUnit = '';
    smartScheduling = true;
    timings.clear();
    durationController.text = '1';
    notifyListeners();
  }

  /// Gets the required number of timings based on medication schedule.
  int getRequiredTimingsCount() {
    if (selectedMedication == null) return 0;
    
    final scheduleType = selectedMedication!['scheduleType'] ?? 'daily';
    final frequency = selectedMedication!['frequency'] ?? 1;
    
    if (scheduleType == 'daily') {
      return frequency is int ? frequency : int.tryParse(frequency.toString()) ?? 1;
    } else if (scheduleType == 'weekly') {
      return frequency is int ? frequency : int.tryParse(frequency.toString()) ?? 1;
    } else {
      return 1; // Default for other schedule types
    }
  }

  /// Validates the form and submits it.
  Future<void> submitForm(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    
    if (selectedMedication == null) {
      _showErrorSnackBar(context, "Please select a medication");
      return;
    }

    if (!smartScheduling && timings.isEmpty) {
      _showErrorSnackBar(context, "Please add at least one timing");
      return;
    }

    if (!smartScheduling) {
      final requiredCount = getRequiredTimingsCount();
      if (timings.length != requiredCount) {
        _showErrorSnackBar(context, "Please add exactly $requiredCount timings for this medication schedule");
        return;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar(context, "Authentication error. Please log in.");
        return;
      }

      final reminderData = reminderService.createReminderData(
        userMedicationId: userMedicationId,
        medicationType: medicationType,
        medicationName: medicationName,
        startDate: getFinalStartDateTime(),
        isIndefinite: isIndefinite,
        durationUnits: isIndefinite ? null : durationUnit,
        durationLength: isIndefinite ? null : durationController.text,
        smartScheduling: smartScheduling,
        timings: smartScheduling ? null : timings,
        // Pass the additional medication details
        scheduleType: scheduleType,
        frequency: frequency,
        doseUnits: doseUnits,
        doseQuantity: doseQuantity,
        applicationSite: applicationSite,
        isEnabled: true, // New reminders are enabled by default
      );

      // Checks if reminder already exists for this medication.
      final isDuplicate = await reminderService.isDuplicateReminder(user.uid, userMedicationId);

      if (isDuplicate) {
        if (context.mounted) {
          _showErrorSnackBar(context, "A reminder for this medication already exists");
        }
      } else {
        await reminderService.addReminder(user.uid, reminderData);
        resetForm();
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Reminder created successfully")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Failed to create reminder: ${e.toString()}");
      }
      log("Error submitting reminder: $e");
    }
  }

  /// Display error message.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}