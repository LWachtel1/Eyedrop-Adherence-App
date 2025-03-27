import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/searchable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Common Medication Selection Screen specifically for reviews
/// 
/// This screen displays medications from the common medications collection
/// and allows filtering by medication type (e.g., Eye Medication only)
class CommonMedicationSelectionScreen extends StatefulWidget {
  final String? filterByType;

  const CommonMedicationSelectionScreen({Key? key, this.filterByType}) : super(key: key);

  @override
  _CommonMedicationSelectionScreenState createState() => _CommonMedicationSelectionScreenState();
}

class _CommonMedicationSelectionScreenState extends State<CommonMedicationSelectionScreen> {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // First try to get medications from the common collection
      List<Map<String, dynamic>> commonMeds = await firestoreService.getAllDocsWithIds(
        collectionPath: "medications",
      );

      // Apply type filter if specified
      if (widget.filterByType != null) {
        commonMeds = commonMeds.where((med) => 
          med["medType"] == widget.filterByType
        ).toList();
      }
      
      setState(() {
        _medications = commonMeds;
        _filteredMedications = commonMeds;
        _isLoading = false;
      });
    } catch (e) {
      log("Error loading medications: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMedications(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMedications = _medications;
      } else {
        _filteredMedications = _medications.where((med) {
          final name = med["medicationName"]?.toString().toLowerCase() ?? "";
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _addCustomMedication() {
    if (_searchQuery.trim().isEmpty) return;
    
    Navigator.pop(context, {
      "medicationName": _searchQuery.trim(),
      "medType": "Eye Medication"
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Column(
        children: [
          // Add Back Button and Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Go Back",
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Select Eye Medication",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 48), // Balance the header
              ],
            ),
          ),
          
          // Search input
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search medications or enter a new one",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  tooltip: "Add custom medication",
                  onPressed: _addCustomMedication,
                ),
              ),
              onChanged: _filterMedications,
            ),
          ),
          
          // Help text for custom medications
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Can't find your medication? Type it and tap the + icon to add a custom one.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.sp,
              ),
            ),
          ),
        
          // Medication list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredMedications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("No medications found."),
                            if (_searchQuery.isNotEmpty) ...[
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _addCustomMedication,
                                icon: Icon(Icons.add),
                                label: Text("Add \"${_searchQuery.trim()}\""),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMedications.length,
                        itemBuilder: (context, index) => 
                          _buildMedicationItem(_filteredMedications[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication) {
    final medName = medication["medicationName"] ?? "Unknown Medication";

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        title: Text(medName),
        subtitle: Text("Eye Medication"),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pop(context, medication),
      ),
    );
  }
}