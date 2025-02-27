import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

///The main API for Cloud FireStore interactions
///
///It provides CRUD operations for FireStore database. These can be called from anywhere in Flutter app.
class FirestoreService {

  //private named constructor 
  FirestoreService._internal();

   //creates a private static instance of PouchDBService when class first loads, using the 
   //private constructor 
  static final FirestoreService _instance = FirestoreService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  //factory constructor always returns the same _instance, so only 1 FirestoreService instance is made.
  factory FirestoreService() => _instance;


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

  //Generates a custom document ID with a specific prefix
  String _generatePrefixedId({required String collectionPath , required String prefix}) {

    // FireStore-generated ID
    String uniqueId = FirebaseFirestore.instance.collection(collectionPath).doc().id; 
    return "$prefix$uniqueId"; // Append prefix
  }
  
  //CREATE
  //ALSO PROVIDES UPDATE without overwrite CAPABILITY AS IT ALLOWS MERGE to be set to true if needed
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

  //Read
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

  // Helper function to compare two maps for updating document
  bool _isSameData(Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    return DeepCollectionEquality().equals(oldData, newData);
  }

  
  //UPDATE
  Future<bool> updateDoc({
  required String collectionPath,
  required String docId,
  required Map<String, dynamic> newData,
  }) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection(collectionPath).doc(docId).get();

      if (!docSnapshot.exists) {
        print("Document does not exist");
        return false; // Document was created
      }

      // Convert Firestore document to a Map
      Map<String, dynamic> existingData = docSnapshot.data() as Map<String, dynamic>;


      // Compare new data with existing data
      if (_isSameData(existingData, newData)) {
        print("Document already has the same data. No update needed.");
        return false; // No update performed
      }

      // Update document if data is different
      await _firestore.collection(collectionPath).doc(docId).update(newData);
      print("Document updated successfully.");
      return true; // Document was updated

    } catch (e) {
      print("Error checking/updating document: $e");
      return false; // Error occurred
    }
  }

  //DELETE
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


