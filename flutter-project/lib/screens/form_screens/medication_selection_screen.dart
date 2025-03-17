/* 
  TODO:
  - Handle cases where Firestore query fails due to network issues.
  - Implement caching for medications to reduce redundant Firestore reads.
*/

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:eyedrop/logic/medications/medication_service.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:eyedrop/widgets/searchable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Medication Selection Screen
/// 
/// - Displays a searchable list of common eye medications.
/// - Allows users to either select a medication from Firestore 
/// - Fetches data asynchronously from Firestore when the screen loads.
/// - Implements real-time filtering as users type in the search bar.
class MedicationSelectionScreen extends StatefulWidget {

  // StatefulWidget chosen as it fetches data asynchronously from Firestore & 
  // updates the UI dynamically when users search for medications.

  @override
  _MedicationSelectionScreenState createState() => _MedicationSelectionScreenState();
}

class _MedicationSelectionScreenState extends State<MedicationSelectionScreen> {

  /// Tracks if an error has occurred during FireStore retrieval.
  String? _errorMessage;

  // List of all medications fetched from Firestore. 
  List<String> _medicationNames = [];

  bool _isLoading = true; // Whether medications data is still loading or not.

  @override
  void initState() {
    super.initState();
    _fetchMedications(); // Calls _fetchMedications() when the screen loads.

  }


  /*
  Future<void> _fetchMedications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message when retrying.
    });

    try {
      // Get FirestoreService instance
      // `listen: false` means this widget won’t rebuild when FirestoreService updates.
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // Fetch medications using FirestoreService's getAllDocs method
      List<Map<String, dynamic>> meds = await firestoreService.getAllDocs(collectionPath: "medications");

      // Handles empty medications list case.
      if (meds.isEmpty) {
          throw Exception("No medications found in the database.");
        }

      setState(() {
         _medicationNames = meds.map((med) => med["medicationName"] as String? ?? "").toList(); // Initialises with full list of medications.
        _isLoading = false; // Stops loading indicator.
      });
    } on FirebaseException catch (e) {
        log("Firestore error: ${e.message}");
        setState(() {
        _errorMessage = "Failed to fetch medications. Please check your network."; // Stops loading on error.
        _isLoading = false;
      });

    } catch (e) {
        log("Unexpected error fetching medications: $e");
        setState(() {
        _errorMessage = "Something went wrong. Please try again later.";
        _isLoading = false;
      });

    }

  } */
 
  /// Fetches medications using `MedicationService`.
  Future<void> _fetchMedications() async {
    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      List<Map<String, dynamic>> meds = await medicationService.fetchCommonMedications();

      setState(() {
        _medicationNames = meds.map((med) => med["medicationName"] as String? ?? "").toList(); // Initialises with full list of medications.
        _isLoading = false;
      });
    } catch (e) {
      log("Error fetching medications: $e");
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }


  /// Builds the medication selection UI.
  ///
  /// Displays:
  /// - Back button for navigation.
  /// - Search bar for filtering medications.
  /// - List of medications, dynamically updating based on search.
  /// 
  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Column(
        children: [

          // Back Button.
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4.w, top: 2.h),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: 24.sp),
                onPressed: () {
                  Navigator.pop(context); // Simply returns to the previous screen with no selection.
                },
              ),
            ),
          ),

        
          // Main content area - shows either loading, error, or the searchbar & searchable list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator()) // Shows loading spinner.
                : _errorMessage != null
                    ? _buildErrorWidget() // Shows error message.
                : _medicationNames.isEmpty
                    ? Center(child: Text("No medications found"))
                 : SearchableList( // Provides search bar and searchable list.
                      items: _medicationNames,
                      hintText: "Search Medications",
                      onSelect: (selectedMedication) {
                        Navigator.pop(context, selectedMedication); // Returns selection to form.
                      },
                    ),
          ),
        ],
      ),
    );
  }

  /// Displays an error message with a retry button.
  Widget _buildErrorWidget() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
            SizedBox(height: 1.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16.sp),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchMedications,
                  child: Text("Retry"),
                ),
                SizedBox(width: 2.w),
                //Back button.
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back"),
                ),
              ],
            ),
          ],
        ),
      );
  }
  

  

}
