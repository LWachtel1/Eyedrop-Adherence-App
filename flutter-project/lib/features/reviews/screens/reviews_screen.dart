import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/reviews/controllers/reviews_controller.dart';
import 'package:eyedrop/features/reviews/screens/create_review_screen.dart';
import 'package:eyedrop/features/reviews/screens/medication_reviews_screen.dart';
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
  
  List<Map<String, dynamic>> _userReviews = [];
  List<Map<String, dynamic>> _medications = [];
  bool _isLoadingUser = true;
  bool _isLoadingMedications = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _reviewsController = ReviewsController(firestoreService: firestoreService);
    
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || _tabController.animation!.value == _tabController.index) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _isLoadingUser = true;
      _isLoadingMedications = true;
    });
    
    try {
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

      // Load reviewed medications
      final medications = await _reviewsController.getReviewedMedications();
      setState(() {
        _medications = medications;
        _isLoadingMedications = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
        _isLoadingMedications = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"))
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
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: "My Reviews"),
              Tab(text: "Browse Reviews"),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Reviews Tab
                _buildMyReviewsTab(user),
                
                // Browse Reviews Tab
                _buildBrowseReviewsTab(),
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
                ).then((_) => _loadData());
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

    if (_userReviews.isEmpty) {
      return Center(
        child: Text("You haven't written any reviews yet.")
      );
    }

    return SearchableList<Map<String, dynamic>>(
      items: _userReviews,
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

  Widget _buildBrowseReviewsTab() {
    if (_isLoadingMedications) {
      return Center(child: CircularProgressIndicator());
    }

    if (_medications.isEmpty) {
      return Center(child: Text("No reviewed medications found"));
    }

    return SearchableList<Map<String, dynamic>>(
      items: _medications,
      getSearchString: (medication) => medication["medicationName"] ?? "",
      itemBuilder: (medication, index) => _buildMedicationCard(medication),
      onSelect: (medication) => _navigateToMedicationReviews(medication),
      hintText: "Search medications",
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final medName = medication["medicationName"] ?? "Unknown Medication";
    final reviewCount = medication["reviewCount"] ?? 0;
    final averageRating = medication["averageRating"] ?? 0.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          medName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            SizedBox(width: 4),
            Text(averageRating.toStringAsFixed(1)),
            SizedBox(width: 8),
            Text("($reviewCount reviews)"),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _navigateToMedicationReviews(medication),
      ),
    );
  }

  void _navigateToMedicationReviews(Map<String, dynamic> medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationReviewsScreen(medication: medication),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToEditReview(Map<String, dynamic> review) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || review["userId"] != user.uid) {
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
    ).then((_) => _loadData());
  }

  void _showDeleteConfirmation(Map<String, dynamic> review) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || review["userId"] != user.uid) {
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
                _loadData();
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
