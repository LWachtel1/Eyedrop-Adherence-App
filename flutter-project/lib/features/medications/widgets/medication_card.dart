import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// A reusable widget that displays a medication card.
///
/// This card includes the medication's name, type (Eye/Non-Eye), 
/// and provides options for deleting or selecting the medication.
///
/// Parameters:
/// - `medication`: A map containing medication details (e.g., name, type).
/// - `onDelete`: A callback function triggered when the delete button is pressed.
/// - `onTap`: A callback function triggered when the card is tapped.
///
/// Example Usage:
/// ```dart
/// MedicationCard(
///   medication: {
///     "medicationName": "Artificial Tears",
///     "medType": "Eye Medication"
///   },
///   onDelete: (med) => print("Deleted: ${med['medicationName']}"),
///   onTap: (med) => print("Selected: ${med['medicationName']}"),
/// )
/// ```
class MedicationCard extends StatelessWidget {
  final Map<String, dynamic> medication;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onTap;

  const MedicationCard({
    required this.medication,
    required this.onDelete,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasReminder = medication["reminderSet"] == true;
    String? notes = medication["notes"]?.toString();
    String? applicationSite = medication["applicationSite"]?.toString();
    String? doseQuantity = medication["doseQuantity"]?.toString();
    String? doseUnits = medication["doseUnits"]?.toString();
    String? frequency = medication["frequency"]?.toString();
    String? scheduleType = medication["scheduleType"]?.toString();
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 5.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          try {
            if (medication.isNotEmpty) {
              onTap(medication);
            } else {
              throw Exception("Invalid medication data");
            }
          } catch (e) {
            debugPrint("Error selecting medication: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to open medication details.")),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with medication name and delete button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      medication["medicationName"]?.toString() ?? "Unnamed Medication",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20.sp,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 22.sp),
                    onPressed: () {
                      try {
                        onDelete(medication);
                      } catch (e) {
                        debugPrint("Error deleting medication: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to delete medication.")),
                        );
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Medication Type with Icon
              Row(
                children: [
                  Icon(Icons.medication_outlined, size: 18.sp, color: Colors.blue[700]),
                  SizedBox(width: 2.w),
                  Text(
                    "Eye Medication",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Reminder Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: hasReminder ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasReminder ? Colors.green.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasReminder ? Icons.notifications_active : Icons.notifications_off,
                      size: 18.sp,
                      color: hasReminder ? Colors.green[700] : Colors.grey[600],
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      hasReminder ? "Reminder active" : "No reminder set",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: hasReminder ? Colors.green[700] : Colors.grey[600],
                        fontWeight: hasReminder ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Additional Details Section
              if (applicationSite != null || doseQuantity != null || frequency != null) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (applicationSite != null) ...[
                        _buildDetailRow(
                          Icons.remove_red_eye,
                          "Application: $applicationSite",
                        ),
                        SizedBox(height: 0.5.h),
                      ],
                      if (doseQuantity != null && doseUnits != null) ...[
                        _buildDetailRow(
                          Icons.local_hospital_outlined,
                          "Dose: $doseQuantity $doseUnits",
                        ),
                        SizedBox(height: 0.5.h),
                      ],
                      if (frequency != null && scheduleType != null) ...[
                        _buildDetailRow(
                          Icons.schedule,
                          "$frequency times $scheduleType",
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Notes Section
              if (notes != null && notes.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 16.sp, color: Colors.blue[700]),
                          SizedBox(width: 1.w),
                          Text(
                            "Notes",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        notes,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.blue[900],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[700]),
        SizedBox(width: 2.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}