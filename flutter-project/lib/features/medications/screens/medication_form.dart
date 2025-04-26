import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/features/medications/controllers/medication_form_controller.dart';
import 'package:eyedrop/shared/widgets/form_components.dart';
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
            Center(
              child: Text(
                "Add Eye Medication",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
            ),
            
            SizedBox(height: 3.h),

            // 1. Medication Name Field with search for eye medications
            FormComponents.buildTextField(
              label: "Medication Name",
              controller: controller.medicationController,
              onTapIcon: () => controller.selectMedicationFromFirestore(context),
              icon: Icons.search,
            ),
          
            SizedBox(height: 1.h),

            // 2. Application Site
            FormComponents.buildDropdown(
              label: "Application Site",
              value: controller.applicationSite,
              items: ["Left", "Right", "Both"],
              onChanged: (val) {
                setState(() {
                  controller.applicationSite = val!;
                });
              },
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

            // 5-6. Duration Fields (Only show if not indefinite)
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

              // 6. Duration Length
              FormComponents.buildNumericStepperField(
                label: "Duration Length",
                controller: controller.durationController,
                isEnabled: !controller.isIndefinite,
                step: 1.0,
                minValue: 1.0,
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

            // 7. Schedule Type
            FormComponents.buildDropdown(
              label: "Schedule Type",
              value: "daily",
              items: ["daily"],
              onChanged: (val) {
                setState(() {
                  controller.scheduleType = val!;
                });
              },
            ),

            SizedBox(height: 1.h),

            // 8. Frequency
            FormComponents.buildNumericStepperField(
              label: "Frequency",
              controller: controller.frequencyController,
              isEnabled: true,
              step: 1.0,
              minValue: 1.0,
              allowDecimals: false,
              onIncrement: () {
                controller.incrementFrequency();
              },
              onDecrement: () {
                controller.decrementFrequency();
              },
            ),

            SizedBox(height: 1.h),

            // 9. Dose Units
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

            // 10. Dose Quantity
            FormComponents.buildNumericStepperField(
              label: "Dose Quantity",
              controller: controller.doseQuantityController,
              isEnabled: true,
              step: 0.1,
              minValue: 0.1,
              allowDecimals: true,
              onIncrement: () {
                controller.incrementDoseQuantity();
              },
              onDecrement: () {
                controller.decrementDoseQuantity();
              },
            ),

            SizedBox(height: 2.h),

            // 11. Notes
            TextFormField(
              controller: controller.notesController,
              decoration: InputDecoration(
                labelText: "Notes",
                hintText: "Add any additional notes about this medication",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textAlignVertical: TextAlignVertical.top,
            ),

            SizedBox(height: 3.h),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () => controller.submitForm(context),
                child: Text(
                  "Add Medication",
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
