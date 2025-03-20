import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:eyedrop/features/medications/screens/medication_selection_screen.dart';
import 'package:eyedrop/shared/widgets/form_components.dart'; // Add this import

/// A helper class that provides reusable UI components for displaying and editing medication details.
class MedicationDetailsFields {

  /// Builds an editable text field or a read-only detail row.
  ///
  /// If `isEditing` is true, it displays a text input field. Otherwise, it shows a non-editable text field.
  /// If `allowSelection` is enabled and `medType` is "Eye Medication", an icon appears for selecting medication from Firestore.
  static Widget buildEditableField({
    required String label,
    required String fieldKey,
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required Function(String, dynamic) onValueChanged,
    bool isNumeric = false,
    bool allowSelection = false,
    BuildContext? context,
  }) {
    TextEditingController controller = TextEditingController(
      text: medicationData[fieldKey]?.toString() ?? ''
    );

    // Use FormComponents for text field
    return isEditing
      ? FormComponents.buildTextField(
          label: label,
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          icon: allowSelection && medicationData["medType"] == "Eye Medication" && context != null 
                ? Icons.search
                : null,
          onTapIcon: allowSelection && medicationData["medType"] == "Eye Medication" && context != null
                ? () => _selectMedicationFromFirestore(
                    context, fieldKey, controller, medicationData, onValueChanged
                  )
                : null,
          inputFormatters: isNumeric 
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : null,
        )
      : buildDetailRow(label, medicationData[fieldKey]?.toString());
  }

  /// Builds a dropdown selection field.
  ///
  /// If `isEditing` is true, displays a dropdown menu. Otherwise, shows a read-only text row with the selected value.
  static Widget buildDropdownField({
    required String label,
    required String fieldKey,
    required List<String> options,
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required Function(String, dynamic) onValueChanged,
  }) {
    String? currentValue = medicationData[fieldKey];
    
    // Ensure value is in the options list to avoid dropdown errors.
    if (currentValue != null && !options.contains(currentValue)) {
      currentValue = options.isNotEmpty ? options[0] : null;
    }
    
    return isEditing
      ? FormComponents.buildDropdown(
          label: label,
          value: currentValue,
          items: options,
          onChanged: (value) {
            if (value != null) {
              onValueChanged(fieldKey, value);
            }
          },
        )
      : buildDetailRow(label, medicationData[fieldKey]?.toString());
  }

  /// Builds a date picker field.
  ///
  /// If `isEditing` is enabled, allows selecting a date. Otherwise, it displays the formatted date as read-only text.
  static Widget buildDatePicker({
    required String label,
    required String fieldKey,
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required BuildContext context,
    required Function(String, dynamic) onValueChanged,
  }) {
    // Convert the Firestore Timestamp to DateTime for the FormComponents
    DateTime? dateTime = medicationData[fieldKey] != null 
                        ? _extractDateTime(medicationData[fieldKey])
                        : null;
                        
    return isEditing
      ? FormComponents.buildDateField(
          label: label,
          value: dateTime,
          onTap: () => _selectDate(
            context, fieldKey, medicationData, onValueChanged
          ),
        )
      : buildDetailRow(label, _formatDateOnly(medicationData[fieldKey]));
  }

  /// Builds a time picker field
  /// 
  /// If `isEditing` is enabled, allows selecting a time. Otherwise, it displays the formatted time as read-only text.
  static Widget buildTimePicker({
    required String label,
    required String fieldKey,
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required BuildContext context,
    required Function(String, dynamic) onValueChanged,
  }) {
    // Convert the Firestore Timestamp to TimeOfDay
    DateTime? dateTime = medicationData[fieldKey] != null 
                      ? _extractDateTime(medicationData[fieldKey])
                      : null;
                      
    TimeOfDay? timeOfDay = dateTime != null 
                         ? TimeOfDay(hour: dateTime.hour, minute: dateTime.minute)
                         : null;
                         
    return isEditing
      ? FormComponents.buildTimeField(
          label: label,
          value: timeOfDay,
          onTap: () => _selectTime(
            context, fieldKey, medicationData, onValueChanged
          ),
        )
      : buildDetailRow(label, _formatTime(medicationData[fieldKey]));
  }

