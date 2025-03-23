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
    bool isEyeMedication = medication["medType"]?.toString() == "Eye Medication";
    bool hasReminder = medication["reminderSet"] == true;
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        // Displays the medication name.
        title: Text(
          medication["medicationName"]?.toString() ?? "Unnamed Medication",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        // Displays whether the medication is for the eyes or not and reminder status
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEyeMedication ? "Eye" : "Non-Eye",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            ),
            // Only show reminder status for eye medications
            if (isEyeMedication)
              Text(
                hasReminder ? "Reminder set" : "No reminder",
                style: TextStyle(
                  fontSize: 12.sp, 
                  color: hasReminder ? Colors.green[700] : Colors.grey[600],
                  fontWeight: hasReminder ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),

        // Delete button to remove the medication.
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
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
      ),
    );
  }
}