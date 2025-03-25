/*
  TO DO:
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

    if (collectionPath.isEmpty || docId.isEmpty) {
      log("Error: Collection path or document ID cannot be empty.");
      return false;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection(collectionPath).doc(docId).get();
      return doc.exists; // Returns true if document exists, false otherwise.
    } on FirebaseException catch (e) {
      log("Firestore error checking document in $collectionPath/$docId: ${e.message}");
      return false;
    } catch (e) {
      log("Unexpected error checking document in $collectionPath/$docId: $e");
      return false;
    }
  }

 
  /// Parameters:
  /// - `collectionPath`: The collection to which document belongs.
  ///
  /// Returns:
  /// A String consisting of a unique document id.
  String _generateUniqueId(
      {required String collectionPath}) {
    // FireStore-generated ID
    String uniqueId =
        _firestore.collection(collectionPath).doc().id;
    return uniqueId;
  }
 
  /*
  /// Generates a unique document id for a document, with an attached prefix.
  ///
  /// Parameters:
  /// - `path`: The FireStore path string to the document.
  ///
  /// Returns:
  /// A String comprised of prefix followed by unique document id.
  String _generateUniqueId(String path) {
    String prefix = path.split('/').last.substring(0, 3); // Prefix from last segment
    return "$prefix-${FirebaseFirestore.instance.collection(path).doc().id}";
  }
  */

  /// Navigates a FireStore path string to return the correct DocumentReference.
  /// 
  /// Parameters:
  /// - `path`: FireStore path string
  /// - `docId`: the id of the alleged document
  /// 
  /// Returns:
  /// A `DocumentReference` specifying the location at which to manipulate a document.
  DocumentReference _getDocumentReference(String path, String? docId) {
    if (path.trim().isEmpty) {
      throw ArgumentError("Firestore path cannot be empty.");
    }

    List<String> segments = path.split('/').where((s) => s.isNotEmpty).toList(); // Remove empty parts
  

    if (segments.isEmpty) {
      throw ArgumentError("Invalid Firestore path: Path must have at least one segment.");
    }

    if (segments.length == 1) {
      // If there's only one segment, it's a top-level collection.
      if (docId == null || docId.isEmpty) {
        throw ArgumentError("A document ID must be provided when adding to a root collection.");
      }
      return _firestore.collection(segments[0]).doc(docId);
    }

    if (segments.length.isOdd) {
      // If the number of segments is ODD, last segment is a COLLECTION.
      DocumentReference parentDocRef = _firestore.collection(segments[0]).doc(segments[1]);

      for (int i = 2; i < segments.length - 1; i += 2) {
        parentDocRef = parentDocRef.collection(segments[i]).doc(segments[i + 1]);
      }

      return parentDocRef.collection(segments.last).doc(docId);
    } else {
      // If the number of segments is EVEN, last segment is a DOCUMENT.
      CollectionReference collectionRef = _firestore.collection(segments[0]);

      for (int i = 1; i < segments.length - 1; i += 2) {
        collectionRef = collectionRef.doc(segments[i]).collection(segments[i + 1]);
      }

      return collectionRef.doc(docId);
    }
  }

  

  /*
  /// Creates a new document or updates an existing document, depending on value of merge parameter.
  ///   
  /// Parameters:
  ///
  /// - `collectionPath`: The path to the collection in which to add or update document.
  /// - `prefix`: The prefix to attach to id of new documents (based on document type).
  /// - `data`: The data for a new document or updated data for an existing document.
  /// - `merge`: Whether or not to create/overwrite a document or to update instead.
  /// - `docId`: The document id for the document to update if using addDoc with merge: True
  Future<void> addDoc({
    required String collectionPath,
    required String prefix,
    required Map<String, dynamic> data, // Document data.
    bool merge =
        false, // If true, merges existing doc. Otherwise, overwrites by default.
    String? docId
  }) async {

     if (collectionPath.isEmpty || data.isEmpty) {
      log("Error: Collection path or data cannot be empty.");
      return;
    }


    try {
      String documentId = "";

      if (collectionPath.startsWith("users")) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          log("Error: No authenticated user found.");
          return;
        }
        //If altering a user document, sets document id to id of current user.
        documentId = user.uid;
      } else {
        //Otherwise, sets id to provided parameter (for update) or generates a unique id (for create).
        documentId = docId ??
            _generatePrefixedId(collectionPath: collectionPath, prefix: prefix);

      }


      await _firestore.collection(collectionPath).doc(documentId).set(
            data,
            SetOptions(merge: merge), // Merge existing data if needed
          );
      log("Document added to $collectionPath/$documentId successfully!");
    } on FirebaseException catch (e) {
      log("Firestore error adding document to $collectionPath: ${e.message}");
    } catch (e) {
      log("Unexpected error adding document to $collectionPath: $e");
    }
  }
  */


  /// Creates a new document or updates an existing document, depending on value of merge parameter.
  /// 
  /// Can add documents to top-level collections and deeply nested sub-collections as well.
  ///
  /// Parameters:
  ///
  /// - `path`: The FireStore path string directing where to add or update document. 
  /// This can be a top-level collection or nested sub-collection.
  /// - `data`: The data for a new document or updated data for an existing document.
  /// - `docId`: The document id for the document to update if using addDoc with merge: True
  /// - `merge`: Whether or not to create/overwrite a document or to update instead.
  /// - `useAuthUid`: Whether or not to use authenticated user's UID as doc ID (for top-level user docs).
  Future<void> addDoc({
  required String path, 
  required Map<String, dynamic> data, 
  String? docId, 
  bool merge = false, 
  bool useAuthUid = false, 
}) async {

  if (path.isEmpty || data.isEmpty) {
    log("Error: Collection path or data cannot be empty.");
    return;
  }

  try {
    String finalDocId = docId ?? _generateUniqueId(collectionPath: path);

    // Use authenticated user's UID as doc ID (for top-level user docs).
    if (useAuthUid) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("Error: No authenticated user found.");
        return;
      }
      finalDocId = user.uid;
    }

    // Gets Document Reference to the correct Firestore collection.
    DocumentReference docRef = _getDocumentReference(path, finalDocId);

    // Add or merge document.
    await docRef.set(data, SetOptions(merge: merge));
    log("Document successfully added/updated at ${docRef.path}");

  } on FirebaseException catch (e) {
    log("Firestore error adding document: ${e.message}");
  } catch (e) {
    log("Unexpected error adding document: $e");
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

    if (collectionPath.isEmpty || docId.isEmpty) {
      log("Error: Collection path or document ID cannot be empty.");
      return null;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection(collectionPath).doc(docId).get();
      
      if (!doc.exists) return null; //returns

      final data = doc.data();

      if (data is Map<String, dynamic>) {
        return data;
      } else {
        log("Error: Document data in $collectionPath/$docId is not a valid Map.");
        return null;
      }

      //return doc.exists ? doc.data() as Map<String, dynamic> : null;
    
    } on FirebaseException catch (e) {
      log("Firestore error reading document in $collectionPath/$docId: ${e.message}");
      return null;
    } catch (e) {
      log("Unexpected error reading document in $collectionPath/$docId: $e");
      return null;
    }
  }

  /// Normalises then compares two maps of document data to see if they are the same; used for the purpose of updating a document.
  ///
  /// Parameters:
  /// `oldData`: The first map, corresponding to existing data within document.
  /// `newData`: The second map, corresponding to updated data.
  ///
  /// Returns:
  /// - `true` if the normalised maps contain the same data.
  /// - `false` if the normalised maps do not contain the same data.
  bool _isSameData(Map<String, dynamic> oldData, Map<String, dynamic> newData) {
  Map<String, dynamic> normalizedOld = _normalizeData(oldData);
  Map<String, dynamic> normalizedNew = _normalizeData(newData);
  return DeepCollectionEquality().equals(normalizedOld, normalizedNew);
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

    if (collectionPath.isEmpty || docId.isEmpty || newData.isEmpty) {
      log("Error: Collection path, document ID, or new data cannot be empty.");
      return false;
    }

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
    } 
    on FirebaseException catch (e) {
      log("Firestore error updating document from $collectionPath/$docId: ${e.message}");
      return false; // Error occurred - no update performed.
    } catch (e) {
      log("Unexpected error updating document from $collectionPath/$docId: $e");
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

    if (collectionPath.isEmpty || docId.isEmpty) {
      log("Error: Collection path or document ID cannot be empty.");
      return;
    }

    try {
      await _firestore.collection(collectionPath).doc(docId).delete();

      log("Document deleted $collectionPath/$docId successfully!");
    } on FirebaseException catch (e) {
      log("Firestore error deleting document from $collectionPath/$docId: ${e.message}");
    } catch (e) {
      log("Unexpected error deleting document from $collectionPath/$docId: $e");
    }

  }


  /// Retrieves all documents from a specified Firestore collection.
  /// 
  /// Parameters:
  /// - `collectionPath`: The Firestore collection from which to retrieve documents.
  /// 
  /// Returns:
  /// - A `List<Map<String, dynamic>>` containing all documents from the collection.
  /// - If the collection is empty or an error occurs, returns an empty list.
  Future<List<Map<String, dynamic>>> getAllDocs({
    required String collectionPath,
  }) async {

    if (collectionPath.isEmpty) {
      log("Error: Collection path cannot be empty.");
      return [];
    }

    try {
      QuerySnapshot querySnapshot = await _firestore.collection(collectionPath).get();

      // Convert Firestore documents into a List<Map<String, dynamic>>
      List<Map<String, dynamic>> documents = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID in the returned map
        return data;
      }).toList();

      return documents;
    } on FirebaseException catch (e) {
      log("Firestore error retrieving documents from $collectionPath: ${e.message}");
      return [];
    } catch (e) {
      log("Unexpected error retrieving documents from $collectionPath: $e");
      return [];
    }
  }

  /// Queries a Firestore collection with optional filtering, ordering, and limiting.
  ///
  /// Parameters:
  /// - `collectionPath`: The Firestore collection to query.
  /// - `filters`: A list of maps, each containing a filter condition.
  ///   - Each map should have:
  ///     - `field` (String): The field name to filter by.
  ///     - `operator` (String): The comparison operator (`==`, `<`, `>`, `<=`, `>=`, `array-contains`, etc.).
  ///     - `value` (dynamic): The value to compare against.
  /// - `orderBy`: A map specifying how to order the results (optional).
  ///   - `field` (String): The field name to sort by.
  ///   - `descending` (bool, default: `false`): Whether to sort in descending order.
  /// - `limit`: The maximum number of documents to return (optional).
  ///
  /// Returns:
  /// - A `List<Map<String, dynamic>>` containing documents that match the query.
  /// - If an error occurs or no results are found, returns an empty list.
  ///
  /// Example Usage:
  /// ```dart
  /// List<Map<String, dynamic>> results = await queryCollection(
  ///   collectionPath: "medications",
  ///   filters: [
  ///     {"field": "category", "operator": "==", "value": "antibiotic"},
  ///     {"field": "stock", "operator": ">", "value": 0}
  ///   ],
  ///   orderBy: {"field": "name", "descending": false},
  ///   limit: 10,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> queryCollection({
    required String collectionPath,
    List<Map<String, dynamic>>? filters,
    Map<String, dynamic>? orderBy,
    int? limit,
  }) async {
    if (collectionPath.isEmpty) {
      log("Error: Collection path cannot be empty.");
      return [];
    }

    try {
      Query query = _firestore.collection(collectionPath);

      // Applies filters (WHERE conditions).
      if (filters != null && filters.isNotEmpty) {
        for (var filter in filters) {
          String field = filter["field"];
          String operator = filter["operator"];
          dynamic value = filter["value"];

          switch (operator) {
            case "==":
              query = query.where(field, isEqualTo: value);
              break;
            case "<":
              query = query.where(field, isLessThan: value);
              break;
            case ">":
              query = query.where(field, isGreaterThan: value);
              break;
            case "<=":
              query = query.where(field, isLessThanOrEqualTo: value);
              break;
            case ">=":
              query = query.where(field, isGreaterThanOrEqualTo: value);
              break;
            case "array-contains":
              query = query.where(field, arrayContains: value);
              break;
            case "array-contains-any":
              query = query.where(field, arrayContainsAny: value);
              break;
            case "in":
              query = query.where(field, whereIn: value);
              break;
            case "not-in":
              query = query.where(field, whereNotIn: value);
              break;
            default:
              log("Error: Unsupported query operator $operator");
              return [];
          }
        }
      }

      // Applies ordering (ORDER BY).
      if (orderBy != null && orderBy.containsKey("field")) {
        String orderField = orderBy["field"];
        bool descending = orderBy["descending"] ?? false;
        query = query.orderBy(orderField, descending: descending);
      }

      // Applies limit.
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Executes query and process results.
      QuerySnapshot querySnapshot = await query.get();
      List<Map<String, dynamic>> results = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Includes document ID.
        return data;
      }).toList();

      return results;
    } on FirebaseException catch (e) {
      log("Firestore query error in $collectionPath: ${e.message}");
      return [];
    } catch (e) {
      log("Unexpected error querying $collectionPath: $e");
      return [];
    }
  }

  /// Checks if an exact duplicate document exists within a Firestore collection.
  /// 
  /// This function compares all fields in `data` against existing documents.
  /// 
  /// Parameters:
  /// - `collectionPath`: The path to the Firestore collection/sub-collection.
  /// - `data`: The document data to check for duplication.
  /// 
  /// Returns:
  /// - `true` if an exact duplicate exists.
  /// - `false` if no duplicate is found.
 Future<bool> checkExactDuplicateDoc({
  required String collectionPath,
  required Map<String, dynamic> data,
}) async {
  if (collectionPath.isEmpty || data.isEmpty) {
    log("Error: Collection path and data cannot be empty.");
    return false;
  }

  try {
    // Fetch all documents from the specified collection.
    QuerySnapshot querySnapshot = await _firestore.collection(collectionPath).get();

    for (var doc in querySnapshot.docs) {
      // ✅ Explicitly cast Firestore data to `Map<String, dynamic>`
      Map<String, dynamic> existingData = Map<String, dynamic>.from(doc.data() as Map);

      // ✅ Remove Firestore metadata fields
      existingData.remove("id");
      data.remove("id");

      // ✅ Normalize Firestore timestamps and numbers for comparison
      Map<String, dynamic> normalizedExisting = _normalizeData(existingData);
      Map<String, dynamic> normalizedData = _normalizeData(data);

      // ✅ Perform deep equality check
      if (DeepCollectionEquality().equals(normalizedExisting, normalizedData)) {
        log("Exact duplicate document found in $collectionPath with ID: ${doc.id}");
        return true; // Duplicate found
      }
    }

    log("No exact duplicate document found in $collectionPath.");
    return false; // No duplicates found
  } on FirebaseException catch (e) {
    log("Firestore error checking duplicates in $collectionPath: ${e.message}");
    return false;
  } catch (e) {
    log("Unexpected error checking duplicates in $collectionPath: $e");
    return false;
  }
}

