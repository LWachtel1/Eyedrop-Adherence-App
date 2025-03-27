import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Replace streams with lists to store data
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _userReviews = [];
  bool _isLoadingAll = true;
  bool _isLoadingUser = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _reviewsController = ReviewsController(firestoreService: firestoreService);
    
    // Add listener to tab controller to refresh data when tab changes
    _tabController.addListener(_handleTabChange);
    
    // Initial data load
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    // If tab selection actually changed, refresh the data
    if (_tabController.indexIsChanging || _tabController.animation!.value == _tabController.index) {
      _loadReviews();
    }
  }
  
  // Load both all reviews and user reviews
  Future<void> _loadReviews() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    // Set loading states
    setState(() {
      _isLoadingAll = true;
      _isLoadingUser = true;
    });
    
    try {
      // Load all reviews
      final allReviews = await _reviewsController.getAllReviews();
      setState(() {
        _allReviews = allReviews;
        _isLoadingAll = false;
      });
      
      // Load user reviews if user is logged in
      if (user != null) {
        final userReviews = await _reviewsController.getUserReviews(user.uid);
        setState(() {
          _userReviews = userReviews;
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _userReviews = [];
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoadingAll = false;
        _isLoadingUser = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading reviews: $e"))
        );
      }
    }
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

    if (_isLoadingUser) {
      return Center(child: CircularProgressIndicator());
    }

    // Apply filtering
    final filteredReviews = _applyFilter(_userReviews);

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
                ).then((_) => _loadReviews()); // Refresh after returning
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
  }

  Widget _buildAllReviewsTab(User? user) {
    if (_isLoadingAll) {
      return Center(child: CircularProgressIndicator());
    }
    
    // Apply filtering
    final filteredReviews = _applyFilter(_allReviews);

    if (filteredReviews.isEmpty) {
      return Center(child: Text("No reviews found"));
    }

    return SearchableList<Map<String, dynamic>>(
      items: filteredReviews,
      getSearchString: (review) => review["medicationName"] ?? "",
      itemBuilder: (review, index) {
        // Check if this review belongs to the current user
        bool isUserReview = user != null && review["userId"] == user.uid;
        
        return ReviewCard(
          review: review,
          isUserReview: isUserReview,
          onEdit: (review) {
            // Only allow editing if it's the user's review
            if (isUserReview) {
              _navigateToEditReview(review);
            }
          },
          onDelete: (review) {
            // Only allow deletion if it's the user's review
            if (isUserReview) {
              _showDeleteConfirmation(review);
            }
          },
        );
      },
      onSelect: (review) {
        // Only navigate to edit if it's the user's review
        if (user != null && review["userId"] == user.uid) {
          _navigateToEditReview(review);
        }
      },
      hintText: "Search reviews",
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
          // Handle Timestamp or DateTime for comparison
          DateTime aTime;
          DateTime bTime;
          
          if (a["createdAt"] is Timestamp) {
            aTime = (a["createdAt"] as Timestamp).toDate();
          } else if (a["createdAt"] is DateTime) {
            aTime = a["createdAt"] as DateTime;
          } else {
            aTime = DateTime.now(); // Fallback
          }
          
          if (b["createdAt"] is Timestamp) {
            bTime = (b["createdAt"] as Timestamp).toDate();
          } else if (b["createdAt"] is DateTime) {
            bTime = b["createdAt"] as DateTime;
          } else {
            bTime = DateTime.now(); // Fallback
          }
          
          return bTime.compareTo(aTime); // Newer first
        });
      default:
        return reviews;
    }
  }

  void _navigateToEditReview(Map<String, dynamic> review) {
    // Extra safety check to ensure only the owner can edit
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || review["userId"] != user.uid) {
      // User is not the owner of this review
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only edit your own reviews"))
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(existingReview: review),
      ),
    ).then((_) => _loadReviews()); // Refresh after returning
  }

  void _showDeleteConfirmation(Map<String, dynamic> review) {
    // Extra safety check to ensure only the owner can delete
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || review["userId"] != user.uid) {
      // User is not the owner of this review
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only delete your own reviews"))
      );
      return;
    }
    
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
                _loadReviews(); // Refresh after deletion
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
