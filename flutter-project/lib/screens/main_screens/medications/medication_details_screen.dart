/* 
  TO DO:
  check it works correctly
*/

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/screens/form_screens/medication_selection_screen.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Displays full details of a selected medication with inline editing.
class MedicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> medication;

  const MedicationDetailScreen({required this.medication, super.key});

  @override
  _MedicationDetailScreenState createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  bool isEditing = false; // Toggles between view and edit mode
  bool isLoading = true; // **Flag to track loading state**

   Map<String, dynamic> editableMedication = {};

  final _formKey = GlobalKey<FormState>();

  @override
  @override
void initState() {
  super.initState();
  _fetchMedicationData();
}

/// Fetches latest medication data from Firestore
/// Fetches latest medication data from Firestore
 /// Fetches latest medication data from Firestore
  Future<void> _fetchMedicationData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      String collectionPath = widget.medication["isEyeMedication"] == true
          ? "users/$uid/eye_medications"
          : "users/$uid/noneye_medications";
      String docId = widget.medication["id"];

      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      final fetchedData =
          await firestoreService.readDoc(collectionPath: collectionPath, docId: docId);

      setState(() {
        editableMedication = fetchedData ?? {};
        isLoading = false; // **Stop loading once data is fetched**
      });

    } catch (e) {
      log("Error fetching medication: $e");
      setState(() {
        isLoading = false; // **Even if error occurs, stop loading**
      });
    }
  }


  /// Saves the edited data back to Firestore
  Future<void> _saveEdits() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    // Ensure correct values for duration
    if (editableMedication["isIndefinite"] == true) {
      editableMedication["durationLength"] = null;
      editableMedication["durationUnits"] = null;
    }

       // Remove applicationSite if switching to Non-Eye Medication
    if (editableMedication["isEyeMedication"] == false) {
      editableMedication.remove("applicationSite");
    }


    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("No authenticated user found. Cannot edit medication.");
        return;
      }

      String uid = user.uid;
      String collectionPath = editableMedication["isEyeMedication"] == true
          ? "users/$uid/eye_medications"
          : "users/$uid/noneye_medications";
      String docId = editableMedication["id"];

      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      await firestoreService.updateDoc(
        collectionPath: collectionPath,
        docId: docId,
        newData: editableMedication,
      );

      setState(() {
        isEditing = false; // Exit edit mode after saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Medication updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating medication: $e")),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    bool isEyeMedication = editableMedication["isEyeMedication"] == true;
    bool isIndefinite = editableMedication["isIndefinite"] == true;

    if (isLoading) {
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

            // Scrollable Form
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
_buildEditableField("Medication Name", "medicationName", allowSelection: true),

if (isEditing)
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              editableMedication["isEyeMedication"] = true;

              // Ensure "applicationSite" exists when selecting Eye Medication
              if (!editableMedication.containsKey("applicationSite")) {
                editableMedication["applicationSite"] = "Both"; // Default value
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: editableMedication["isEyeMedication"] == true ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "Eye Medication",
                style: TextStyle(
                  color: editableMedication["isEyeMedication"] == true ? Colors.white : Colors.black,
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
            setState(() {
              editableMedication["isEyeMedication"] = false;

              // Remove "applicationSite" when switching to Non-Eye Medication
              editableMedication.remove("applicationSite");
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: editableMedication["isEyeMedication"] == false ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "Non-Eye Medication",
                style: TextStyle(
                  color: editableMedication["isEyeMedication"] == false ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  )
else
  _buildDetailRow("Type", editableMedication["isEyeMedication"] == true ? "Eye Medication" : "Non-Eye Medication"),

// Show or disable Application Site field
if (isEditing && editableMedication["isEyeMedication"] == true)
  _buildDropdownField("Application Site", "applicationSite", ["Left", "Right", "Both"])
else if (!isEditing && editableMedication["isEyeMedication"] == true)
  _buildDetailRow("Application Site", editableMedication["applicationSite"] ?? "N/A"),
                        
                        _buildDropdownField("Schedule Type", "scheduleType", ["daily", "weekly", "monthly"]),
                        _buildEditableField("Frequency", "frequency", isNumeric: true),
                        _buildEditableField("Dose Quantity", "doseQuantity", isNumeric: true),
                        _buildDropdownField("Dose Units", "doseUnits", ["drops", "sprays", "mL", "pills"]),
                        _buildDatePicker("Prescription Date", "datePrescribed"),
                        _buildTimePicker("Time of prescribing", "datePrescribed"), // Uses same field


                        // View Mode: Show correct duration value
if (!isEditing) 
  _buildDetailRow(
    "Duration",
    editableMedication["isIndefinite"] == true
        ? "Indefinite"
        : "${editableMedication["durationLength"] ?? "N/A"} ${editableMedication["durationUnits"] ?? ""}",
  ),

// Edit Mode: Show fields correctly
if (isEditing) 
  Row(
    children: [
      Checkbox(
        value: editableMedication["isIndefinite"] ?? false,
        onChanged: (value) {
          setState(() {
            editableMedication["isIndefinite"] = value!;
            if (value) {
              // Clear fields when indefinite is selected
              editableMedication["durationLength"] = null;
              editableMedication["durationUnits"] = null;
            }
          });
        },
      ),
      Text("Taken Indefinitely", style: TextStyle(fontSize: 17.5.sp)),
    ],
  ),
  
// Show duration fields only if NOT indefinite
if (isEditing && (editableMedication["isIndefinite"] == false)) ...[
  _buildEditableField("Duration Length", "durationLength", isNumeric: true),
  _buildDropdownField("Duration Units", "durationUnits", ["Days", "Weeks", "Months", "Years"]),
],

                        // Show Application Site only for eye medications
                        if (isEyeMedication) _buildDropdownField("Application Site", "applicationSite", ["Left", "Right", "Both"]),
                        
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Back and Edit/Save Buttons
            Center(
              child: 
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Back Button
                 ElevatedButton(
                  onPressed: () {
                    if (isEditing) {
                      setState(() {
                        isEditing = false; 
                        editableMedication = Map.from(widget.medication); // Revert changes
                      });
                    } else {
                      Navigator.pop(context); // Normal back navigation
                    }
                  },
                  child: Text("Back", style: TextStyle(fontSize: 17.5.sp)),
                ),


                        ElevatedButton(
              child: Text(isEditing ? "Save" : "Edit", style: TextStyle(fontSize: 17.5.sp)),
              onPressed: isEditing ? _saveEdits : () => setState(() => isEditing = true),
            ),
              ],
            ),
              
              
            
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  /// Builds an editable text field for modifying data.
/// Builds an editable text field with optional selection support.
Widget _buildEditableField(
  String label,
  String fieldKey, {
  bool isNumeric = false,
  bool allowSelection = false,
}) {
  TextEditingController controller =
      TextEditingController(text: editableMedication[fieldKey]?.toString());

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
              color: Colors.grey[700]),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextFormField(
                      controller: controller,
                      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
                      onChanged: (value) => editableMedication[fieldKey] = value,
                      onSaved: (value) => editableMedication[fieldKey] = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "This field cannot be empty";
                        if (isNumeric) {
                          double? numValue = double.tryParse(value);
                          if (numValue == null || numValue < 1) {
                            return "Value must be a number and at least 1";
                          }
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                    )
                  : Text(
                      editableMedication[fieldKey]?.toString() ?? "N/A",
                      style: TextStyle(fontSize: 17.5.sp),
                    ),
            ),
            if (isEditing && allowSelection && editableMedication["isEyeMedication"] == true)
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () => _selectMedicationFromFirestore(fieldKey, controller),
              ),
          ],
        ),
      ],
    ),
  );
}



