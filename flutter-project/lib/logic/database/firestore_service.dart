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
import 'dart:convert';
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
  /// @param collectionPath The collection in which document to check for document.
  /// @param docId The id of alleged document.
  /// @returns A boolean value stating whether or not document exists.
  Future<bool> checkDocExists({
    required String collectionPath,
    required String docId,
    }) async {
      try {
        DocumentSnapshot doc = await _firestore.collection(collectionPath).doc(docId).get();
        return doc.exists; // Returns true if document exists, false otherwise
      } catch (e) {
        print("Error checking document existence in $collectionPath/$docId: $e");
        return false; // Assume false if an error occurs
      }
  }

  /// Generates a unique document id for a document, with an attached prefix.
  /// 
  /// @param collectionPath The cllection to which document belongs.
  /// @param prefix The prefix to attach to uniquely generated document id (based on document type).
  /// @returns A String comprised of prefix followed by unique document id.
  String _generatePrefixedId({required String collectionPath , required String prefix}) {

    // FireStore-generated ID
    String uniqueId = FirebaseFirestore.instance.collection(collectionPath).doc().id; 
    return "$prefix$uniqueId"; 
  }
  
  /// Creates a new document or updates an existing document, depending on value of merge parameter.
  /// 
  /// @param collectionPath The collection in which to add or update document.
  /// @param prefix The prefix to attach to id of new documents (based on document type).
  /// @param data The data for a new document or updated data for an existing document.
  /// @param merge Whether or not to create/overwrite a document or to update instead.
  Future<void> addDoc(
    {
    required String collectionPath, // e.g., "users" or "medications"
    required String prefix,
    required Map<String, dynamic> data, // Document data
    bool merge = false, // If true, merges existing doc. Otherwise, overwrites by default.
  }) async {
    try {

      String docId = "";


      if(collectionPath == "users") {
        User? user = FirebaseAuth.instance.currentUser;
        if(user == null) {
          print("Error: No authenticated user found.");
          return;
        } 
        docId = user.uid;
        
      } else {
         docId = _generatePrefixedId(collectionPath: collectionPath, prefix: prefix);
      }

      await _firestore.collection(collectionPath).doc(docId).set(
            data,
            SetOptions(merge: merge), // Merge existing data if needed
          );
      print("Document added to $collectionPath/$docId successfully!");
    } catch (e) {
      print("Error adding document to $collectionPath: $e");
    }

  }

  /// Reads a document from Cloud FireStore database.
  /// 
  /// @param collectionPath The collection from which to get document.
  /// @param docId The The id of alleged document.
  /// @returns `Map<String, dynamic>` containing document's data if it exists. Otherwise returns null.
  Future<Map<String, dynamic>?> readDoc({
    required String collectionPath,
    required String docId,
    }) async {
      try {
        DocumentSnapshot doc = await _firestore.collection(collectionPath).doc(docId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null; 
      //returns document data if it exists, otherwise returns null
      } catch (e) {
        print("Error reading document  in $collectionPath/$docId: $e");
        return null; 
      }
  }

  /// Compares two maps of document data to see if they are the same; used for the purpose of updating a document.
  /// 
  /// @param oldData First map, corresponding to existing data within document.
  /// @param newData Second map, corresponding to updated data.
  /// @returns Whether or not the two maps contain the same data.
  bool _isSameData(Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    return DeepCollectionEquality().equals(oldData, newData);
  }

  
  /// Updates an existing document.
  /// 
  /// @param collectionPath The collection in which to update document.
  /// @param docId The id of alleged document.
  /// @param newData The data with which to update.
  /// @returns Whether or not the update occurred.
  Future<bool> updateDoc({
  required String collectionPath,
  required String docId,
  required Map<String, dynamic> newData,
  }) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection(collectionPath).doc(docId).get();

      if (!docSnapshot.exists) {
        print("Document does not exist");
        return false; //Document does not exist - no update performed.
      }

      // Converts Firestore document to a Map.
      Map<String, dynamic> existingData = docSnapshot.data() as Map<String, dynamic>;


      // Compares new data with existing data.
      if (_isSameData(existingData, newData)) {
        print("Document already has the same data. No update needed.");
        return false; // No update performed.
      }

      // Updates document if data is different.
      await _firestore.collection(collectionPath).doc(docId).update(newData);
      print("Document updated successfully.");
      return true; // Document was updated successfully.

    } catch (e) {
      print("Error checking/updating document: $e");
      return false; // Error occurred - no update performed. 
    }
  }

    
  /// Deletes a document.
  /// 
  /// @param collectionPath The collection from which to delete document.
  /// @param docId The id of alleged document.
  Future<void> deleteDoc(
    {
    required String collectionPath, // e.g., "users" or "medications"
    required String docId
  }) async {
    try {


      await _firestore.collection(collectionPath).doc(docId).delete();
          
      print("Document deleted $collectionPath/$docId successfully!");
    } catch (e) {
      print("Error deleting document from $collectionPath: $e");
    }

  }
 

}


