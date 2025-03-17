/* 
    TO DO:
*/

import 'dart:developer';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:eyedrop/screens/main_screens/medications/medication_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sizer/sizer.dart';

/// Screen displaying a user's medications.
class MedicationsScreen extends StatefulWidget {
  @override
  _MedicationsScreenState createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];

  TextEditingController _searchController = TextEditingController();

  String _sortFilterOption = "Show All"; // Default option

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterMedications);
  }



  /// Deletes a medication from Firestore.
  Future<void> _deleteMedication(Map<String, dynamic> medication) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Determine collection path
      String collectionPath = medication["isEyeMedication"] == true
          ? "users/${user.uid}/eye_medications"
          : "users/${user.uid}/noneye_medications";

      // Ensure the document has an ID before trying to delete
      if (!medication.containsKey("id") || medication["id"] == null) {
        log("Error: Medication does not have an ID.");
        return;
      }

      await firestoreService.deleteDoc(collectionPath: collectionPath, docId: medication["id"]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Medication deleted successfully.")),
      );
    } catch (e) {
      log("Error deleting medication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting medication.")),
      );
    }
  }

  /// Shows a confirmation dialog before deleting a medication.
  void _showDeleteConfirmationDialog(BuildContext context, Map<String, dynamic> medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Medication?"),
        content: Text("Are you sure you want to delete ${medication["medicationName"]}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel deletion
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _deleteMedication(medication);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  /// Filters and sorts medications based on search query.
  void _filterMedications() {
    String query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> tempList = _medications.where((med) {
      String name = (med["medicationName"] ?? "").toLowerCase();
      return name.contains(query);
    }).toList();
    
    // Apply filtering
    if (_sortFilterOption == "Show Only Eye Medications") {
      tempList = tempList.where((med) => med["isEyeMedication"] == true).toList();
    } else if (_sortFilterOption == "Show Only Non-Eye Medications") {
      tempList = tempList.where((med) => med["isEyeMedication"] == false).toList();
    }

    // Apply sorting
    if (_sortFilterOption == "Sort A-Z") {
      tempList.sort((a, b) => (a["medicationName"] ?? "").compareTo(b["medicationName"] ?? ""));
    } else if (_sortFilterOption == "Sort Z-A") {
      tempList.sort((a, b) => (b["medicationName"] ?? "").compareTo(a["medicationName"] ?? ""));
    }
    
    setState(() {
      _filteredMedications = tempList;
    });
  }
  

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

/// Displays the list of medications with sorting and filtering options.
@override
Widget build(BuildContext context) {
  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
  User? user = FirebaseAuth.instance.currentUser;
  
  return BaseLayoutScreen(
    child: Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(5.w),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Search Medications",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
            ),
          ),
        ),

        // Sorting & Filtering Dropdown
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: DropdownButtonFormField<String>(
            value: _sortFilterOption,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
            ),
            items: [
              "Show All",
              "Show Only Eye Medications",
              "Show Only Non-Eye Medications",
              "Sort A-Z",
              "Sort Z-A",
            ].map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
            onChanged: (value) {
              setState(() {
                _sortFilterOption = value!;
                _filterMedications();
              });
            },
          ),
        ),

        SizedBox(height: 2.h),

        // Medication List with StreamBuilder
        Expanded(
          child: user == null
              ? Center(child: Text("Please log in"))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _buildMedicationsStream(firestoreService, user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _medications.isEmpty) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    // Process data WITHOUT setState
                    if (snapshot.hasData) {
                      // Update local data without setState
                      _medications = snapshot.data!;
                      // Apply filtering without setState
                      _updateFilteredMedicationsWithoutSetState();
                    }
                    
                    if (_filteredMedications.isEmpty) {
                      return Center(child: Text("No medications found"));
                    }
                    
                    return ListView.builder(
                      itemCount: _filteredMedications.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> medication = _filteredMedications[index];
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
                              medication["isEyeMedication"] == true ? "Eye" : "Non-Eye",
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(context, medication),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationDetailScreen(medication: medication),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

// New method that filters without calling setState
void _updateFilteredMedicationsWithoutSetState() {
  String query = _searchController.text.toLowerCase();
  List<Map<String, dynamic>> tempList = _medications.where((med) {
    String name = (med["medicationName"] ?? "").toLowerCase();
    return name.contains(query);
  }).toList();
  
  // Apply filtering
  if (_sortFilterOption == "Show Only Eye Medications") {
    tempList = tempList.where((med) => med["isEyeMedication"] == true).toList();
  } else if (_sortFilterOption == "Show Only Non-Eye Medications") {
    tempList = tempList.where((med) => med["isEyeMedication"] == false).toList();
  }

  // Apply sorting
  if (_sortFilterOption == "Sort A-Z") {
    tempList.sort((a, b) => (a["medicationName"] ?? "").compareTo(b["medicationName"] ?? ""));
  } else if (_sortFilterOption == "Sort Z-A") {
    tempList.sort((a, b) => (b["medicationName"] ?? "").compareTo(a["medicationName"] ?? ""));
  }
  
  // Direct assignment instead of setState
  _filteredMedications = tempList;
}
  // Create a stream that combines both eye and non-eye medications
  Stream<List<Map<String, dynamic>>> _buildMedicationsStream(FirestoreService firestoreService, String userId) {
    Stream<List<Map<String, dynamic>>> eyeStream = 
        firestoreService.getCollectionStream("users/$userId/eye_medications");
    Stream<List<Map<String, dynamic>>> nonEyeStream = 
        firestoreService.getCollectionStream("users/$userId/noneye_medications");
        
    return _combineStreams(eyeStream, nonEyeStream);
  }
  
  // Helper method to combine two streams
  Stream<List<Map<String, dynamic>>> _combineStreams(
      Stream<List<Map<String, dynamic>>> stream1, 
      Stream<List<Map<String, dynamic>>> stream2) {
    return Rx.combineLatest2(
      stream1, 
      stream2,
      (List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
        return [...list1, ...list2];
      }
    );
  }

}