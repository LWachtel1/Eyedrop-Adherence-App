import 'dart:developer';
import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/features/medications/widgets/medication_card.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/searchable_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Screen for selecting an eye medication for a reminder
///
/// Displays a list of the user's eye medications and allows selecting one
class EyeMedicationSelectionScreen extends StatefulWidget {
  const EyeMedicationSelectionScreen({Key? key}) : super(key: key);

  @override
  State<EyeMedicationSelectionScreen> createState() => _EyeMedicationSelectionScreenState();
}

class _EyeMedicationSelectionScreenState extends State<EyeMedicationSelectionScreen> {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedMedication;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  /// Loads the user's eye medications from Firestore
  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "Please log in to view your medications";
          _isLoading = false;
        });
        return;
      }

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      
      // Get medication data stream and get first value
      final stream = medicationService.buildMedicationsStream(firestoreService, user.uid);
      
      final medications = await stream.first;
      
      // Filter for only eye medications
      final eyeMedications = medications
          .where((med) => med["medType"] == "Eye Medication")
          .toList();
      
      setState(() {
        _medications = eyeMedications;
        _filteredMedications = _processFilteredMedications(_medications);
        _isLoading = false;
      });
    } catch (e) {
      log("Error loading medications: $e");
      setState(() {
        _errorMessage = "Failed to load medications. Please try again.";
        _isLoading = false;
      });
    }
  }

  /// Filters medications based on search query
  List<Map<String, dynamic>> _processFilteredMedications(
      List<Map<String, dynamic>> sourceMedications) {
    // Currently no filtering, but we could add search later
    return List.from(sourceMedications);
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
            child: Text(
              "Select Medication for Reminder",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Eye medications list
          Expanded(
            child: _buildMainContent(),
          ),

          // Bottom action buttons
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontSize: 15.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedMedication != null
                      ? () => Navigator.pop(context, _selectedMedication)
                      : null,
                  child: Text(
                    "Select",
                    style: TextStyle(fontSize: 15.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main content based on state (loading, error, or medication list)
  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_filteredMedications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 32.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 2.h),
              Text(
                "No eye medications found",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                "Add an eye medication first before creating a reminder",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
      itemCount: _filteredMedications.length,
      itemBuilder: (context, index) {
        final medication = _filteredMedications[index];
        final isSelected = _selectedMedication != null && 
                          _selectedMedication!['id'] == medication['id'];
        
        return _buildMedicationSelectionCard(medication, isSelected);
      },
    );
  }

  /// Builds a custom medication card with selection capability
  Widget _buildMedicationSelectionCard(Map<String, dynamic> medication, bool isSelected) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMedication = null;
            } else {
              _selectedMedication = medication;
            }
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedMedication = medication;
                    } else {
                      _selectedMedication = null;
                    }
                  });
                },
              ),
              SizedBox(width: 2.w),
              
              // Medication info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication["medicationName"] ?? "Unnamed Medication",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 12.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          "Eye Medication",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (medication.containsKey("applicationSite") && 
                        medication["applicationSite"] != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        "Application: ${medication["applicationSite"]}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an error widget with retry option
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32.sp,
              color: Colors.red,
            ),
            SizedBox(height: 2.h),
            Text(
              _errorMessage ?? "An error occurred",
              style: TextStyle(fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _loadMedications,
              icon: Icon(Icons.refresh),
              label: Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}