/// **Helper function: Normalizes Firestore data**
Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
  Map<String, dynamic> normalizedData = {};

  data.forEach((key, value) {
    if (value is Timestamp) {
      normalizedData[key] = value.toDate().toIso8601String(); // ✅ Ensures consistent format
    } else if (value is DateTime) {
      normalizedData[key] = value.toIso8601String(); // ✅ Ensures consistent format
    } else if (value is num) {
      normalizedData[key] = value.toDouble(); // ✅ Converts int → double for consistency
    } else if (value is List) {
      // Don't try to sort lists that might contain maps
      if (value.isEmpty || value.first is! Map) {
        // Only create a sorted copy for non-Map lists (like strings, numbers)
        normalizedData[key] = value.map((e) => _normalizeValue(e)).toList();
        if (value.isNotEmpty && value.first is Comparable) {
          normalizedData[key].sort(); // Only sort if elements are comparable
        }
      } else {
        // For lists of maps, normalize each map but don't sort
        normalizedData[key] = value.map((e) => _normalizeValue(e)).toList();
      }
    } else if (value is Map) {
      normalizedData[key] = _normalizeData(Map<String, dynamic>.from(value)); // ✅ Ensures Map<String, dynamic>
    } else {
      normalizedData[key] = value;
    }
  });

  return normalizedData;
}

