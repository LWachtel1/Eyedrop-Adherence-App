import 'package:eyedrop/features/reviews/controllers/reviews_controller.dart';
import 'package:eyedrop/features/reviews/screens/create_review_screen.dart';
import 'package:eyedrop/features/reviews/widgets/review_card.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/searchable_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class MedicationReviewsScreen extends StatefulWidget {
  final Map<String, dynamic> medication;

  const MedicationReviewsScreen({
    Key? key,
    required this.medication,
  }) : super(key: key);

  @override
  _MedicationReviewsScreenState createState() => _MedicationReviewsScreenState();
}

class _MedicationReviewsScreenState extends State<MedicationReviewsScreen> {
  late ReviewsController _reviewsController;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String _filterOption = "No Filter";

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _reviewsController = ReviewsController(firestoreService: firestoreService);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviews = await _reviewsController.getMedicationReviews(widget.medication["id"]);
      setState(() {
        _reviews = _applyFilter(reviews);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading reviews: $e"))
        );
      }
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> reviews) {
    switch (_filterOption) {
      case "Highest Rated":
        return List.from(reviews)..sort((a, b) => (b["rating"] as num).compareTo(a["rating"] as num));
      case "Lowest Rated":
        return List.from(reviews)..sort((a, b) => (a["rating"] as num).compareTo(b["rating"] as num));
      default:
        return reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final medName = widget.medication["medicationName"] ?? "Unknown Medication";
    final reviewCount = widget.medication["reviewCount"] ?? 0;
    final averageRating = widget.medication["averageRating"] ?? 0.0;

    return BaseLayoutScreen(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        medName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "($reviewCount reviews)",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Dropdown
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Sort Reviews",
                border: OutlineInputBorder(),
              ),
              value: _filterOption,
              items: [
                "No Filter",
                "Highest Rated",
                "Lowest Rated",
              ].map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _filterOption = value!;
                  _reviews = _applyFilter(_reviews);
                });
              },
            ),
          ),

          SizedBox(height: 16),

          // Reviews List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? Center(child: Text("No reviews yet"))
                    : SearchableList<Map<String, dynamic>>(
                        items: _reviews,
                        getSearchString: (review) => review["reviewText"] ?? "",
                        itemBuilder: (review, index) => ReviewCard(
                          review: review,
                          isUserReview: user?.uid == review["userId"],
                          onEdit: (review) => _navigateToEditReview(review),
                          onDelete: (review) => _showDeleteConfirmation(review),
                        ),
                        onSelect: (review) {
                          if (user?.uid == review["userId"]) {
                            _navigateToEditReview(review);
                          }
                        },
                        hintText: "Search reviews",
                      ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditReview(Map<String, dynamic> review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(existingReview: review),
      ),
    ).then((_) => _loadReviews());
  }

  void _showDeleteConfirmation(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Review"),
        content: Text("Are you sure you want to delete this review?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reviewsController.deleteReview(review);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Review deleted successfully")),
                  );
                }
                _loadReviews();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete review: $e")),
                  );
                }
              }
            },
            child: Text("Delete"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
} 