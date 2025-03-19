import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:eyedrop/logic/medications/medication_details_controller.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:eyedrop/widgets/edit_action_buttons.dart';
import 'package:eyedrop/widgets/medication_details_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Screen for displaying and editing medication details.
/// 
/// - Supports viewing and inline editing of medication details.
/// - Retrieves data from Firestore and updates it upon saving.
/// - Uses `MedicationDetailsController` for business logic.
class MedicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> medication;

  const MedicationDetailScreen({required this.medication, super.key});

  @override
  _MedicationDetailScreenState createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  late MedicationDetailsController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _controller = MedicationDetailsController(
      firestoreService: firestoreService, 
      originalMedication: widget.medication
    );
    _loadData(); // Fetch individual medication's data from Firestore
  }

  /// Loads medication data from Firestore and updates the UI.
  Future<void> _loadData() async {
    try {
      await _controller.fetchMedicationData();
      // Update UI after data is loaded
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading medication data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load medication details. Please try again.")),
        );
      }
    }
  }

  /// Updates a field value in the controller and triggers UI update.
  void _updateFieldValue(String fieldKey, dynamic value) {
    setState(() {
      _controller.updateField(fieldKey, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEyeMedication = _controller.editableMedication["medType"] == "Eye Medication";
    bool isIndefinite = _controller.editableMedication["isIndefinite"] == true;

    if (_controller.isLoading) {
      return BaseLayoutScreen(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BaseLayoutScreen(
      child: Padding(
        padding: EdgeInsets.only(top: 2.h, left: 5.w, right: 5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Medication Details",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
            ),

            // Scrollable Form.
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rearranged fields in the requested order
                        
                        // 1. Medication Type.
                        _controller.isEditing
                          ? MedicationDetailsFields.buildToggleButtons(
                              medicationData: _controller.editableMedication,
                              isEditing: _controller.isEditing,
                              onValueChanged: (fieldKey, value) {
                                setState(() {
                                  _controller.updateMedicationType(value);
                                });
                              },
                              options: ["Eye Medication", "Non-Eye Medication"],
                              fieldKey: "medType",
                            )
                          : MedicationDetailsFields.buildDetailRow(
                              "Type",
                              _controller.editableMedication["medType"] == "Eye Medication"
                                ? "Eye Medication" 
                                : "Non-Eye Medication"
                            ),
                        
                        // 2. Medication Name.
                        MedicationDetailsFields.buildEditableField(
                          label: "Medication Name",
                          fieldKey: "medicationName",
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          allowSelection: true,
                          context: context,
                          onValueChanged: _updateFieldValue,
                        ),

                        // 3. Date/Time.
                        // Prescription Date.
                        MedicationDetailsFields.buildDatePicker(
                          label: "Prescription Date",
                          fieldKey: "prescriptionDate",
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          context: context,
                          onValueChanged: _updateFieldValue,
                        ),
                        
                        // Time of prescribing.
                        MedicationDetailsFields.buildTimePicker(
                          label: "Time of prescribing",
                          fieldKey: "prescriptionDate",
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          context: context,
                          onValueChanged: _updateFieldValue,
                        ),
                        
                        // Duration section.
                        // View Mode: Show correct duration value.
                        if (!_controller.isEditing) 
                          MedicationDetailsFields.buildDetailRow(
                            "Duration",
                            _controller.editableMedication["isIndefinite"] == true
                                ? "Indefinite"
                                : "${_controller.editableMedication["durationLength"] ?? "N/A"} ${_controller.editableMedication["durationUnits"] ?? ""}",
                          ),

                        // Edit Mode: Show Indefinite checkbox.
                        if (_controller.isEditing) 
                          MedicationDetailsFields.buildCheckbox(
                            label: "Taken Indefinitely",
                            fieldKey: "isIndefinite",
                            medicationData: _controller.editableMedication,
                            isEditing: _controller.isEditing,
                            onValueChanged: (fieldKey, value) {
                              setState(() {
                                _controller.updateIndefiniteDuration(value);
                              });
                            },
                          ),
    
                        // 4. Duration Units and 5. Duration Length (if not indefinite).
                        if (_controller.isEditing && (_controller.editableMedication["isIndefinite"] == false)) ...[
                          // 4. Duration Units
                          MedicationDetailsFields.buildDropdownField(
                            label: "Duration Units",
                            fieldKey: "durationUnits",
                            options: ["Days", "Weeks", "Months", "Years"],
                            medicationData: _controller.editableMedication,
                            isEditing: _controller.isEditing,
                            onValueChanged: _updateFieldValue,
                          ),
                          
                          // 5. Duration Length.
                          MedicationDetailsFields.buildNumericStepperField(
                            label: "Duration Length",
                            fieldKey: "durationLength",
                            medicationData: _controller.editableMedication,
                            isEditing: _controller.isEditing,
                            onValueChanged: _updateFieldValue,
                            minValue: 1,
                          ),
                        ],
                        
                        // 6. Schedule Type.
                        MedicationDetailsFields.buildDropdownField(
                          label: "Schedule Type",
                          fieldKey: "scheduleType",
                          options: ["daily", "weekly", "monthly"],
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          onValueChanged: _updateFieldValue,
                        ),
                        
                        // 7. Frequency.
                        MedicationDetailsFields.buildNumericStepperField(
                          label: "Frequency",
                          fieldKey: "frequency",
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          onValueChanged: _updateFieldValue,
                          minValue: 1,
                        ),
                        
                        // Application Site (moved here) - only shown for eye medications.
                        if ((_controller.isEditing && _controller.editableMedication["medType"] == "Eye Medication") ||
                           (!_controller.isEditing && _controller.editableMedication["medType"] == "Eye Medication"))
                          MedicationDetailsFields.buildDropdownField(
                            label: "Application Site",
                            fieldKey: "applicationSite",
                            options: ["Left", "Right", "Both"],
                            medicationData: _controller.editableMedication,
                            isEditing: _controller.isEditing,
                            onValueChanged: _updateFieldValue,
                          ),
                        
                        // 8. Dose Units.
                        MedicationDetailsFields.buildDropdownField(
                          label: "Dose Units",
                          fieldKey: "doseUnits",
                          options: ["drops", "sprays", "mL", "teaspoon", "tablespoon", "pills/tablets"],
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          onValueChanged: _updateFieldValue,
                        ),
                        
                        // 9. Dose Quantity.
                        MedicationDetailsFields.buildNumericStepperField(
                          label: "Dose Quantity",
                          fieldKey: "doseQuantity",
                          medicationData: _controller.editableMedication,
                          isEditing: _controller.isEditing,
                          onValueChanged: _updateFieldValue,
                          minValue: 0.1,
                          step: 0.1,  // Explicitly set step to 0.1 for dose quantity
                          allowDecimals: true,
                        ),
                        
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Back and Edit/Save Buttons.
            Center(
              child: EditActionButtons(
                isEditing: _controller.isEditing,
                onBack: () {
                  if (_controller.isEditing) {
                    setState(() {
                      _controller.cancelEditing();
                    });
                  } else {
                    Navigator.pop(context); // Normal back navigation
                  }
                },
                onEditSave: _controller.isEditing 
                  ? () => _saveChanges() 
                  : () => setState(() => _controller.startEditing()),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  /// Handle saving changes with form validation.
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      try {
        
        // Ensures duration fields have string values.
        if (_controller.editableMedication["isIndefinite"] == true) {
          // For indefinite medications, explicitly set empty strings instead of null
          _controller.editableMedication["durationLength"] = "";
          _controller.editableMedication["durationUnits"] = "";
        } else {
          // For definite medications, ensure we have valid values.
          if (_controller.editableMedication["durationLength"] == null) {
            _controller.editableMedication["durationLength"] = "1";
          }
          if (_controller.editableMedication["durationUnits"] == null) {
            _controller.editableMedication["durationUnits"] = "Days";
          }
        }

      await _controller.saveEdits();
      // Closes loading dialog.
      if (mounted) Navigator.of(context).pop();
        
        
      if (mounted) {
        setState(() {}); // Updates UI after save.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medication updated successfully")),
        );
      }        

  
      } catch (e) {
          // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        print("Error saving medication: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update medication. Please try again."), 
              action: SnackBarAction(
                label: 'Details',
                onPressed: () {
                  // Show error details in a dialog for advanced users
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Error Details"),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          child: Text("OK"),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    }
  }
}






