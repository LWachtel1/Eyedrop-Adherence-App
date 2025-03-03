/*
  TO DO:
  - Implement stricter checks and error-handling in CRUD operations
    - checking whether document exists before attempting CRUD
    etc.

  - Test how addDoc() with merge: True works 
    i.e., does it truly update a document with removing fields not mentioned in data
  
  - Test whether updateDoc() remove fields not mentioned from newData

  - Add additional CRUD-related operations 
    - queries
  
*/

import 'dart:async';
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

///The main API for Cloud FireStore interactions
///
///It provides CRUD operations for interacting with th app's Cloud FireStore database.
class FirestoreService {
  //private named constructor
  FirestoreService._internal();

  //Creates a private static instance of class when class first loads, using the private constructor.
  static final FirestoreService _instance = FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Factory constructor always returns the same _instance, so only 1 FirestoreService instance is made.
  factory FirestoreService() => _instance;

  /// Checks if a given document exists.
  ///
  /// Parameters:
  /// - `collectionPath`: The collection in which document to check for document.
  /// - `docId`: The id of alleged document for which to check.
  ///
  /// Returns:
  /// - `true` if the document exists.
  /// - `false` if the document does not exist or an error occurs while checking for the document.
  Future<bool> checkDocExists({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collectionPath).doc(docId).get();
      return doc.exists; // Returns true if document exists, false otherwise.
    } catch (e) {
      log("Error checking document existence in $collectionPath/$docId: $e");
      return false; // Assume false if an error occurs.
    }
  }

  /// Generates a unique document id for a document, with an attached prefix.
  ///
  /// Parameters:
  /// - `collectionPath`: The cllection to which document belongs.
  /// - `prefix`: The prefix to attach to uniquely generated document id (based on document type).
  ///
  /// Returns:
  /// A String comprised of prefix followed by unique document id.
  String _generatePrefixedId(
      {required String collectionPath, required String prefix}) {
    // FireStore-generated ID
    String uniqueId =
        FirebaseFirestore.instance.collection(collectionPath).doc().id;
    return "$prefix$uniqueId";
  }

  /// Creates a new document or updates an existing document, depending on value of merge parameter.
  ///
  /// Parameters:
  ///
  /// - `collectionPath`: The collection in which to add or update document.
  /// - `prefix`: The prefix to attach to id of new documents (based on document type).
  /// - `data`: The data for a new document or updated data for an existing document.
  /// - `merge`: Whether or not to create/overwrite a document or to update instead.
  Future<void> addDoc({
    required String collectionPath,
    required String prefix,
    required Map<String, dynamic> data, // Document data.
    bool merge =
        false, // If true, merges existing doc. Otherwise, overwrites by default.
  }) async {
    try {
      String docId = "";

      if (collectionPath == "users") {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          log("Error: No authenticated user found.");
          return;
        }
        docId = user.uid;
      } else {
        docId =
            _generatePrefixedId(collectionPath: collectionPath, prefix: prefix);
      }

      await _firestore.collection(collectionPath).doc(docId).set(
            data,
            SetOptions(merge: merge), // Merge existing data if needed
          );
      log("Document added to $collectionPath/$docId successfully!");
    } catch (e) {
      log("Error adding document to $collectionPath: $e");
    }
  }

  /// Reads a document from Cloud FireStore database.
  ///
  /// Parameters:
  /// `collectionPath`: The collection from which to retrieve document.
  /// `docId`: The id of alleged document to retrieve.
  ///
  /// Returns:
  /// A `Map<String, dynamic>` containing document's data if the document exists.
  /// Otherwise, returns null.
  Future<Map<String, dynamic>?> readDoc({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collectionPath).doc(docId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
      // Returns document data if it exists, otherwise returns null.
    } catch (e) {
      log("Error reading document  in $collectionPath/$docId: $e");
      return null;
    }
  }

  /// Compares two maps of document data to see if they are the same; used for the purpose of updating a document.
  ///
  /// Parameters:
  /// `oldData`: The first map, corresponding to existing data within document.
  /// `newData`: The second map, corresponding to updated data.
  ///
  /// Returns:
  /// - `true` if the maps contain the same data.
  /// - `false` if the maps do not contain the same data.
  bool _isSameData(Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    return DeepCollectionEquality().equals(oldData, newData);
  }

  /// Updates an existing document.
  ///
  /// Parameters:
  /// - `collectionPath`: The collection in which to update document.
  /// - `docId`: The id of alleged document to update.
  /// - `newData`: The data with which to update.
  ///
  /// Returns:
  /// - `true` if the document was updated successfully.
  /// - `false` if the document does not exist, already contains the same data,
  ///   or if an error occurred during the update process.
  Future<bool> updateDoc({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> newData,
  }) async {
    try {
      DocumentSnapshot docSnapshot =
          await _firestore.collection(collectionPath).doc(docId).get();

      if (!docSnapshot.exists) {
        log("Document does not exist");
        return false; //Document does not exist - no update performed.
      }

      // Converts Firestore document to a Map.
      Map<String, dynamic> existingData =
          docSnapshot.data() as Map<String, dynamic>;

      // Compares new data with existing data.
      if (_isSameData(existingData, newData)) {
        log("Document already has the same data. No update needed.");
        return false; // No update performed.
      }

      // Updates document if data is different.
      await _firestore.collection(collectionPath).doc(docId).update(newData);
      log("Document updated successfully.");
      return true; // Document was updated successfully.
    } catch (e) {
      log("Error checking/updating document: $e");
      return false; // Error occurred - no update performed.
    }
  }

  /// Deletes a document.
  ///
  /// Parameters:
  /// - `collectionPath`: The collection from which to delete document.
  /// - `docId`: The id of alleged document to delete.
  Future<void> deleteDoc(
      {required String collectionPath, required String docId}) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();

      log("Document deleted $collectionPath/$docId successfully!");
    } catch (e) {
      log("Error deleting document from $collectionPath: $e");
    }
  }
}
