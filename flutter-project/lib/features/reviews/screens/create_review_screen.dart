import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/reviews/screens/common_medication_selection_screen.dart';
import 'package:eyedrop/features/reviews/controllers/reviews_controller.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/form_components.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class CreateReviewScreen extends StatefulWidget {
  final Map<String, dynamic>? existingReview;

  const CreateReviewScreen({Key? key, this.existingReview}) : super(key: key);

  @override
  _CreateReviewScreenState createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late ReviewsController _reviewsController;
  double _rating = 3.0;
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Form controllers
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _reviewTextController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _doseQuantityController = TextEditingController(text: "1.0");
  
  // Form values
  String _medType = "Eye Medication"; // Only allow Eye Medication
  String _applicationSite = "Both";
  String _scheduleType = "daily";
  String _doseUnits = "drops";
  bool _recommend = true;
  List<String> _pros = [""];
  List<String> _cons = [""];
  String? _medicationId;

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _reviewsController = ReviewsController(firestoreService: firestoreService);
    
    // If we're editing an existing review, load its data
    if (widget.existingReview != null) {
      _isEditing = true;
      _loadExistingReview();
    }
  }

  void _loadExistingReview() {
    final review = widget.existingReview!;
    
    _medicationNameController.text = review["medicationName"] ?? "";
    _reviewTextController.text = review["reviewText"] ?? "";
    _durationController.text = review["durationUsed"] ?? "";
    _doseQuantityController.text = review["doseQuantity"] ?? "1.0";
    
    _rating = (review["rating"] as num?)?.toDouble() ?? 3.0;
    _medType = review["medType"] ?? "Eye Medication";
    _applicationSite = review["applicationSite"] ?? "Both";
    _scheduleType = review["scheduleType"] ?? "daily";
    _doseUnits = review["doseUnits"] ?? "drops";
    _recommend = review["recommend"] ?? true;
    _medicationId = review["medicationId"];
    
    _pros = List<String>.from(review["pros"] ?? [""]);
    if (_pros.isEmpty) _pros.add("");
    
    _cons = List<String>.from(review["cons"] ?? [""]);
    if (_cons.isEmpty) _cons.add("");
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _reviewTextController.dispose();
    _durationController.dispose();
    _doseQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // App Bar with Back Button
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
                    _isEditing ? "Edit Review" : "Create Review",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 48), // Balance the header
                ],
              ),
            ),
            
            // Form Content in Scrollable Area
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Medication Selection
                  FormComponents.buildTextField(
                    label: "Medication Name",
                    controller: _medicationNameController,
                    validator: (val) => val!.isEmpty ? "Please enter a medication name" : null,
                    icon: Icons.search,
                    onTapIcon: () => _selectMedication(),
                  ),
                  SizedBox(height: 16),
                  
                  // Remove Medication Type Toggle - Only Eye Medication allowed
                  
                  // Rating
                  _buildRatingSelector(),
                  SizedBox(height: 16),
                  
                  // ...existing fields...
                  
                  // Review Text
                  FormComponents.buildTextField(
                    label: "Review",
                    controller: _reviewTextController,
                    validator: (val) => val!.isEmpty ? "Please write a review" : null,
                    maxLines: 4,
                    hintText: "Share your experience with this medication...",
                  ),
                  SizedBox(height: 16),
                  
                  // Pros
                  Text("Pros:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ..._buildProsWidgets(),
                  
                  // Cons
                  SizedBox(height: 16),
                  Text("Cons:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ..._buildConsWidgets(),
                  
                  // Would Recommend
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text("Would Recommend"),
                    value: _recommend,
                    onChanged: (value) {
                      setState(() {
                        _recommend = value;
                      });
                    },
                  ),
                  
                  // Experience Details Section
                  SizedBox(height: 16),
                  Text("Usage Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  
                  // Duration Used
                  FormComponents.buildTextField(
                    label: "Duration Used",
                    controller: _durationController,
                    hintText: "e.g., 2 Weeks, 3 Months",
                    validator: (val) => null, // Make this field optional
                  ),
                  SizedBox(height: 16),
                  
                  // Schedule Type
                  FormComponents.buildDropdown(
                    label: "Schedule Type",
                    value: _scheduleType,
                    items: ["daily", "weekly", "monthly"],
                    onChanged: (value) {
                      setState(() {
                        _scheduleType = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Application Site (always show for Eye Medications)
                  FormComponents.buildDropdown(
                    label: "Application Site",
                    value: _applicationSite,
                    items: ["Left", "Right", "Both"],
                    onChanged: (value) {
                      setState(() {
                        _applicationSite = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Dose Quantity and Units
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FormComponents.buildNumericStepperField(
                          label: "Dose Quantity",
                          controller: _doseQuantityController,
                          isEnabled: true,
                          step: 0.1,
                          minValue: 0.1,
                          allowDecimals: true,
                          onIncrement: () {
                            double val = double.tryParse(_doseQuantityController.text) ?? 1.0;
                            _doseQuantityController.text = (val + 0.1).toStringAsFixed(1);
                          },
                          onDecrement: () {
                            double val = double.tryParse(_doseQuantityController.text) ?? 1.0;
                            if (val > 0.1) {
                              _doseQuantityController.text = (val - 0.1).toStringAsFixed(1);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: FormComponents.buildDropdown(
                          label: "Dose Units",
                          value: _doseUnits,
                          items: ["drops", "sprays", "mL", "teaspoon", "tablespoon", "pills/tablets"],
                          onChanged: (value) {
                            setState(() {
                              _doseUnits = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitReview,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(_isEditing ? "Update Review" : "Submit Review"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  
                  // Cancel Button
                  SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Remove _buildMedicationTypeToggle() method as we only allow Eye Medication

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Rating", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${_rating.toStringAsFixed(1)} / 5.0"),
            Expanded(
              child: Slider(
                value: _rating,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  _rating >= (index + 1) ? Icons.star : 
                  (_rating > index ? Icons.star_half : Icons.star_border),
                  color: Colors.amber,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildProsWidgets() {
    List<Widget> widgets = [];
    
    for (int i = 0; i < _pros.length; i++) {
      widgets.add(
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _pros[i],
                decoration: InputDecoration(
                  hintText: "Add a pro",
                ),
                onChanged: (value) {
                  _pros[i] = value;
                },
              ),
            ),
            IconButton(
              icon: Icon(i == _pros.length - 1 ? Icons.add : Icons.remove),
              onPressed: () {
                setState(() {
                  if (i == _pros.length - 1) {
                    _pros.add("");
                  } else {
                    _pros.removeAt(i);
                  }
                });
              },
            ),
          ],
        ),
      );
    }
    
    return widgets;
  }

  List<Widget> _buildConsWidgets() {
    List<Widget> widgets = [];
    
    for (int i = 0; i < _cons.length; i++) {
      widgets.add(
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _cons[i],
                decoration: InputDecoration(
                  hintText: "Add a con",
                ),
                onChanged: (value) {
                  _cons[i] = value;
                },
              ),
            ),
            IconButton(
              icon: Icon(i == _cons.length - 1 ? Icons.add : Icons.remove),
              onPressed: () {
                setState(() {
                  if (i == _cons.length - 1) {
                    _cons.add("");
                  } else {
                    _cons.removeAt(i);
                  }
                });
              },
            ),
          ],
        ),
      );
    }
    
    return widgets;
  }

  Future<void> _selectMedication() async {
  try {
    final selectedMedication = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommonMedicationSelectionScreen(
        // Only show eye medications
        filterByType: "Eye Medication",
      )),
    );

    if (selectedMedication != null) {
      setState(() {
        // Handle both cases: a full medication object or just a string
        if (selectedMedication is Map) {
          _medicationNameController.text = selectedMedication["medicationName"] ?? "";
          if (selectedMedication["id"] != null) {
            _medicationId = selectedMedication["id"];
          }
        } else {
          _medicationNameController.text = selectedMedication.toString();
          _medicationId = null; // Clear medication ID if just using text
        }
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to select medication: $e")),
    );
  }
}

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be logged in to submit a review")),
      );
      return;
    }
    
    // Clean up the pros and cons lists by removing empty entries
    final cleanPros = _pros.where((pro) => pro.trim().isNotEmpty).toList();
    final cleanCons = _cons.where((con) => con.trim().isNotEmpty).toList();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final reviewData = {
        "userId": user.uid,
        "medicationId": _medicationId, // May be null if manually entered
        "medicationName": _medicationNameController.text.trim(),
        "medType": "Eye Medication", // Always set to Eye Medication
        "rating": _rating,
        "reviewText": _reviewTextController.text.trim(),
        "pros": cleanPros,
        "cons": cleanCons,
        "recommend": _recommend,
        "applicationSite": _applicationSite,
        "durationUsed": _durationController.text.trim(),
        "scheduleType": _scheduleType,
        "doseQuantity": _doseQuantityController.text,
        "doseUnits": _doseUnits,
      };
      
      if (_isEditing && widget.existingReview != null) {
        // Update existing review
        await _reviewsController.updateReview(
          widget.existingReview!["id"],
          reviewData,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Review updated successfully")),
        );
      } else {
        // Add timestamp for new reviews
        reviewData["createdAt"] = Timestamp.now();
        
        // Create new review
        await _reviewsController.createReview(reviewData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Review submitted successfully")),
        );
      }
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
