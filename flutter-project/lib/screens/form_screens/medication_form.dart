/* 
  TO DO:
  - add condition IDs to link to added medication
*/

import 'dart:developer';
import 'package:eyedrop/logic/database/doc_templates.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:eyedrop/screens/form_screens/medication_selection_screen.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// A form for creating and storing user medications.
/// 
/// This allows users to specify:
/// - Medication Type: Eye or non-eye medication.
/// - Medication Name: Either manually entered or selected from a predefined list (only for eye medications).
/// - Prescription Details: Date, time, and whether it's indefinite.
/// - Duration (if not indefinite): Units (days, weeks, months) and length.
/// - Schedule Type: Daily, weekly, or monthly.
/// - Dosage Details: Frequency, dose units, and quantity.
/// - Eye Medication Specifics: Application site (left, right, both).
/// 
/// Validates user input and prevents duplicate medications from being stored.
class MedicationForm extends StatefulWidget {
  @override
  _MedicationFormState createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  // A unique key used to validate and manage the form state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 

  String _medType = '';
  String? _commonMedicationID; // For common eye medications pre-defined in `medications` collection.
  String _medicationName = ''; 
  DateTime? _prescriptionDate;
  TimeOfDay? _prescriptionTime;
  bool _isIndefinite = false;
  String _durationUnits = '';
  int _durationLength = 1;
  String _scheduleType = '';
  int _frequency = 1;
  String _doseUnits = '';

  double _doseQuantity = 0.0;
  String _applicationSite = ''; // An Eye Medication Only Field.

  Map<String, dynamic> medData = {}; // Stores the submitted data to be added to FireStore in a document.
  bool isDuplicate = false; // Whether the medication details submitted are a duplicate of an already existing user medication.

  TextEditingController _medicationController = TextEditingController();
  // Manages the value of a TextField or TextFormField dynamically.
  // Can programatically retrieve, update and clear. Also listens for text changes.

  final TextEditingController _durationController = 
    TextEditingController(text: '1');  //Manages value of `_durationLength` field.

    final TextEditingController _frequencyController = 
    TextEditingController(text: '1');  //Manages value of `_frequency` field.

  
  /// Opens a selection screen for choosing a common eye medication.
  /// 
  /// - Only applicable for eye medications.
  /// - Updates the medication name field when a selection is made.
  /// - Uses `Navigator.push()` to load the selection screen asynchronously.
  Future<void> _selectMedicationFromFirestore() async {

    try {
      final selectedMedication = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MedicationSelectionScreen()),
      );

      // If a medication was selected, the form field is updated to display this selection. 
      if (selectedMedication != null) {
        //  setState() tells Flutter that the UI should be rebuilt to reflect changes in widget state.
        setState(() {
          _medicationName = selectedMedication;
          _medicationController.text = selectedMedication;
        });
      } else {
        log("User canceled medication selection.");
      }
  } catch (e) {
    log("Error selecting medication: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select medication. Try again.")),
      );
    }
  }
}

/// Opens a date picker to select the prescription date.
/// 
/// - Shows a calendar allowing the user to pick a date.
/// - Ensures the selected date is within a valid range (2000-2100).
/// - Updates `_prescriptionDate` and rebuilds the UI.
/// - If no date is selected, keeps the existing value.
Future<void> _selectPrescriptionDate(BuildContext context) async {
  try {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  // If a date is selected, the relevant field is updated and the UI rebuilt to display these changes.
  if (pickedDate != null && pickedDate != _prescriptionDate) {
    setState(() {
      _prescriptionDate = pickedDate;
    });
  } else {
      log("User canceled date selection.");
    }
  } catch (e) {
    log("Error selecting date: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select date. Please try again.")),
      );
    }
  }
}

/// Shows a time picker for selecting the time portion of the date-time of prescription.
Future<void> _selectPrescriptionTime(BuildContext context) async {

  // If a time has already been picked, it will be pre-selected to be shown on the time picker.
  // Otherwise, the current time is shown by default.
  TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: _prescriptionTime ?? TimeOfDay.now(),
  );

  if (pickedTime != null) {
    setState(() {
      _prescriptionTime = pickedTime;
    });
  }
}

