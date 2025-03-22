/* 
    TO DO:
*/

import 'dart:developer';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/features/medications/screens/medication_details_screen.dart';
import 'package:eyedrop/shared/widgets/delete_confirmation_dialog.dart';
import 'package:eyedrop/shared/widgets/form_components.dart';
import 'package:eyedrop/features/medications/widgets/medication_card.dart';
import 'package:eyedrop/shared/widgets/searchable_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sizer/sizer.dart';

/// A screen that displays a list of medications for the logged-in user.
///
/// This screen provides functionalities such as:
/// - Real-time Firestore Syncing: Retrieves medication data dynamically.
/// - Filtering and Sorting: Allows users to filter by medication type and sort alphabetically.
/// - Searchable List: Users can search for medications by name.
/// - Delete Confirmation: Users must confirm before deleting a medication.
/// - Navigation to Details: Tapping on a medication opens its detail screen.
///
/// Features
/// - Uses `StreamBuilder` to update the list in real-time.
/// - Filters and sorts medications based on user input.
/// - Displays a `SearchableList` of `MedicationCard` widgets.
/// - Integrates a `DeleteConfirmationDialog` for safe deletion.
class MedicationsScreen extends StatefulWidget {
  static const String id = '/medications';
  
  @override
  _MedicationsScreenState createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  late MedicationService medicationService;
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];

  TextEditingController _searchController = TextEditingController();

  String _sortFilterOption = "Show All"; // Default option

  @override
  void initState() {
    super.initState();

    medicationService = Provider.of<MedicationService>(context, listen: false);
    // Instead of attaching listener that calls setState, we'll rely on the stream
    _searchController.addListener(() {
      setState(() {
        // Just trigger a rebuild, filtering happens in build
      });
    });
  }

  /// Filters and sorts the medications based on search query and selected options.
  ///
  /// - Search Query: Filters medications containing the query in their name.
  /// - Filtering Options: Allows filtering by medication type (Eye/Non-Eye).
  /// - Sorting Options: Allows sorting alphabetically (A-Z, Z-A).
  ///
  /// Parameters:
  /// - `sourceMedications`: List of medications to process.
  ///
  /// Returns:
  /// - A new filtered and sorted list of medications.
  List<Map<String, dynamic>> _processFilteredMedications(List<Map<String, dynamic>> sourceMedications) {
    String query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> tempList = sourceMedications.where((med) {
      String name = (med["medicationName"] ?? "").toLowerCase();
      return name.contains(query);
    }).toList();
    
    // Apply filtering
    if (_sortFilterOption == "Show Only Eye Medications") {
      tempList = tempList.where((med) => med["medType"] == "Eye Medication").toList();
      // tempList = tempList.where((med) => med["isEyeMedication"] == true).toList();
    } else if (_sortFilterOption == "Show Only Non-Eye Medications") {
          tempList = tempList.where((med) => med["medType"] != "Eye Medication").toList();
          // tempList = tempList.where((med) => med["isEyeMedication"] == false).toList();
    }

    // Apply sorting
    if (_sortFilterOption == "Sort A-Z") {
      tempList.sort((a, b) => (a["medicationName"] ?? "").compareTo(b["medicationName"] ?? ""));
    } else if (_sortFilterOption == "Sort Z-A") {
      tempList.sort((a, b) => (b["medicationName"] ?? "").compareTo(a["medicationName"] ?? ""));
    }
    
    return tempList;
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Handles deletion of a medication and its associated reminders
  void _handleMedicationDelete(Map<String, dynamic> medication) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        medicationName: medication["medicationName"] ?? "Unnamed Medication",
        isReminder: false, // This is a medication deletion
        onConfirm: () async {
          // Close the confirmation dialog first
          Navigator.of(context).pop();
          
          // Show loading indicator at the bottom of the screen with a reasonable duration
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text("Deleting medication..."),
                ],
              ),
              duration: Duration(seconds: 10), // More reasonable duration
              backgroundColor: Colors.blue[700],
            ),
          );
          
          try {
            // Delete the medication (which may take time for network operations)
            await medicationService.deleteMedication(medication);
            
            // Hide current SnackBar and show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Medication and associated reminders deleted successfully"),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            // Hide current SnackBar and show error message
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed to delete medication: $e"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Displays the list of medications with sorting and filtering options.
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;
    
    return BaseLayoutScreen(
      child: Column(
        children: [
          
          // Sorting & Filtering Dropdown
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
            child: FormComponents.buildDropdown(
              label: "Filter/Sort",
              value: _sortFilterOption,
              items: [
                "Show All",
                "Show Only Eye Medications",
                "Show Only Non-Eye Medications",
                "Sort A-Z",
                "Sort Z-A",
              ],
              onChanged: (value) {
                setState(() {
                  _sortFilterOption = value!;
                });
              },
            ),
          ),

          // Medication List with StreamBuilder
          Expanded(
            child: user == null
                ? Center(child: Text("Please log in"))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: medicationService.buildMedicationsStream(firestoreService, user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && _medications.isEmpty) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                    if (snapshot.hasData) {
                      _medications = snapshot.data!;
                      _filteredMedications = _processFilteredMedications(_medications);
                    }
                      
                      if (_filteredMedications.isEmpty) {
                        return Center(child: Text("No medications found"));
                      }
                      
                      return SearchableList<Map<String, dynamic>>(
                        items: _filteredMedications,
                        getSearchString: (med) => med["medicationName"] ?? "Unnamed Medication",
                        itemBuilder: (med, index) => MedicationCard(
                          medication: med,
                          onDelete: _handleMedicationDelete, // Use our new method
                          onTap: (medication) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationDetailScreen(medication: medication),
                            ),
                          ),
                        ),
                        onSelect: (medication) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationDetailScreen(medication: medication),
                            ),
                          );
                        },
                        hintText: "Search Medications",
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

}