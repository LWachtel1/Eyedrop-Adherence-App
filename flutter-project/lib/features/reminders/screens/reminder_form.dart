import 'package:eyedrop/features/reminders/controllers/reminder_form_controller.dart';
import 'package:eyedrop/features/reminders/screens/eye_medication_selection_screen.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/form_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Form for creating medication reminders.
///
/// Allows users to:
/// - Select an eye medication to create a reminder for.
/// - Set start date/time and duration.
/// - Choose between smart scheduling or manual time selection.
class ReminderForm extends StatefulWidget {
  const ReminderForm({Key? key}) : super(key: key);

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReminderFormController>(context);

    return BaseLayoutScreen(
      child: Form(
        key: controller.formKey,
        child: ListView(
          padding: EdgeInsets.all(5.w),
          children: [
            Center(
              child: Text(
                "Create Reminder",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
            ),
            
            SizedBox(height: 3.h),

            // 1. Medication Selection Field.
            _buildMedicationSelection(controller),
            
            SizedBox(height: 2.h),

            // Only show the rest of the form if a medication is selected.
            if (controller.selectedMedication != null) ...[
              // Display medication details in view-only mode
              _buildMedicationDetails(controller),
              
              SizedBox(height: 2.h),
              
              // 2. Start Date Field
              FormComponents.buildDateField(
                label: "Start Date",
                value: controller.startDate,
                onTap: () => controller.selectStartDate(context),
              ),

              SizedBox(height: 1.h),

              // 3. Start Time Field.
              FormComponents.buildTimeField(
                label: "Start Time",
                value: controller.startTime,
                onTap: () => controller.selectStartTime(context),
              ),

              SizedBox(height: 1.h),

              // 4. Indefinite Duration Checkbox.
              FormComponents.buildCheckbox(
                label: "Set Indefinitely",
                value: controller.isIndefinite,
                onChanged: (val) {
                  setState(() {
                    controller.toggleIndefinite(val!);
                  });
                },
              ),

              SizedBox(height: 1.h),

              // 5-6. Duration Fields (Only show if reminder not set indefinitely).
              if (!controller.isIndefinite) ...[
                // 5. Duration Units.
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

                // 6. Duration Length.
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

              SizedBox(height: 2.h),

              // 7. Smart Scheduling Toggle.
              FormComponents.buildCheckbox(
                label: "Use Smart Scheduling",
                value: controller.smartScheduling,
                onChanged: (val) {
                  setState(() {
                    controller.toggleSmartScheduling(val!);
                  });
                },
              ),

              SizedBox(height: 1.h),

              // 8. Manual Timings (Only if smart scheduling is off).
              if (!controller.smartScheduling) ...[
                _buildTimingsList(controller),
              ],

              SizedBox(height: 3.h),

              // Submit Button.
              Center(
                child: ElevatedButton(
                  onPressed: () => controller.submitForm(context),
                  child: Text(
                    "Create Reminder",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the medication selection widget.
  Widget _buildMedicationSelection(ReminderFormController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selected Medication",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 1.h),
            
            if (controller.selectedMedication == null)
              Center(
                child: Text(
                  "No medication selected",
                  style: TextStyle(fontSize: 15.sp),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.medicationName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    controller.medicationType,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 2.h),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final medication = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EyeMedicationSelectionScreen(),
                    ),
                  );
                  
                  if (medication != null) {
                    controller.setSelectedMedication(medication);
                  }
                },
                icon: Icon(Icons.medication_outlined),
                label: Text(
                  controller.selectedMedication == null
                      ? "Select Medication"
                      : "Change Medication",
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a view-only card displaying medication details
  Widget _buildMedicationDetails(ReminderFormController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Medication Details",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
            ),
            Divider(),
            
            // Schedule type
            _buildDetailRow(
              "Schedule Type",
              _formatScheduleType(controller.scheduleType),
            ),
            
            // Frequency
            _buildDetailRow(
              "Frequency",
              _formatFrequency(controller.frequency, controller.scheduleType),
            ),
            
            // Dose information
            _buildDetailRow(
              "Dose",
              "${_formatDoseQuantity(controller.doseQuantity)} ${controller.doseUnits}",
            ),
            
            // Application site (only for eye medications)
            if (controller.medicationType == "Eye Medication" && 
                controller.applicationSite.isNotEmpty)
              _buildDetailRow(
                "Application Site",
                controller.applicationSite,
              ),
          ],
        ),
      ),
    );
  }

  /// Formats the schedule type to a readable string
  String _formatScheduleType(String scheduleType) {
    if (scheduleType.isEmpty) return "N/A";
    
    String type = scheduleType.toLowerCase();
    // Capitalize first letter
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }

  /// Formats the frequency to a readable string
  String _formatFrequency(int frequency, String scheduleType) {
    String type = scheduleType.isEmpty ? "daily" : scheduleType.toLowerCase();
    
    if (type == "daily") {
      return frequency == 1 ? "Once daily" : "$frequency times daily";
    } else if (type == "weekly") {
      return frequency == 1 ? "Once weekly" : "$frequency times per week";
    } else if (type == "monthly") {
      return frequency == 1 ? "Once monthly" : "$frequency times per month";
    }
    
    return "$frequency times per $type";
  }

  /// Formats the dose quantity to a readable string
  String _formatDoseQuantity(double quantity) {
    // Format to remove trailing zeros if it's a whole number
    return quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1);
  }

  /// Builds a simple label-value row for read-only display
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of timing selections.
  Widget _buildTimingsList(ReminderFormController controller) {
    final requiredCount = controller.getRequiredTimingsCount();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Set Reminder Times",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
            ),
            if (controller.timings.length < requiredCount)
              ElevatedButton.icon(
                onPressed: () => controller.selectTiming(context, controller.timings.length),
                icon: Icon(Icons.add, size: 16.sp),
                label: Text("Add Time", style: TextStyle(fontSize: 13.sp)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                ),
              ),
          ],
        ),
        
        SizedBox(height: 1.h),
        
        Text(
          "Based on your medication schedule, you need to set $requiredCount time(s)",
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        
        SizedBox(height: 1.h),
        
        if (controller.timings.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Center(
              child: Text(
                "No times added yet",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[500],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.timings.length,
            itemBuilder: (context, index) {
              final timing = controller.timings[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 0.5.h),
                child: ListTile(
                  title: Text(
                    "Time ${index + 1}: ${timing.format(context)}",
                    style: TextStyle(fontSize: 15.sp),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => controller.selectTiming(context, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => controller.removeTiming(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}