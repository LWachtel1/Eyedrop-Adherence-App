import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';


/// Displays full details of a selected medication.
class MedicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> medication;

  const MedicationDetailScreen({required this.medication, super.key});

  @override
  Widget build(BuildContext context) {
    bool isEyeMedication = medication["isEyeMedication"] == true;
    bool isIndefinite = medication["isIndefinite"] == true;

    return BaseLayoutScreen(
      child: Padding(
        padding: EdgeInsets.only(top: 2.h, left: 5.w, right: 5.w), // Moves content up
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      
    
            // Title
            Center(
              child: Text(
                "Medication Details",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
            ),
           

            // Scrollable Section
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("Medication Name", medication["medicationName"]),
                      _buildDetailRow("Type", isEyeMedication ? "Eye" : "Non-Eye"),
                      _buildDetailRow("Schedule Type", medication["scheduleType"]),
                      _buildDetailRow("Frequency", medication["frequency"].toString()),
                      _buildDetailRow("Dose Quantity", medication["doseQuantity"].toString()),
                      _buildDetailRow("Dose Units", medication["doseUnits"]),
                      _buildDetailRow("Prescribed Date", _formatDateTime(medication["datePrescribed"])),

                      // Handle "Duration" conditionally
                      _buildDetailRow(
                        "Duration",
                        isIndefinite
                            ? "Indefinite"
                            : "${medication["durationLength"] ?? "N/A"} ${medication["durationUnits"] ?? ""}",
                      ),

                      // Show Application Site only for eye medications
                      if (isEyeMedication) _buildDetailRow("Application Site", medication["applicationSite"]),

                      SizedBox(height: 2.h), // Extra spacing for scrolling comfort
                    ],
                  ),
                ),
              ),
            ),

          // Back Button
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back", style: TextStyle(fontSize: 17.5.sp)),
              ),
            ),
            SizedBox(height: 2.h), // Adds spacing at the bottom
          ],
        ),
      ),
    );
  }

  /// Builds an evenly spaced detail row with labels and values on separate lines.
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5.sp, color: Colors.grey[700]),
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

  String _formatDateTime(dynamic date) {
  if (date == null) return "N/A";

  // If it's already a DateTime, format it
  if (date is DateTime) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date); // Formats as "2025-03-12 14:03"
  }

  // If it's a Firestore Timestamp, convert it to DateTime
  if (date is Timestamp) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date.toDate());
  }

  return "Invalid Date";
}

}