  /// Builds a checkbox field for selecting boolean values.
  ///
  /// If `isEditing` is enabled, displays a toggleable checkbox.
  static Widget buildCheckbox({
    required String label,
    required String fieldKey,
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required Function(String, dynamic) onValueChanged,
  }) {
    bool value = medicationData[fieldKey] == true;
    
    return isEditing
      ? FormComponents.buildCheckbox(
          label: label,
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onValueChanged(fieldKey, newValue);
            }
          },
        )
      : buildDetailRow(label, value ? "Yes" : "No");
  }

  /// Toggle buttons for medication type.   
  /// 
  /// If `isEditing` is enabled, displays a row of toggle buttons. Otherwise, it shows the selected value as read-only text.
  static Widget buildToggleButtons({
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required Function(String, dynamic) onValueChanged,
    required List<String> options,
    required String fieldKey,
  }) {
    if (!isEditing) {
      return buildDetailRow("Type", medicationData[fieldKey]?.toString());
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Medication Type",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17.5.sp,
              color: Colors.grey[700]
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: options.map((option) {
              bool isSelected = medicationData[fieldKey] == option;
              
              return FormComponents.buildToggleButton(
                label: option,
                isSelected: isSelected,
                onTap: () => onValueChanged(fieldKey, option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds a numeric stepper for adjusting numerical values.
  ///
  /// If `isEditing` is true, allows increasing or decreasing values.
  /// Otherwise, displays the numeric value in a read-only format.
  /// Error handling:
  /// - Handles null or empty values by using the provided `minValue`
  /// - Prevents values below `minValue`
  /// - Gracefully handles parsing errors for non-numeric input
  static Widget buildNumericStepperField({
    required String label,
    required String fieldKey,
    required Map<String, dynamic> medicationData,
    required bool isEditing,
    required Function(String, dynamic) onValueChanged,
    double minValue = 1.0,
    double step = 1.0,
    bool allowDecimals = false,
  }) {
      try{
        // Handles null or empty values safely.
        String initialValue = "";
        var fieldValue = medicationData[fieldKey];
        
        if (fieldValue == null || fieldValue.toString().isEmpty) {
          initialValue = minValue.toString();
        } else {
          // Ensures we have a string representation.
          initialValue = fieldValue.toString();
        }
        
        TextEditingController controller = TextEditingController(text: initialValue);
        Timer? debounceTimer;

        return isEditing
          ? FormComponents.buildNumericStepperField(
              label: label,
              controller: controller,
              isEnabled: isEditing,
              onChanged: (value) {
                
                // Only validate completed inputs, otherwise let user continue typing
                // Use a debounce mechanism to delay validation until the user stops typing 
                // (prevents validation on every keystroke - which forces user to click repeatedly to use it)
                debounceTimer = Timer(Duration(milliseconds: 1000), () {
                  if (value.isEmpty) {
                    onValueChanged(fieldKey, "");
                    return;
                  }

                  // Check if it's a partial decimal entry (e.g., "0.")
                  if (allowDecimals && (value == "." || value.endsWith("."))) {
                    onValueChanged(fieldKey, value);
                    return;
                  }

                  // For completed values, perform validation
                  try {
                    double? parsedValue = double.tryParse(value);
                    if (parsedValue != null && parsedValue >= minValue) {
                      // Valid complete value
                      onValueChanged(fieldKey, value);
                    }
                  } catch (e) {
                    print("Error processing numeric value: $e");
                  }
                });
              },
              onIncrement: () {
                double currentValue = double.tryParse(controller.text) ?? minValue;
                // Use the provided step value (for dose quantity, this should be 0.1)
                currentValue += step;
                
                // Format with correct decimal places based on the step value
                String formattedValue;
                if (allowDecimals) {
                  // Determine number of decimal places based on step
                  int decimalPlaces = step.toString().split('.')[1].length;
                  formattedValue = currentValue.toStringAsFixed(decimalPlaces);
                } else {
                  formattedValue = currentValue.toStringAsFixed(0);
                }
                
                controller.text = formattedValue;
                onValueChanged(fieldKey, controller.text);
              },
              onDecrement: () {
                double currentValue = double.tryParse(controller.text) ?? minValue;
                if (currentValue > minValue) {
                  currentValue -= step;
                  controller.text = allowDecimals 
                                ? currentValue.toStringAsFixed(1) 
                                : currentValue.toStringAsFixed(0);
                  // Ensures we store values as strings.
                  onValueChanged(fieldKey, controller.text);
                }
              },
              step: step,
              minValue: minValue,
              allowDecimals: allowDecimals,
            )
          : buildDetailRow(label, medicationData[fieldKey]?.toString());
      } catch (e) {
        print("Error building numeric stepper field: $e");
        // Return a fallback widget that won't crash the UI
        return Text("Error displaying field: $label", 
                    style: TextStyle(color: Colors.red));
      }
    }

  /// Builds a read-only detail row for displaying values in non-edit mode.
  static Widget buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17.5.sp,
              color: Colors.grey[700]
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value ?? "N/A",
            style: TextStyle(fontSize: 17.5.sp),
          ),
        ],
      ),
    );
  }
  
  // Helper methods for date/time handling.

  /// Converts Firestore Timestamp to DateTime.
  static DateTime _extractDateTime(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    return DateTime.now();
  }
  
  /// Formats date as `dd-MM-yyyy`.
  static String _formatDateOnly(dynamic date) {
    if (date == null) return "N/A";
    try {
      return DateFormat('dd-MM-yyyy').format(_extractDateTime(date));
    } catch (e) {
      print("Error formatting date: $e for value: $date (${date.runtimeType})");
      return "Date Error";
    }
  }
  
  static String _formatTime(dynamic date) {
    if (date == null) return "N/A";
    try {
      return DateFormat('HH:mm').format(_extractDateTime(date));
    } catch (e) {
      print("Error formatting time: $e for value: $date (${date.runtimeType})");
      return "Time Error";
    }
  }
  
  /// Allows selecting a medication from Firestore.
  static Future<void> _selectMedicationFromFirestore(
    BuildContext context,
    String fieldKey,
    TextEditingController controller,
    Map<String, dynamic> medicationData,
    Function(String, dynamic) onValueChanged,
  ) async {
    try {
      final selectedMedication = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MedicationSelectionScreen()),
      );

      if (selectedMedication != null) {
        controller.text = selectedMedication;
        onValueChanged(fieldKey, selectedMedication);
      }
    } catch (e) {
      print("Error selecting medication: $e");
      // Show an error dialog/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select medication. Please try again.")),
      );
    }
  }
  
  static Future<void> _selectDate(
    BuildContext context,
    String fieldKey,
    Map<String, dynamic> medicationData,
    Function(String, dynamic) onValueChanged,
  ) async {
    DateTime originalDateTime = _extractDateTime(medicationData[fieldKey] ?? DateTime.now());
    
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: originalDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      // Retain existing time
      DateTime updatedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        originalDateTime.hour,
        originalDateTime.minute,
      );
      
      onValueChanged(fieldKey, Timestamp.fromDate(updatedDateTime));
    }
  }
  
  static Future<void> _selectTime(
    BuildContext context,
    String fieldKey,
    Map<String, dynamic> medicationData,
    Function(String, dynamic) onValueChanged,
  ) async {
    DateTime originalDateTime = _extractDateTime(medicationData[fieldKey] ?? DateTime.now());
    
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: originalDateTime.hour, minute: originalDateTime.minute),
    );
    
    if (pickedTime != null) {
      // Create updated DateTime with new time
      DateTime updatedDateTime = DateTime(
        originalDateTime.year,
        originalDateTime.month,
        originalDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      
      onValueChanged(fieldKey, Timestamp.fromDate(updatedDateTime));
    }
  }
}