Future<void> _selectMedicationFromFirestore(String fieldKey, TextEditingController controller) async {
  if (!isEditing || editableMedication["isEyeMedication"] != true) return; // Prevent selection if not editing

  final selectedMedication = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MedicationSelectionScreen()),
  );

  if (selectedMedication != null) {
    setState(() {
      controller.text = selectedMedication;
      editableMedication[fieldKey] = selectedMedication;
    });
  }
}



  /// Builds a dropdown field for selection.
  Widget _buildDropdownField(String label, String fieldKey, List<String> options) {
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
          isEditing
              ? DropdownButtonFormField<String>(
                  value: editableMedication[fieldKey],
                  items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (value) {
                    setState(() {
                      editableMedication[fieldKey] = value!;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                )
              : Text(
                  editableMedication[fieldKey]?.toString() ?? "N/A",
                  style: TextStyle(fontSize: 17.5.sp),
                ),
        ],
      ),
    );
  }

/// Builds a time picker field that extracts time from prescribedDate.
Widget _buildTimePicker(String label, String fieldKey) {
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
        isEditing
            ? GestureDetector(
                onTap: () => _selectTime(fieldKey),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(editableMedication[fieldKey]), // Formats only time
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      Icon(Icons.access_time, color: Colors.blue),
                    ],
                  ),
                ),
              )
            : Text(
                _formatTime(editableMedication[fieldKey]), // Show time when not editing
                style: TextStyle(fontSize: 17.5.sp),
              ),
      ],
    ),
  );
}

