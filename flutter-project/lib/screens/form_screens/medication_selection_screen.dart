/* 
  TO DO:
*/

import 'package:eyedrop/logic/database/firestore_service.dart';
import 'package:eyedrop/screens/main_screens/base_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Screen displaying common eye medications a user can select and search 
/// instead of entering completely manually.
class MedicationSelectionScreen extends StatefulWidget {

  // StatefulWidget chosen as it fetches data asynchronously from Firestore & 
  // updates the UI dynamically when users search for medications.

  @override
  _MedicationSelectionScreenState createState() => _MedicationSelectionScreenState();
}

class _MedicationSelectionScreenState extends State<MedicationSelectionScreen> {
  // Gets the FirestoreService from Provider to allow CRUD operations within class.

  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = []; 

  bool _isLoading = true; // Whether medications data is still loading or not.
  TextEditingController _searchController = TextEditingController(); // Manages user searchbar input.

  @override
  void initState() {
    super.initState();
    _fetchMedications(); // Calls _fetchMedications() when the screen loads.

    // Adds a listener to filter results as user types (if they search list instead of scrolling).
     // _filterMedications() is called whenver user types.
    _searchController.addListener(_filterMedications); 


  }

  /// Fetches medications from FireStore 'medications' collection.
  Future<void> _fetchMedications() async {
  try {
    // Get FirestoreService instance
    // `listen: false` means this widget won’t rebuild when FirestoreService updates.
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // Fetch medications using FirestoreService's getAllDocs method
    List<Map<String, dynamic>> meds = await firestoreService.getAllDocs(collectionPath: "medications");

    setState(() {
      _medications = meds;
      _filteredMedications = meds; // Initialises with full list of medications.
      _isLoading = false; // Stops loading indicator.
    });
  } catch (e) {
    print("Error fetching medications: $e");
    setState(() => _isLoading = false); // Stops loading on error.
  }

}

  /// Filters the medication list based on the search query.
  void _filterMedications() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMedications = _medications.where((med) {
        String name = (med["medicationName"] ?? "").toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Prevents memory leaks from the TextEditingController.
    super.dispose();
  }

  /// Displays a scrollable list of the retrieved medications with a search bar for filtering. 
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

          // Provides search bar.
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

          // Displays scrollable medication list.
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator()) // Shows loading spinner.
                : _filteredMedications.isEmpty
                    ? Center(child: Text("No medications found"))
                    : ListView.builder(
                        itemCount: _filteredMedications.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> medication = _filteredMedications[index];
                          return ListTile(
                            title: Text(medication["medicationName"] ?? "Unnamed Medication"
                            , style: TextStyle(fontWeight: FontWeight.bold, fontSize:18.sp)),
                            onTap: () {
                              Navigator.pop(context, medication["medicationName"]); // Returns selection to form.
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
