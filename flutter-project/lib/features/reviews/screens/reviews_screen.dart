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

class ReviewsScreen extends StatefulWidget {
  static const String id = '/reviews';

  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReviewsController _reviewsController;
  String _filterOption = "All Medications";
  
  // Add stream variables
  late Stream<List<Map<String, dynamic>>> _allReviewsStream;
  Stream<List<Map<String, dynamic>>>? _userReviewsStream;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _reviewsController = ReviewsController(firestoreService: firestoreService);
    
    // Initialize streams
    _allReviewsStream = _reviewsController.getAllReviewsStream();
    
    // Initialize user reviews stream if user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userReviewsStream = _reviewsController.getUserReviewsStream(user.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    
    return BaseLayoutScreen(
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: "My Reviews"),
              Tab(text: "All Reviews"),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          
          // Filter Dropdown
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Filter Reviews",
                border: OutlineInputBorder(),
              ),
              value: _filterOption,
              items: [
                "All Medications",
                "Highest Rated",
                "Lowest Rated",
                "Most Recent"
              ].map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _filterOption = value!;
                });
              },
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Reviews Tab
                _buildMyReviewsTab(user),
                
                // All Reviews Tab
                _buildAllReviewsTab(user),
              ],
            ),
          ),
          
          // Add Review Button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateReviewScreen(),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text("Write an Eye Medication Review"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReviewsTab(User? user) {
    if (user == null) {
      return Center(child: Text("Please log in to view your reviews"));
    }

    // Initialize user stream if it wasn't initialized in initState
    if (_userReviewsStream == null) {
      _userReviewsStream = _reviewsController.getUserReviewsStream(user.uid);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userReviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading reviews: ${snapshot.error}"));
        }

        final reviews = snapshot.data ?? [];

        // Apply filtering
        final filteredReviews = _applyFilter(reviews);

        if (filteredReviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("You haven't written any reviews yet."),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateReviewScreen(),
                      ),
                    );
                  },
                  child: Text("Write Your First Review"),
                ),
              ],
            ),
          );
        }

        return SearchableList<Map<String, dynamic>>(
          items: filteredReviews,
          getSearchString: (review) => review["medicationName"] ?? "",
          itemBuilder: (review, index) => ReviewCard(
            review: review,
            isUserReview: true,
            onEdit: (review) => _navigateToEditReview(review),
            onDelete: (review) => _showDeleteConfirmation(review),
          ),
          onSelect: (review) => _navigateToEditReview(review),
          hintText: "Search your reviews",
        );
      },
    );
  }

  Widget _buildAllReviewsTab(User? user) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _allReviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading reviews: ${snapshot.error}"));
        }

        final reviews = snapshot.data ?? [];
        
        // Apply filtering
        final filteredReviews = _applyFilter(reviews);

        if (filteredReviews.isEmpty) {
          return Center(child: Text("No reviews found"));
        }

        return SearchableList<Map<String, dynamic>>(
          items: filteredReviews,
          getSearchString: (review) => review["medicationName"] ?? "",
          itemBuilder: (review, index) => ReviewCard(
            review: review,
            isUserReview: user != null && review["userId"] == user.uid,
            onEdit: (review) => _navigateToEditReview(review),
            onDelete: (review) => _showDeleteConfirmation(review),
          ),
          onSelect: (review) {
            if (user != null && review["userId"] == user.uid) {
              _navigateToEditReview(review);
            }
          },
          hintText: "Search reviews",
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> reviews) {
    switch (_filterOption) {
      case "Highest Rated":
        return List.from(reviews)..sort((a, b) => (b["rating"] as num).compareTo(a["rating"] as num));
      case "Lowest Rated":
        return List.from(reviews)..sort((a, b) => (a["rating"] as num).compareTo(b["rating"] as num));
      case "Most Recent":
        return List.from(reviews)..sort((a, b) {
          final aTime = a["createdAt"] as DateTime? ?? DateTime.now();
          final bTime = b["createdAt"] as DateTime? ?? DateTime.now();
          return bTime.compareTo(aTime);
        });
      default:
        return reviews;
    }
  }

  void _navigateToEditReview(Map<String, dynamic> review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(existingReview: review),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Review"),
        content: Text("Are you sure you want to delete this review for ${review['medicationName']}?"),
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