/// Normalizes a single value - helper for normalizing list items
dynamic _normalizeValue(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  } else if (value is DateTime) {
    return value.toIso8601String();
  } else if (value is num) {
    return value.toDouble();
  } else if (value is Map) {
    return _normalizeData(Map<String, dynamic>.from(value));
  } else if (value is List) {
    return value.map((e) => _normalizeValue(e)).toList();
  } else {
    return value;
  }
}

/// Fetches a Firestore collection as a real-time stream.
Stream<List<Map<String, dynamic>>> getCollectionStream(String collectionPath) {
  return _firestore.collection(collectionPath).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data["id"] = doc.id; 
      return data;
    }).toList();
  });
}

/// Returns a stream of documents from a collection, including document IDs.
///
/// This method is similar to getCollectionStream but explicitly adds the document ID
/// as an "id" field in each document's data map.
Stream<List<Map<String, dynamic>>> getCollectionStreamWithIds(String collectionPath) {
  try {
    return _firestore
        .collection(collectionPath)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Create a map with the document data
            Map<String, dynamic> data = doc.data();
            // Add the document ID as a field named "id"
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  } catch (e) {
    log("Error getting collection stream with IDs: $e");
    // Return an empty stream in case of error
    return Stream.value([]);
  }
}

/// Gets all documents from a collection, including their IDs.
Future<List<Map<String, dynamic>>> getAllDocsWithIds(
    {required String collectionPath}) async {
  try {
    final snapshot =
        await _firestore.collection(collectionPath).get();
    
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      // Add the document ID as a field named "id"
      data['id'] = doc.id;
      return data;
    }).toList();
  } catch (e) {
    log("Error getting all docs with IDs: $e");
    return [];
  }
}

