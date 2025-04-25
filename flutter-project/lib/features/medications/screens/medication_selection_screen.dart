/* 
  TODO:
  - Handle cases where Firestore query fails due to network issues.
  - Implement caching for medications to reduce redundant Firestore reads.
*/

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/searchable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Medication Selection Screen
/// 
/// - Displays a searchable list of common eye medications.
/// - Allows users to either select a medication from Firestore 
/// - Fetches data asynchronously from Firestore when the screen loads.
/// - Implements real-time filtering as users type in the search bar.
class MedicationSelectionScreen extends StatefulWidget {

  // Add a filterByType parameter
  final String? filterByType;

  const MedicationSelectionScreen({Key? key, this.filterByType}) : super(key: key);

  @override
  _MedicationSelectionScreenState createState() => _MedicationSelectionScreenState();
}

class _MedicationSelectionScreenState extends State<MedicationSelectionScreen> {

  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final allMedications = await medicationService.fetchCommonMedications();
      
      // Apply type filter if specified
      if (widget.filterByType != null) {
        setState(() {
          _medications = allMedications.where((med) => 
            med["medType"] == widget.filterByType
          ).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _medications = allMedications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading medications: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Column(
        children: [
          // Add Back Button and Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Go Back",
                ),
                Text(
                  "Select Medication",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 48), // Balance the header
              ],
            ),
          ),
        
          // Rest of the content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _medications.isEmpty
                    ? Center(child: Text("No medications found"))
                    : SearchableList<Map<String, dynamic>>(
                        items: _medications,
                        getSearchString: (med) => med["medicationName"] ?? "",
                        itemBuilder: (med, index) => _buildMedicationItem(med),
                        onSelect: (med) => Navigator.pop(context, med),
                        hintText: "Search medications",
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication) {
    final medName = medication["medicationName"] ?? "Unknown Medication";
    final medType = medication["medType"] ?? "Unknown Type";

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(medName),
        subtitle: Text(medType),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pop(context, medication),
      ),
    );
  }
}