/// Extracts and formats only the time from Firestore Timestamp or DateTime.
String _formatTime(dynamic date) {
  if (date == null) return "N/A";

  // If it's a Firestore Timestamp, convert it to DateTime first
  DateTime dateTime = _extractDateTime(date);

  return DateFormat('HH:mm').format(dateTime); // Formats as "14:03"
}

/// Extracts DateTime from a Firestore Timestamp or DateTime.
DateTime _extractDateTime(dynamic date) {
  if (date is Timestamp) return date.toDate();
  if (date is DateTime) return date;
  return DateTime.now(); // Fallback in case of null or invalid type
}


/// Opens a time picker and updates only the time in prescribedDate.
Future<void> _selectTime(String fieldKey) async {
  DateTime originalDateTime = _extractDateTime(editableMedication[fieldKey]);

  TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: originalDateTime.hour, minute: originalDateTime.minute),
  );

  if (pickedTime != null) {
    setState(() {
      // Create a new DateTime with the updated time
      DateTime updatedDateTime = DateTime(
        originalDateTime.year,
        originalDateTime.month,
        originalDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Store back as Firestore Timestamp
      editableMedication[fieldKey] = Timestamp.fromDate(updatedDateTime);
    });
  }
}



  /// Builds a date picker field.
 /// Builds a date picker field that correctly formats the Firestore Timestamp.
/// Builds a date picker field that correctly formats Firestore Timestamp.
Widget _buildDatePicker(String label, String fieldKey) {
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
        isEditing
            ? GestureDetector(
                onTap: () => _selectDate(fieldKey),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateOnly(editableMedication[fieldKey]), // Only date in edit mode
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      Icon(Icons.calendar_today, color: Colors.blue),
                    ],
                  ),
                ),
              )
            : Text(
                _formatDateOnly(editableMedication[fieldKey]), // Only date in non-edit mode
                style: TextStyle(fontSize: 17.5.sp),
              ),
      ],
    ),
  );
}


Future<void> _selectDate(String fieldKey) async {
  DateTime originalDateTime = _extractDateTime(editableMedication[fieldKey]);

  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: originalDateTime,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    setState(() {
      // Retain the existing time and update only the date
      DateTime updatedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        originalDateTime.hour,
        originalDateTime.minute,
      );

      // Store back as Firestore Timestamp
      editableMedication[fieldKey] = Timestamp.fromDate(updatedDateTime);
    });
  }
}


}


  /// Builds a static detail row (non-editable fields).
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

  /// Formats date-time values from Firestore.
/// Formats date-time values from Firestore correctly.
String _formatDateTime(dynamic date) {
  if (date == null) return "N/A";

  // If it's already a DateTime, format it
  if (date is DateTime) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date); // Formats as "12-03-2025 14:03"
  }

  // If it's a Firestore Timestamp, convert it to DateTime
  if (date is Timestamp) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date.toDate());
  }

  return "Invalid Date";
}


/// Formats and returns only the date from Firestore Timestamp or DateTime.
String _formatDateOnly(dynamic date) {
  if (date == null) return "N/A";

  // If it's already a DateTime, format it
  if (date is DateTime) {
    return DateFormat('dd-MM-yyyy').format(date); // Formats as "12-03-2025"
  }

  // If it's a Firestore Timestamp, convert it to DateTime
  if (date is Timestamp) {
    return DateFormat('dd-MM-yyyy').format(date.toDate());
  }

  return "Invalid Date";
}



  


