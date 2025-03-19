import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:eyedrop/logic/medications/medication_form_controller.dart';
import 'package:eyedrop/widgets/form_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Form for user medication input.
///
/// This form allows users to input details about their medication.
/// 
/// Features:
/// - Uses `MedicationFormController` to manage form state.
/// - Includes input validation and structured form fields.
/// - Supports increment/decrement numeric fields for dose, frequency, and duration.
/// - Allows users to select medication type (Eye or Non-Eye Medication).
/// - Conditionally displays fields based on input values.
/// - Includes search functionality for eye medications.
class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key});

  @override
  MedicationFormState createState() => MedicationFormState();
}

class MedicationFormState extends State<MedicationForm> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MedicationFormController>(context);
  
    return BaseLayoutScreen(
      child: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.all(5.w),
          children: [
            // 1. Medication Type Toggle (Eye vs. Non-Eye)
            _buildToggleButtons(controller),
            
            SizedBox(height: 1.h),

            // 2. Medication Name Field
            // - Manual entry is always allowed.
            // - If "Eye Medication" is selected, users can also search for a medication
            FormComponents.buildTextField(
              label: "Medication Name",
              controller: controller.medicationController,
              onTapIcon: controller.medType == "Eye Medication"
                  ? () => controller.selectMedicationFromFirestore(context)
                  : null, // Opens selection only if search icon is clicked.
              icon: controller.medType == "Eye Medication" ? Icons.search : null,
            ),
          
            SizedBox(height: 1.h),

            // 3. Date/Time
            // Date Prescribed
            FormComponents.buildDateField(
              label: "Date Prescribed",
              value: controller.prescriptionDate,
              onTap: () => controller.selectPrescriptionDate(context),
            ),

            SizedBox(height: 1.h),

            // Time of prescription
            FormComponents.buildTimeField(
              label: "Prescription Time",
              value: controller.prescriptionTime,
              onTap: () => controller.selectPrescriptionTime(context),
            ),

            SizedBox(height: 1.h),

            // 4. Taken Indefinitely Checkbox
            // - If checked, the duration fields will be hidden.
            FormComponents.buildCheckbox(
              label: "Taken Indefinitely",
              value: controller.isIndefinite,
              onChanged: (val) {
                setState(() {
                  controller.isIndefinite = val!;
                });
              },
            ),

            SizedBox(height: 1.h),

            // 5-6. Duration Fields (Only show if not medication not taken indefinitely)
            if (!controller.isIndefinite) ...[
              // 5. Duration Units
              FormComponents.buildDropdown(
                label: "Duration Unit",
                value: controller.durationUnit.isNotEmpty ? controller.durationUnit : null,
                items: ["Days", "Weeks", "Months", "Years"],
                onChanged: (val) {
                  setState(() {
                    controller.durationUnit = val!;
                  });
                },
              ),

              SizedBox(height: 1.h),

              // 6. Duration Length field
              FormComponents.buildNumericStepperField(
                label: "Duration Length",
                controller: controller.durationController,
                isEnabled: !controller.isIndefinite,
                step: 1.0,
                minValue: 1.0, // Ensures a minimum of 1
                allowDecimals: false,
                onIncrement: () {
                  controller.incrementDurationLength();
                },
                onDecrement: () {
                  controller.decrementDurationLength();
                },
              ),
            ],

            SizedBox(height: 1.h),

            // 7. Schedule Type Dropdown field
            FormComponents.buildDropdown(
              label: "Schedule Type",
              value: controller.scheduleType.isNotEmpty ? controller.scheduleType : null,
              items: ["daily", "weekly", "monthly"],
              onChanged: (val) {
                setState(() {
                  controller.scheduleType = val!;
                });
              },
            ),

            SizedBox(height: 1.h),

            // 8. Frequency Field
            // - Minimum value: 1
            // - Increments/Decrements by 1
            FormComponents.buildNumericStepperField(
              label: "Frequency",
              controller: controller.frequencyController,
              isEnabled: true,
              step: 1.0,
              minValue: 1.0, // Ensures a minimum of 1
              allowDecimals: false,
              onIncrement: () {
                controller.incrementFrequency();
              },
              onDecrement: () {
                controller.decrementFrequency();
              },
            ),

            SizedBox(height: 1.h),

            // 9. Application Site field (Only show if medication is eye medication)
            if (controller.medType == "Eye Medication") ...[
              FormComponents.buildDropdown(
                label: "Application Site",
                value: controller.applicationSite.isNotEmpty ? controller.applicationSite : null,
                items: ["Left Eye", "Right Eye", "Both Eyes"],
                onChanged: (val) {
                  setState(() {
                    controller.applicationSite = val!;
                  });
                },
              ),
              
              SizedBox(height: 1.h),
            ],

            // 10. Dose Units
            FormComponents.buildDropdown(
              label: "Dose Units",
              value: controller.doseUnits.isNotEmpty ? controller.doseUnits : null,
              items: ["drops", "sprays", "mL", "teaspoon", "tablespoon", "pills/tablets"],
              onChanged: (val) {
                setState(() {
                  controller.doseUnits = val!;
                });
              },
            ),

            SizedBox(height: 1.h),

            // 11. Dose Quantity
            // - Allows manual entry
            // - Increments/Decrements by 0.1
            // - Minimum dose: 0.0
            FormComponents.buildNumericStepperField(
              label: "Dose Quantity",
              controller: controller.doseQuantityController,
              isEnabled: true,
              step: 0.1,
              minValue: 0.0, // Allows exactly 0.0 minimum
              allowDecimals: true,
              onIncrement: () {
                controller.incrementDoseQuantity();
              },
              onDecrement: () {
                controller.decrementDoseQuantity();
              },
            ),

            SizedBox(height: 2.h),

            // Submit Button
            ElevatedButton(
              onPressed: () => controller.submitForm(context),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds toggle buttons for selecting medication type (Eye vs. Non-Eye).
  Widget _buildToggleButtons(MedicationFormController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FormComponents.buildToggleButton(
          label: "Eye Medication",
          isSelected: controller.medType == "Eye Medication",
          onTap: () {
            setState(() {
              controller.medType = "Eye Medication";
            });
          },
        ),
        SizedBox(width: 10), 
        
        FormComponents.buildToggleButton(
          label: "Non-Eye Medication",
          isSelected: controller.medType == "Non-Eye Medication",
          onTap: () {
            setState(() {
              controller.medType = "Non-Eye Medication";
            });
          },
        ),
      ],
    );
  }
}