/// Queries a Firestore collection and includes document IDs in the results.
///
/// This method extends the functionality of queryCollection by automatically
/// adding the document ID to each document's data map with the key "id".
///
/// Parameters:
/// - `collectionPath`: The Firestore collection to query.
/// - `filters`: A list of maps, each containing a filter condition.
///   - Each map should have:
///     - `field` (String): The field name to filter by.
///     - `operator` (String): The comparison operator (`==`, `<`, `>`, etc.).
///     - `value` (dynamic): The value to compare against.
/// - `orderBy`: A map specifying how to order the results (optional).
///   - `field` (String): The field name to sort by.
///   - `descending` (bool, default: `false`): Whether to sort in descending order.
/// - `limit`: The maximum number of documents to return (optional).
///
/// Returns:
/// - A `List<Map<String, dynamic>>` containing documents that match the query,
///   with each document containing its ID in the "id" field.
/// - If an error occurs or no results are found, returns an empty list.
Future<List<Map<String, dynamic>>> queryCollectionWithIds({
  required String collectionPath,
  List<Map<String, dynamic>>? filters,
  Map<String, dynamic>? orderBy,
  int? limit,
  String? startAfterDocument,
}) async {
  try {
    if (collectionPath.isEmpty) {
      throw Exception("Collection path cannot be empty");
    }

    Query query = _firestore.collection(collectionPath);

    // Apply filters
    if (filters != null && filters.isNotEmpty) {
      for (var filter in filters) {
        if (filter.containsKey('field') && 
            filter.containsKey('operator') && 
            filter.containsKey('value')) {
          String field = filter['field'] as String;
          String operator = filter['operator'] as String;
          dynamic value = filter['value'];

          switch (operator) {
            case '==':
              query = query.where(field, isEqualTo: value);
              break;
            case '!=':
              query = query.where(field, isNotEqualTo: value);
              break;
            case '>':
              query = query.where(field, isGreaterThan: value);
              break;
            case '>=':
              query = query.where(field, isGreaterThanOrEqualTo: value);
              break;
            case '<':
              query = query.where(field, isLessThan: value);
              break;
            case '<=':
              query = query.where(field, isLessThanOrEqualTo: value);
              break;
            case 'in':
              if (value is List) {
                query = query.where(field, whereIn: value);
              }
              break;
            case 'array-contains':
              query = query.where(field, arrayContains: value);
              break;
            default:
              log('Unsupported operator: $operator');
          }
        }
      }
    }

    // Apply ordering
    if (orderBy != null && 
        orderBy.containsKey('field') && 
        orderBy['field'] is String) {
      bool descending = orderBy.containsKey('descending') && 
                        orderBy['descending'] == true;
      query = query.orderBy(
        orderBy['field'] as String, 
        descending: descending
      );
    }
    
    // Apply pagination using startAfter
    if (startAfterDocument != null) {
      try {
        // Get the document to start after
        DocumentSnapshot startDoc = await _firestore
          .collection(collectionPath)
          .doc(startAfterDocument)
          .get();
          
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      } catch (e) {
        log('Error getting start document: $e');
        // Continue without pagination if there's an error
      }
    }

    // Apply limit
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    final querySnapshot = await query.get();
    final docs = querySnapshot.docs;

    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  } catch (e) {
    log('Error querying collection: $e');
    throw Exception('Failed to query collection: $e');
  }
}

/// Gets a real-time stream for a specific document
/// 
/// Parameters:
/// - `collectionPath`: The path to the collection containing the document
/// - `docId`: The ID of the document to stream
/// 
/// Returns:
/// A stream of the document data as a `Map<String, dynamic>` with the document ID included,
/// or null if the document doesn't exist
Stream<Map<String, dynamic>?> getDocumentStream({
  required String collectionPath, 
  required String docId
}) {
  if (collectionPath.isEmpty || docId.isEmpty) {
    log("Error: Collection path or document ID cannot be empty.");
    return Stream.value(null);
  }

  try {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          // Include the document ID in the data
          data['id'] = snapshot.id;
          return data;
        });
  } catch (e) {
    log("Error creating document stream for $collectionPath/$docId: $e");
    return Stream.value(null);
  }
}


}
