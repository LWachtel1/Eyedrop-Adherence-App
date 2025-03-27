import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isUserReview;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  const ReviewCard({
    Key? key,
    required this.review,
    required this.isUserReview,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double rating = (review["rating"] as num?)?.toDouble() ?? 0.0;
    final List<String> pros = List<String>.from(review["pros"] ?? []);
    final List<String> cons = List<String>.from(review["cons"] ?? []);
    final bool recommend = review["recommend"] ?? false;
    final doseQuantity = review["doseQuantity"] ?? "";
    final doseUnits = review["doseUnits"] ?? "";
    final scheduleType = review["scheduleType"] ?? "";
    final applicationSite = review["applicationSite"];
    
    // Format the timestamp
    String formattedDate = "Unknown date";
    if (review["createdAt"] != null) {
      DateTime date;
      if (review["createdAt"] is Timestamp) {
        date = (review["createdAt"] as Timestamp).toDate();
      } else {
        date = review["createdAt"] as DateTime;
      }
      formattedDate = DateFormat('MMM d, yyyy').format(date);
    }
    
    // Check if review has been edited
    bool isEdited = review["editedAt"] != null;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication name and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review["medicationName"] ?? "Unknown Medication",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildRatingStars(rating),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Date and edited status
            Row(
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                if (isEdited) ...[
                  SizedBox(width: 8),
                  Text(
                    "(edited)",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            
            SizedBox(height: 12),
            
            // Review text
            Text(
              review["reviewText"] ?? "",
              style: TextStyle(fontSize: 14.sp),
            ),
            
            SizedBox(height: 16),
            
            // Pros and Cons
            if (pros.isNotEmpty) _buildDetailSection("Pros", pros, Colors.green[100]!),
            SizedBox(height: 8),
            if (cons.isNotEmpty) _buildDetailSection("Cons", cons, Colors.red[100]!),
            
            SizedBox(height: 12),
            
            // Recommendation
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: recommend ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                recommend ? "Would Recommend" : "Would Not Recommend",
                style: TextStyle(
                  color: recommend ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Usage details
            if (review["durationUsed"] != null && review["durationUsed"].toString().isNotEmpty)
              _buildInfoRow("Duration Used", review["durationUsed"]),
            
            if (scheduleType.isNotEmpty)
              _buildInfoRow("Schedule", scheduleType),
            
            if (applicationSite != null && applicationSite.toString().isNotEmpty)
              _buildInfoRow("Application Site", applicationSite),
            
            if (doseQuantity.toString().isNotEmpty && doseUnits.toString().isNotEmpty)
              _buildInfoRow("Dose", "$doseQuantity $doseUnits"),
            
            // Actions only for user's own reviews
            if (isUserReview) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => onEdit(review),
                    tooltip: "Edit Review",
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete(review),
                    tooltip: "Delete Review",
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating.ceil() && index >= rating.floor()) {
          return Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  Widget _buildDetailSection(String title, List<String> items, Color backgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(item),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
