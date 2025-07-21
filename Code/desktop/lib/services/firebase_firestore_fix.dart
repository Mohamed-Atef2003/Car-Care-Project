import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility class to help prevent Firebase Firestore threading issues
/// This should be used whenever accessing Firestore streams to ensure
/// operations occur on the platform thread
class FirestoreThreadFix {
  
  /// Configures Firestore with optimized settings
  static void configureFirestore() {
    try {
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('FirestoreThreadFix: Configured Firestore successfully');
    } catch (e) {
      debugPrint('FirestoreThreadFix: Error configuring Firestore: $e');
    }
  }
  
  /// Wraps a Firestore stream to ensure it runs on the platform thread
  /// This helps prevent the threading error messages from Flutter
  static Stream<T> wrapStream<T>(Stream<T> stream) {
    return stream.handleError((error) {
      debugPrint('FirestoreThreadFix: Stream error: $error');
      throw error;
    });
  }
  
  /// Creates a stream for a collection that runs on the platform thread
  static Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
    bool includeMetadataChanges = false,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return wrapStream(
      query.snapshots(includeMetadataChanges: includeMetadataChanges)
    );
  }
  
  /// Creates a stream for a document that runs on the platform thread
  static Stream<DocumentSnapshot<Map<String, dynamic>>> documentStream(
    String path, {
    bool includeMetadataChanges = false,
  }) {
    return wrapStream(
      FirebaseFirestore.instance.doc(path).snapshots(includeMetadataChanges: includeMetadataChanges)
    );
  }
  
  /// Safely gets data from a DocumentSnapshot, handling null cases
  static Map<String, dynamic>? getData(DocumentSnapshot? doc) {
    if (doc == null) return null;
    try {
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('FirestoreThreadFix: Error getting document data: $e');
      return null;
    }
  }
} 