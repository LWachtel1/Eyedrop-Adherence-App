import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsController {
  final FirestoreService firestoreService;

  ReviewsController({required this.firestoreService});

  /// Get a stream of all reviews
  Stream<List<Map<String, dynamic>>> getAllReviewsStream() {
    return firestoreService.getCollectionStreamWithIds("reviews")
        .asBroadcastStream();
  }

  /// Get a stream of reviews for a specific user
  Stream<List<Map<String, dynamic>>> getUserReviewsStream(String userId) {
    return firestoreService.queryCollectionWithIds(
      collectionPath: "reviews",
      filters: [
        {"field": "userId", "operator": "==", "value": userId}
      ],
    ).asStream().asBroadcastStream();
  }

  /// Get a stream of reviews for a specific medication
  Stream<List<Map<String, dynamic>>> getMedicationReviewsStream(String medicationId) {
    return firestoreService.queryCollectionWithIds(
      collectionPath: "reviews",
      filters: [
        {"field": "medicationId", "operator": "==", "value": medicationId}
      ],
    ).asStream().asBroadcastStream();
  }

  /// Check if a medication exists in the medications collection
  Future<Map<String, dynamic>?> _getMedicationById(String medicationId) async {
    return await firestoreService.readDoc(
      collectionPath: "medications",
      docId: medicationId,
    );
  }

  /// Create or get a medication document from the common medications collection
  Future<String> _ensureMedicationExists(Map<String, dynamic> reviewData) async {
    // If medicationId is already provided and valid, use it
    if (reviewData["medicationId"] != null) {
      final medication = await _getMedicationById(reviewData["medicationId"]);
      if (medication != null) {
        return reviewData["medicationId"];
      }
    }

    // Otherwise, look for an existing medication by name
    final queryResults = await firestoreService.queryCollectionWithIds(
      collectionPath: "medications",
      filters: [
        {"field": "medicationName", "operator": "==", "value": reviewData["medicationName"]}
      ],
    );

    if (queryResults.isNotEmpty) {
      return queryResults.first["id"];
    }

    // Generate a unique ID for new medication
    String newMedicationId =
        firestoreService.generateUniqueId(collectionPath: "medications");
    
    
    // If no existing medication is found, create a new one
    final medicationData = {
      "medicationName": reviewData["medicationName"],
      "medType": "Eye Medication", // Default to Eye Medication for reviews
      "createdAt": Timestamp.now(),
    };
    
    // Add the medication with our generated ID
    await firestoreService.addDoc(
      path: "medications",
      data: medicationData,
      docId: newMedicationId,
    );

    log("Created new medication in common collection: ${reviewData["medicationName"]}");
    return newMedicationId;
  }

  /// Create a new review
  Future<void> createReview(Map<String, dynamic> reviewData) async {
    try {
      // Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User must be authenticated to create a review");
      }

      // Make sure userId is set correctly
      reviewData["userId"] = user.uid;

      // Add timestamp if not already present
      if (!reviewData.containsKey("createdAt")) {
        reviewData["createdAt"] = Timestamp.now();
      }

      // Ensure the medication exists and get its ID
      String medicationId = await _ensureMedicationExists(reviewData);
      reviewData["medicationId"] = medicationId;

      // Add the review to Firestore
      await firestoreService.addDoc(
        path: "reviews",
        data: reviewData,
      );

      log("Review created successfully");
    } catch (e) {
      log("Error creating review: $e");
      throw Exception("Failed to create review: $e");
    }
  }

  /// Update an existing review
  Future<void> updateReview(String reviewId, Map<String, dynamic> reviewData) async {
    try {
      // Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User must be authenticated to update a review");
      }

      // Check if the review belongs to the current user
      final existingReview = await firestoreService.readDoc(
        collectionPath: "reviews",
        docId: reviewId,
      );

      if (existingReview == null) {
        throw Exception("Review not found");
      }

      if (existingReview["userId"] != user.uid) {
        throw Exception("You can only edit your own reviews");
      }

      // Ensure medication exists and get its ID
      String medicationId = await _ensureMedicationExists(reviewData);
      reviewData["medicationId"] = medicationId;

      // Add edited timestamp
      reviewData["editedAt"] = Timestamp.now();

      // Update the review
      await firestoreService.updateDoc(
        collectionPath: "reviews",
        docId: reviewId,
        newData: reviewData,
      );

      log("Review updated successfully");
    } catch (e) {
      log("Error updating review: $e");
      throw Exception("Failed to update review: $e");
    }
  }

  /// Delete a review
  Future<void> deleteReview(Map<String, dynamic> review) async {
    try {
      // Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User must be authenticated to delete a review");
      }

      // Verify that the review belongs to the current user
      if (review["userId"] != user.uid) {
        throw Exception("You can only delete your own reviews");
      }

      // Delete the review
      await firestoreService.deleteDoc(
        collectionPath: "reviews",
        docId: review["id"],
      );

      log("Review deleted successfully");
    } catch (e) {
      log("Error deleting review: $e");
      throw Exception("Failed to delete review: $e");
    }
  }
}