/// Combines the separately selected date and time to save them together as a single DateTime object.
/// 
/// Returns:
/// - A DateTime object containing the combined date and time.
DateTime getFinalPrescriptionDateTime() {
  if (_prescriptionDate == null) return DateTime.now();

  // If user selected a time, use it, otherwise default to 12:00 AM.
  return DateTime(
    _prescriptionDate!.year,
    _prescriptionDate!.month,
    _prescriptionDate!.day,
    _prescriptionTime?.hour ?? 0,
    _prescriptionTime?.minute ?? 0,
  );
}


  /// Validates the form and uploads medication data to Firestore.
  /// 
  /// - Ensures all required fields are filled.
  /// - Prevents duplicate medications from being added.
  /// - Saves data in the correct subcollection based on medication type.
  /// - Displays a warning if a duplicate is detected.
  Future<void> _submitForm() async {
    setState(() {}); // Forces UI update for validation message.

    if (_medType.isEmpty) {
      return; // Stops submission if medication type is not selected.
    }

    // Calls the validator functions of all TextFormField widgets inside the form.
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Triggers the onSaved function of each TextFormField.
      
      // Gets the FirestoreService from Provider to allow CRUD operations within class.
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      
      try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("No authenticated user found. Cannot add medication.");
        return; // Safeguard: if no user, do nothing.
      } 

      _prescriptionDate = getFinalPrescriptionDateTime(); 
      // Stores the combined prescription date-time together in the `_prescriptionDate` field.

      if (_medType == "Eye Medication") {

      List<Map<String, dynamic>> results = await firestoreService.queryCollection(collectionPath: 'medications', 
      filters: [{"field": "medicationName", "operator": "==", "value": _medicationName}],
      limit: 1);

      if(results.isNotEmpty) {
        _commonMedicationID = results.first["id"];
      }

       medData = createUserEyeMedDoc(
            _commonMedicationID,
            _medicationName,
            _prescriptionDate ?? DateTime.now(),
            _isIndefinite,
            _isIndefinite ? null : _durationUnits,
           _isIndefinite ? null : _durationLength,
            _scheduleType,
            _frequency,
            _doseUnits,
            _doseQuantity,
            _applicationSite);
        
        isDuplicate = await firestoreService.checkExactDuplicateDoc(collectionPath: "users/${user.uid}/eye_medications", data: medData);

        if(!isDuplicate) {
          await firestoreService.addDoc(path: "users/${user.uid}/eye_medications", data:medData);
        } 

      } else if(_medType == "Non-Eye Medication") {
          medData = createUserNonEyeMedDoc(
            _medicationName,
            _prescriptionDate ?? DateTime.now(),
           _isIndefinite,
            _isIndefinite ? null : _durationUnits,
           _isIndefinite ? null : _durationLength, 
            _scheduleType,
            _frequency,
            _doseUnits,
            _doseQuantity,
          );

          isDuplicate = await firestoreService.checkExactDuplicateDoc(collectionPath: "users/${user.uid}/noneye_medications", data: medData);

          if(!isDuplicate) {
            await firestoreService.addDoc(path: "users/${user.uid}/noneye_medications", data:medData);
          } 
      }

        // If the user medication is a duplicate, a pop-up warning is displayed and the medication is not saved.
        if (isDuplicate) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("This medication is already in your records."),
          backgroundColor: Colors.orangeAccent,
         ),
        );
      }
    } else {
          log("Medication successfully added.");
          if (mounted) {
            Navigator.pop(context); // Returns to previous screen after successful submission.
          }
        }
        
      } on FirebaseException catch (e) {
          log("Firebase Error: ${e.message}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Database error: ${e.message}")),
            );
          }
      } on PlatformException catch (e) {
          log("Platform Error: ${e.message}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("A platform error occurred: ${e.message}")),
            );
          }
      } catch (e, stackTrace) {
          log("Unexpected error while adding medication: $e\n$stackTrace");
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Unexpected Error"),
                content: Text("An error occurred while saving medication. Please try again."),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
              ),
            );
          }
      }

    }
  }

  /// Displays the user medication creation form in a scrollable view.
  /// 
  /// 
  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen( 
      child: SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(), // Scrolling behavior.
      child: Padding(
        padding: EdgeInsets.all(5.w),
      child: Form(
        key: _formKey, // Associates the form key with this Form widget.
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Back button.
              Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back", style: TextStyle(fontSize: 17.5.sp)),
                ),
              ),
        
              // Enables toggling between eye versus non-eye medication and subsequent
              // hiding of irrelevant fields and display relevant fields.
              Text("Medication Type", style: TextStyle(fontWeight: FontWeight.bold)),
              // Row arranges the two tiles, Eye Medication and Non-eye Medication, horizontally.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    // Makes the tile tappable.
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          // Sets _medType to either "" or Eye Medication depending on toggled state of button.
                          _medType = _medType == "Eye Medication" ? "" : "Eye Medication"; 
                        });
                      },
                      // Displays the tile that changes colour depending on whether it is selected or not.
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        margin: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _medType == "Eye Medication" ? Colors.blue : Colors.grey[300], // Highlights if selected.
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          // Displays the text for the toggle button. 
                          // Changes colour of text depending on toggled state.
                          child: Text(
                            "Eye Medication",
                            style: TextStyle(
                              color: _medType == "Eye Medication" ? Colors.white : Colors.black,
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
                          _medType = _medType == "Non-Eye Medication" ? "" : "Non-Eye Medication"; // Toggles selection
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        margin: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _medType == "Non-Eye Medication" ? Colors.blue : Colors.grey[300], // Highlight if selected
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "Non-Eye Medication",
                            style: TextStyle(
                              color: _medType == "Non-Eye Medication" ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // If no medication type is selected, an error message is shown underneath the 2 tiles.
              if (_medType.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    "Please select a medication type.",
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                ),
            
      
                // Medication Name (Manual Entry or Select from FireStore).
                Text("Medication Name", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      // Manual entry.
                      child: TextFormField(
                        controller: _medicationController,
                        decoration: InputDecoration(
                          labelText: 'Enter Medication Name',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter or select a medication.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _medicationName = value!;
                        },
                      ),
                    ),
                    // Clickable search icon to select medications from FireStore.
                    IconButton(
                      icon: Icon(Icons.search),
                      iconSize: 10.w,
                      onPressed: _selectMedicationFromFirestore,
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                // Date of Prescription picker.
                Text("Date Prescribed", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: () => _selectPrescriptionDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                    margin: EdgeInsets.only(bottom: 5.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.w),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _prescriptionDate != null
                              ? "${_prescriptionDate!.day}/${_prescriptionDate!.month}/${_prescriptionDate!.year}"
                              : "Select Date",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Icon(Icons.calendar_today, color: Colors.blue),
                      ],
                    ),
                  ),
                ),

                  // Time Picker (Optional).
                if (_prescriptionDate != null) ...[
                  Text("Prescription Time (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => _selectPrescriptionTime(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                      margin: EdgeInsets.only(bottom: 5.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5.w),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _prescriptionTime != null
                                ? "${_prescriptionTime!.hour}:${_prescriptionTime!.minute.toString().padLeft(2, '0')}"
                                : "Select Time (Optional)",
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          Icon(Icons.access_time, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                ],

                  // Checkbox for Indefinite Medication.
                Row(
                  children: [
                    Checkbox(
                      value: _isIndefinite,
                      onChanged: (value) {
                        setState(() {
                          _isIndefinite = value!;
                          //If it is checked, the duration fields are reset.
                          if (_isIndefinite) {
                            _durationUnits = ''; 
                            _durationLength = 0;
                            _durationController.text = ''; // Clears text field.
                          }
                        });
                      },
                    ),
                    Text("Taken Indefinitely"),
                  ],
                ),

                // Duration Units Dropdown (disabled if medication is take indefinitely).
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Duration",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
                  ),

                  // If "Indefinite" is selected, the dropdown is cleared.
                  // If a duration is selected, the dropdown shows the correct value.
                  value: !_isIndefinite && _durationUnits.isNotEmpty ? _durationUnits : null,

                  // Responsible for dropdown options.
                  items: ["Days", "Weeks", "Months", "Years"]
                      .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                      .toList(),

                  // Handles user selection.
                  onChanged: _isIndefinite ? null : (value) {
                    setState(() {
                      _durationUnits = value!;
                    });
                  },
                  validator: (value) {
                    if (!_isIndefinite && (value == null || value.isEmpty)) {
                      return 'Please select a duration unit.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _durationUnits = value ?? '';
                  },

                  // Shows text when disabled.
                  disabledHint: Text("Indefinite"),
                ),

                // Duration Length Field (disabled if medication is take indefinitely).
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Duration Length", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        // Numeric Input Field.
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: InputDecoration(
                              labelText: "Duration Length",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            enabled: !_isIndefinite, // Disables input if indefinite
                            onChanged: (value) {
                              if (!_isIndefinite) {
                                setState(() {
                                  _durationLength = int.tryParse(value) ?? 1;
                                });
                              }
                            },
                            validator: (value) {
                              if (!_isIndefinite && (value == null || value.isEmpty)) {
                                return 'Please enter a duration length';
                              }
                              return null;
                            },
                          ),
                        ),

                        // Up/Down Buttons for Duration Length value.
                        Column(
                          children: [
                            // Increment Button (Up Arrow).
                            IconButton(
                              icon: Icon(Icons.arrow_drop_up, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: _isIndefinite
                                  ? null // Disables button if medication is taken indefinitely.
                                  : () {
                                      int currentValue = int.tryParse(_durationController.text) ?? 1;
                                      currentValue++;
                                      _durationController.text = '$currentValue';
                                      setState(() => _durationLength = currentValue);
                                    },
                            ),

                            // Divider Line Directly Under the Number Input.
                            Container(
                              width: 30,
                              height: 1,
                              color: Colors.grey[400],
                            ),

                            // Decrement Button (Down Arrow).
                            IconButton(
                              icon: Icon(Icons.arrow_drop_down, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: _isIndefinite
                                  ? null // Disables button if medication is taken indefinitely.
                                  : () {
                                      int currentValue = int.tryParse(_durationController.text) ?? 1;
                                      if (currentValue > 1) {
                                        currentValue--;
                                        _durationController.text = '$currentValue';
                                        setState(() => _durationLength = currentValue);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                Text("Schedule type", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height:1.h),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
                    ),
                    value: _scheduleType.isNotEmpty ? _scheduleType : null, 
                    // If `_scheduleType` already has a value, it will be pre-selected.
                    // If `_scheduleType` is empty, the dropdown starts with no selection (null).

                    items: ["daily", "weekly", "monthly"]
                        .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _scheduleType = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a medication schedule type.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _scheduleType = value!;
                    },
                ),

              
                // Frequency Field
                Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                Text("Frequency", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                children: [
                  // Numeric Input Field
                  Expanded(
                    child: TextFormField(
                      controller: _frequencyController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)), 
                        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w), // Compact height
                      ),
                      keyboardType: TextInputType.number,  
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],  
                      onChanged: (value) {
                        setState(() {
                          _frequency = int.tryParse(value) ?? 1;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a frequency';
                        }
                        final n = int.tryParse(value);
                        if (n == null || n < 1) {
                          return 'Frequency must be at least 1';
                        }
                        return null; 
                      },
                    ),
                  ),

                  // Up/Down Buttons Next to Input.
                  Column(
                    children: [
                      // Increment Button (Up Arrow).
                      IconButton(
                        icon: Icon(Icons.arrow_drop_up, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          int currentValue = int.tryParse(_frequencyController.text) ?? 1;
                          currentValue++;
                          _frequencyController.text = '$currentValue';
                          setState(() => _frequency = currentValue);
                        },
                      ),
                      
                      // Divider Line Directly Under the Number Input.
                      Container(
                        width: 30, 
                        height: 1, 
                        color: Colors.grey[400], 
                      ),

                      // Decrement Button (Down Arrow).
                      IconButton(
                        icon: Icon(Icons.arrow_drop_down, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          int currentValue = int.tryParse(_frequencyController.text) ?? 1;
                          if (currentValue > 1) {
                            currentValue--;
                            _frequencyController.text = '$currentValue';
                            setState(() => _frequency = currentValue);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),]),

            // Duration Units
              Text("Dose Units", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height:1.h),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Duration",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
                ),
                value: _doseUnits.isNotEmpty ? _doseUnits : null, // Keeps previous selection
                items: ["drops", "sprays", "mL", "teaspoon", "tablespoon", "pills/tablets"]
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _doseUnits = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a duration unit.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _doseUnits = value!;
                },
              ),

              // Dose Quantity Field.
              Text("Dose Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 1.h),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Enter Dose Quantity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
                  contentPadding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allows only numbers and decimals.
                ],
                onChanged: (value) {
                  setState(() {
                    _doseQuantity = double.tryParse(value) ?? 0.0;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a dose quantity';
                  }
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
                onSaved: (value) {
                  _doseQuantity = double.parse(value!);
                },
              ),


              // If "Eye Medication" is selected, shows extra fields.
              if (_medType == "Eye Medication") ...[
                SizedBox(height: 2.h), // Spacing for better UI

            

                // Affected Eye Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Affected Eye'),
                  value: _applicationSite.isNotEmpty ? _applicationSite : null, // Keeps previous selection
                  items: ["Left", "Right", "Both"]
                      .map((eye) => DropdownMenuItem(value: eye, child: Text(eye)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _applicationSite = value!; // Updates applicationSite when selection changes
                    });
                  },
                  validator: (value) {
                    if (_medType == "Eye Medication" && (value == null || value.isEmpty)) {
                      return 'Please select the affected eye.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _applicationSite = value ?? ''; // Ensures value is stored even if unchanged
                  },
                ),

              ],

            SizedBox(height: 5.h),

            // Submit button.
            ElevatedButton(
                onPressed: _submitForm, // Calls _submitForm function when the button is pressed.
                child: Text('Submit'), 
            ),
            
            

            ],
          ),
        ),
      ),
    )));
  }
}