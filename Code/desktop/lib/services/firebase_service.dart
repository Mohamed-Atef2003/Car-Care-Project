import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';

class FirebaseService {
  // Simple wrapper around Firebase for the application
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseService() {
    _configureFirestore();
  }
  
  void _configureFirestore() {
    try {
      // Configure Firestore with settings that help prevent threading issues
      _firestore.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('FirebaseService: Firestore configured successfully.');
    } catch (e) {
      debugPrint('FirebaseService: Error configuring Firestore: $e');
    }
  }
  
  // Helper function to ensure we're on the platform thread
  Future<T> _runOnPlatformThread<T>(Future<T> Function() callback) async {
    final completer = Completer<T>();
    
    // Get the binding instance
    final binding = WidgetsBinding.instance;
    
    // We have a binding, schedule on the next frame
    binding.addPostFrameCallback((_) async {
      try {
        final result = await callback();
        if (!completer.isCompleted) completer.complete(result);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    });
      
    return completer.future;
  }
  
  // Helper method to wrap Firestore streams and ensure platform thread usage
  Stream<T> ensurePlatformThread<T>(Stream<T> stream) {
    final controller = StreamController<T>();
    
    // Use a broadcast stream to avoid issues with multiple listeners
    final subscription = stream.listen(
      (data) {
        // Ensure we're adding events on the main thread
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.isClosed) {
            controller.add(data);
          }
        });
      },
      onError: (error, stackTrace) {
        debugPrint('FirebaseService: Stream error: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        });
      },
      onDone: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.isClosed) {
            controller.close();
          }
        });
      },
    );
    
    // Clean up the subscription when the controller is closed
    controller.onCancel = () {
      subscription.cancel();
    };
    
    return controller.stream;
  }
  
  // Get a collection stream with platform thread safety
  Stream<QuerySnapshot> collectionStream(
    String path, {
    Query Function(Query query)? queryBuilder,
    bool includeMetadataChanges = false,
  }) {
    try {
      // Create a dedicated stream controller that will handle platform thread safety
      final controller = StreamController<QuerySnapshot>.broadcast();
      var initialized = false;
      
      // Initialize the query and subscription
      void initialize() {
        if (initialized) return;
        initialized = true;
        
        // Run on the platform thread
        _runOnPlatformThread<void>(() async {
          try {
            // Create the query
            Query query = _firestore.collection(path);
            if (queryBuilder != null) {
              query = queryBuilder(query);
            }
            
            // Listen to snapshots on the platform thread
            final subscription = query.snapshots(
              includeMetadataChanges: includeMetadataChanges
            ).listen(
              (snapshot) {
                // Process each snapshot on the platform thread
                if (!controller.isClosed) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!controller.isClosed) {
                      controller.add(snapshot);
                    }
                  });
                }
              },
              onError: (error, stackTrace) {
                debugPrint('FirebaseService: Collection stream error: $error');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!controller.isClosed) {
                    controller.addError(error, stackTrace);
                  }
                });
              },
              onDone: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!controller.isClosed) {
                    controller.close();
                  }
                });
              },
            );
            
            // Clean up subscription when controller is closed
            controller.onCancel = () {
              subscription.cancel();
            };
          } catch (e) {
            debugPrint('FirebaseService: Error initializing collection stream: $e');
            if (!controller.isClosed) {
              controller.addError(e);
              controller.close();
            }
          }
        });
      }
      
      // Synchronously initialize the stream when the first subscriber connects
      controller.onListen = initialize;
      
      return controller.stream;
    } catch (e) {
      debugPrint('FirebaseService: Error creating collection stream: $e');
      return Stream.empty();
    }
  }
  
  // Get a document stream with platform thread safety
  Stream<DocumentSnapshot> documentStream(
    String path, {
    bool includeMetadataChanges = false,
  }) {
    try {
      // Create a dedicated stream controller that will handle platform thread safety
      final controller = StreamController<DocumentSnapshot>.broadcast();
      var initialized = false;
      
      // Initialize the document subscription
      void initialize() {
        if (initialized) return;
        initialized = true;
        
        // Run on the platform thread
        _runOnPlatformThread<void>(() async {
          try {
            // Get the document reference
            final docRef = _firestore.doc(path);
            
            // Listen to snapshots on the platform thread
            final subscription = docRef.snapshots(
              includeMetadataChanges: includeMetadataChanges
            ).listen(
              (snapshot) {
                // Process each snapshot on the platform thread
                if (!controller.isClosed) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!controller.isClosed) {
                      controller.add(snapshot);
                    }
                  });
                }
              },
              onError: (error, stackTrace) {
                debugPrint('FirebaseService: Document stream error: $error');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!controller.isClosed) {
                    controller.addError(error, stackTrace);
                  }
                });
              },
              onDone: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!controller.isClosed) {
                    controller.close();
                  }
                });
              },
            );
            
            // Clean up subscription when controller is closed
            controller.onCancel = () {
              subscription.cancel();
            };
          } catch (e) {
            debugPrint('FirebaseService: Error initializing document stream: $e');
            if (!controller.isClosed) {
              controller.addError(e);
              controller.close();
            }
          }
        });
      }
      
      // Synchronously initialize the stream when the first subscriber connects
      controller.onListen = initialize;
      
      return controller.stream;
    } catch (e) {
      debugPrint('FirebaseService: Error creating document stream: $e');
      return Stream.empty();
    }
  }
  
  // Check if user is authenticated
  bool get isAuthenticated {
    return FirebaseAuth.instance.currentUser != null;
  }
  
  // Get current user ID
  String? get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }
  
  // Get user profile information
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
      };
    }
    return {};
  }
  
  // Update user's display name
  Future<void> updateDisplayName(String displayName) async {
    await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
  }
  
  // Update user's email
  Future<void> updateEmail(String email) async {
    await FirebaseAuth.instance.currentUser?.updateEmail(email);
  }
  
  // Update user's password
  Future<void> updatePassword(String password) async {
    await FirebaseAuth.instance.currentUser?.updatePassword(password);
  }
  
  // Send email verification
  Future<void> sendEmailVerification() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }
  
  // Re-authenticate user
  Future<void> reauthenticate(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
  }
  
  // Sign in with email/password
  Future<dynamic> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return {'error': e.toString(), 'userId': null};
    }
  }
  
  // Create user with email/password
  Future<dynamic> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return {'error': e.toString(), 'userId': null};
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
  
  // Get ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
  }
  
  // Auth state changes
  Stream<User?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges();
  }
  
  // Firestore operations
  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    try {
      await _runOnPlatformThread<void>(() async {
        await _firestore.doc(path).set(data);
      });
    } catch (e) {
      debugPrint('FirebaseService: Error setting document: $e');
      rethrow;
    }
  }
  
  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    try {
      await _runOnPlatformThread<void>(() async {
        await _firestore.doc(path).update(data);
      });
    } catch (e) {
      debugPrint('FirebaseService: Error updating document: $e');
      rethrow;
    }
  }
  
  Future<DocumentSnapshot?> getDocument(String path) async {
    try {
      return await _runOnPlatformThread<DocumentSnapshot?>(() async {
        return await _firestore.doc(path).get();
      });
    } catch (e) {
      debugPrint('FirebaseService: Error getting document: $e');
      return null;
    }
  }
  
  // Get multiple documents from a query
  Future<QuerySnapshot?> getCollection(
    String path, {
    Query Function(Query query)? queryBuilder,
  }) async {
    try {
      return await _runOnPlatformThread<QuerySnapshot?>(() async {
        Query query = _firestore.collection(path);
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        return await query.get();
      });
    } catch (e) {
      debugPrint('FirebaseService: Error getting collection: $e');
      return null;
    }
  }
  
  // Add document to collection
  Future<DocumentReference?> addDocument(String path, Map<String, dynamic> data) async {
    try {
      return await _runOnPlatformThread<DocumentReference?>(() async {
        return await _firestore.collection(path).add(data);
      });
    } catch (e) {
      debugPrint('FirebaseService: Error adding document: $e');
      return null;
    }
  }
  
  // Delete document
  Future<void> deleteDocument(String path) async {
    try {
      await _runOnPlatformThread<void>(() async {
        await _firestore.doc(path).delete();
      });
    } catch (e) {
      debugPrint('FirebaseService: Error deleting document: $e');
      rethrow;
    }
  }
  
  // Clean up resources
  void dispose() {
    // Nothing to dispose in this simplified version
  }

  // Create a batch for multiple write operations
  WriteBatch createBatch() {
    return _firestore.batch();
  }
  
  // Execute a batch safely on the platform thread
  Future<void> executeBatchSafely(WriteBatch batch) async {
    try {
      await _runOnPlatformThread<void>(() async {
        await batch.commit();
      });
    } catch (e) {
      debugPrint('FirebaseService: Batch execution error: $e');
      rethrow;
    }
  }
  
  // Execute a transaction safely on the platform thread
  Future<T> runTransactionSafely<T>(
    Future<T> Function(Transaction transaction) transactionHandler
  ) async {
    try {
      return await _runOnPlatformThread<T>(() async {
        return await _firestore.runTransaction(transactionHandler);
      });
    } catch (e) {
      debugPrint('FirebaseService: Transaction error: $e');
      rethrow;
    }
  }
} 