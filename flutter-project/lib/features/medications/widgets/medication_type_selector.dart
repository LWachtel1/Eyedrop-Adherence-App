import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MedicationTypeSelector extends StatelessWidget {
  final Map<String, dynamic> medicationData;
  final Function(String, dynamic) onValueChanged;

  const MedicationTypeSelector({
    Key? key,
    required this.medicationData,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              onValueChanged("medType", "Eye Medication");
              if (!medicationData.containsKey("applicationSite")) {
                onValueChanged("applicationSite", "Both");
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: medicationData["medType"] == "Eye Medication" 
                    ? Colors.blue 
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "Eye Medication",
                  style: TextStyle(
                    color: medicationData["medType"] == "Eye Medication" 
                        ? Colors.white 
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              onValueChanged("medType", "Non-Eye Medication");
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: medicationData["medType"] == "Non-Eye Medication" 
                    ? Colors.blue 
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "Non-Eye Medication",
                  style: TextStyle(
                    color: medicationData["medType"] == "Non-Eye Medication" 
                        ? Colors.white 
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}