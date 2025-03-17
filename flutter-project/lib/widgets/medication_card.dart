import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          medication["medicationName"] ?? "Unnamed Medication",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        subtitle: Text(
          medication["medType"] == "Eye Medication" ? "Eye" : "Non-Eye",
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => onDelete(medication),
        ),
        onTap: () => onTap(medication),
      ),
    );
  }
}