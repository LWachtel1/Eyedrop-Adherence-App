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
import 'package:sizer/sizer.dart';


/// Screen displaying a user's medications.
class MedicationsScreen extends StatefulWidget {

  // StatefulWidget chosen as it fetches data asynchronously from Firestore & 
  // updates the UI dynamically when users searches through their list of medications.

  @override
  _MedicationsScreenState createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  // Gets the FirestoreService from Provider to allow CRUD operations within class.

  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = []; 

  bool _isLoading = true; // Whether medications data is still loading or not.
  TextEditingController _searchController = TextEditingController(); // Manages user searchbar input.

  @override
  void initState() {
    super.initState();
    _fetchUserMedications(); // Calls _fetchMedications() when the screen loads.

    // Adds a listener to filter results as user types (if they search list instead of scrolling).
     // _filterMedications() is called whenver user types.
    _searchController.addListener(_filterMedications); 


  }

  /// Fetches user medications from FireStore 
  Future<void> _fetchUserMedications() async {
  try {
    // Get FirestoreService instance
    // `listen: false` means this widget won’t rebuild when FirestoreService updates.
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
    return;
    }

    // Fetch medications using FirestoreService's getAllDocs method
    List<Map<String, dynamic>> eyeMeds = await firestoreService.getAllDocs(collectionPath: "users/${user.uid}/eye_medications");
    List<Map<String, dynamic>> nonEyeMeds = await firestoreService.getAllDocs(collectionPath: "users/${user.uid}/noneye_medications");
    List<Map<String, dynamic>> allMeds = eyeMeds + nonEyeMeds;

    setState(() {
      _medications = allMeds;
      _filteredMedications = allMeds; // Initialises with full list of medications.
      _isLoading = false; // Stops loading indicator.
    });
  } catch (e) {
    log("Error fetching medications: $e");
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

          // Displays scrollable medication summary cards.
           // Medication Summary Cards
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredMedications.isEmpty
                    ? Center(child: Text("No medications found"))
                    : ListView.builder(
                        itemCount: _filteredMedications.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> medication = _filteredMedications[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicationDetailScreen(medication: medication),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medication["medicationName"] ?? "Unnamed Medication",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      medication["isEyeMedication"] ? "Eye" : "Non-Eye",
                                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

