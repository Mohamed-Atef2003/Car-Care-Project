import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';
class AppointmentService {
  // Singleton pattern
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  // Information about the Firestore collection used
  String currentCollection = 'appointment';
  String alternativeCollection = 'appointments';
  CollectionReference get _appointmentCollection => FirebaseFirestore.instance.collection(currentCollection);

  // Get information about the current collection
  String getCurrentCollection() {
    return currentCollection;
  }

  // Toggle collection for testing
  void toggleCollection() {
    if (currentCollection == 'appointment') {
      currentCollection = 'appointments';
    } else {
      currentCollection = 'appointment';
    }
    print('Collection switched to: $currentCollection');
  }

  // Lists to store appointments by status (used as caches)
  final List<AppointmentModel> _upcomingAppointments = [];
  final List<AppointmentModel> _completedAppointments = [];
  final List<AppointmentModel> _canceledAppointments = [];

  // Fetch user appointments
  Future<void> fetchUserAppointments(String userId) async {
    if (userId.isEmpty) {
      print('fetchUserAppointments: userId is empty');
      return;
    }
    
    print('fetchUserAppointments: Fetching appointments for userId: $userId');
    
    // Reset lists
    _upcomingAppointments.clear();
    _completedAppointments.clear();
    _canceledAppointments.clear();
    
    try {
      bool success = false;
      
      // First attempt: Search in 'appointment' collection using customerId
      success = await _tryFetchFromCollection('appointment', 'customerId', userId);
      
      // Second attempt: Search in 'appointment' collection using userId
      if (!success) {
        success = await _tryFetchFromCollection('appointment', 'userId', userId);
      }
      
      // Third attempt: Search in 'appointment' collection using customer.id
      if (!success) {
        success = await _tryFetchFromCollection('appointment', 'customer.id', userId);
      }
      
      // Fourth attempt: Search in 'appointments' collection using customerId
      if (!success) {
        success = await _tryFetchFromCollection('appointments', 'customerId', userId);
      }
      
      // Fifth attempt: Search in 'appointments' collection using userId
      if (!success) {
        success = await _tryFetchFromCollection('appointments', 'userId', userId);
      }
      
      // Sixth attempt: Search in 'appointments' collection using customer.id
      if (!success) {
        success = await _tryFetchFromCollection('appointments', 'customer.id', userId);
      }
      
      // If all attempts fail, try to get all documents and filter manually
      if (!success) {
        print('All query attempts failed - trying manual filtering');
        
        // Try to fetch all documents from both collections and filter manually
        await _fetchAllAppointmentsAndFilter(userId);
      }
      
      // Print fetch results
      print('Final results:');
      print('Upcoming appointments: ${_upcomingAppointments.length}');
      print('Completed appointments: ${_completedAppointments.length}');
      print('Canceled appointments: ${_canceledAppointments.length}');
      
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }
  
  // Try query with specific collection and field
  Future<bool> _tryFetchFromCollection(String collection, String field, String userId) async {
    try {
      print('Trying collection: $collection, field: $field, userId: $userId');
      
      QuerySnapshot snapshot;
      
      // Special query for nested field customer.id
      if (field == 'customer.id') {
        snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('customer.id', isEqualTo: userId)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where(field, isEqualTo: userId)
            .get();
      }
      
      print('Found ${snapshot.docs.length} documents in $collection with $field = $userId');
      
      if (snapshot.docs.isEmpty) {
        return false;
      }
      
      // Process documents and convert them to AppointmentModel objects
      for (var doc in snapshot.docs) {
        try {
          final appointment = AppointmentModel.fromFirestore(doc);
          
          // Add appointment to the appropriate list based on status
          if (appointment.status == 'upcoming' || appointment.status == 'pending' || appointment.status == 'upcoming') {
            _upcomingAppointments.add(appointment);
          } else if (appointment.status == 'completed' || appointment.status == 'completed') {
            _completedAppointments.add(appointment);
          } else if (appointment.status == 'canceled' || appointment.status == 'canceled') {
            _canceledAppointments.add(appointment);
          }
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Error in _tryFetchFromCollection with $collection and $field: $e');
      return false;
    }
  }
  
  // Try to fetch all documents and filter manually
  Future<void> _fetchAllAppointmentsAndFilter(String userId) async {
    try {
      print('Fetching all appointments and filtering manually');
      
      // Get all documents from the first collection
      final appointmentSnapshot = await FirebaseFirestore.instance
          .collection('appointment')
          .get();
          
      print('Found ${appointmentSnapshot.docs.length} total documents in appointment collection');
      
      // Get all documents from the second collection
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
          
      print('Found ${appointmentsSnapshot.docs.length} total documents in appointments collection');
      
      // Merge documents from both collections
      final allDocs = [...appointmentSnapshot.docs, ...appointmentsSnapshot.docs];
      print('Total documents from both collections: ${allDocs.length}');
      
      // Filter and process documents manually
      int processedCount = 0;
      
      for (var doc in allDocs) {
        try {
          Map<String, dynamic> data = doc.data();
          
          // Print debug info for the document
          print('Document ID: ${doc.id}');
          if (data.containsKey('customerId')) print('customerId: ${data['customerId']}');
          if (data.containsKey('userId')) print('userId: ${data['userId']}');
          if (data.containsKey('customer')) {
            if (data['customer'] is Map) {
              print('customer.id: ${(data['customer'] as Map)['id']}');
            }
          }
          
          // Check any field that might contain the user ID
          bool isUserAppointment = false;
          
          if (data['customerId'] == userId) {
            print('✓ customerId match found');
            isUserAppointment = true;
          } else if (data['userId'] == userId) {
            print('✓ userId match found');
            isUserAppointment = true;
          } else if (data['customer'] != null && data['customer'] is Map) {
            Map customerData = data['customer'] as Map;
            if (customerData['id'] == userId) {
              print('✓ customer.id match found');
              isUserAppointment = true;
            }
          }
          
          if (isUserAppointment) {
            processedCount++;
            print('Creating AppointmentModel from document ${doc.id}');
            final appointment = AppointmentModel.fromFirestore(doc);
            
            // Add appointment to the appropriate list based on status
            if (appointment.status == 'upcoming' || appointment.status == 'pending' || appointment.status == 'upcoming') {
              _upcomingAppointments.add(appointment);
            } else if (appointment.status == 'completed' || appointment.status == 'completed') {
              _completedAppointments.add(appointment);
            } else if (appointment.status == 'canceled' || appointment.status == 'canceled') {
              _canceledAppointments.add(appointment);
            }
          }
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
        }
      }
      
      print('Successfully processed $processedCount appointments manually');
    } catch (e) {
      print('Error in _fetchAllAppointmentsAndFilter: $e');
    }
  }

  // Get appointments by status
  List<AppointmentModel> getUpcomingAppointments() => List.unmodifiable(_upcomingAppointments);
  List<AppointmentModel> getCompletedAppointments() => List.unmodifiable(_completedAppointments);
  List<AppointmentModel> getCanceledAppointments() => List.unmodifiable(_canceledAppointments);

  // Add a new appointment to the appropriate list
  void addAppointment(AppointmentModel appointment) {
    switch (appointment.status.toLowerCase()) {
      case 'upcoming':
      case 'pending':
      
        _upcomingAppointments.insert(0, appointment);
        break;
      case 'completed':
      
        _completedAppointments.insert(0, appointment);
        break;
      case 'canceled':
      
        _canceledAppointments.insert(0, appointment);
        break;
      default:
        _upcomingAppointments.insert(0, appointment);
    }
  }

  // Create a new appointment in Firestore
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = _appointmentCollection.doc();
      final data = appointment.toFirestore();
      
      // Add creation timestamp and ID
      final appointmentWithMetadata = {
        ...data,
        'id': appointment.id.isEmpty ? docRef.id : appointment.id,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(appointmentWithMetadata);
      print('Successfully created appointment: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Update appointment status in Firestore and local cache
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    if (appointmentId.isEmpty) {
      print('appointmentId is empty, cannot update appointment');
      return;
    }
    
    try {
    // Find appointment in any list
    AppointmentModel? appointment = _findAppointmentInAllLists(appointmentId);
      if (appointment == null) {
        print('Appointment not found: $appointmentId');
        return;
      }

    // Remove from current list
    _removeAppointmentFromAllLists(appointmentId);

    // Create updated appointment
      final updatedAppointment = appointment.copyWith(status: newStatus);

    // Add to appropriate list
    addAppointment(updatedAppointment);
      
      // Convert status from Arabic to English for storage
      String statusForDb;
      switch (newStatus.toLowerCase()) {
        case 'canceled':
          statusForDb = 'canceled';
          break;
        case 'completed':
          statusForDb = 'completed';
          break;
        case 'upcoming':
          statusForDb = 'pending';
          break;
        default:
          statusForDb = newStatus;
      }
      
      // Update in Firestore
      await _appointmentCollection
          .doc(appointmentId)
          .update({
            'status': statusForDb,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
      print('Successfully updated appointment status in Firestore: $appointmentId');
    } catch (e) {
      print('Error updating appointment status in Firestore: $e');
      rethrow;
    }
  }

  // Cancel appointment in Firestore and local cache
  Future<void> cancelAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      print('appointmentId is empty, cannot cancel appointment');
      return;
    }
    
    try {
      // Find appointment in any list
      AppointmentModel? appointment = _findAppointmentInAllLists(appointmentId);
      if (appointment == null) {
        print('Appointment not found: $appointmentId');
        return;
      }

      // Remove from current list
      _removeAppointmentFromAllLists(appointmentId);
      
      // Create cancelled appointment
      final canceledAppointment = appointment.copyWith(status: 'canceled');
    _canceledAppointments.insert(0, canceledAppointment);
      
      // Update in Firestore
      await _appointmentCollection
          .doc(appointmentId)
          .update({
            'status': 'canceled',
            'updatedAt': FieldValue.serverTimestamp(),
            'canceledAt': FieldValue.serverTimestamp(),
          });
          
      print('Successfully canceled appointment in Firestore: $appointmentId');
    } catch (e) {
      print('Error canceling appointment: $e');
      rethrow;
    }
  }

  // Helper method to find appointment in all lists
  AppointmentModel? _findAppointmentInAllLists(String appointmentId) {
    try {
      // Try upcoming appointments
      for (var appointment in _upcomingAppointments) {
        if (appointment.id == appointmentId) {
          return appointment;
        }
      }
      
      // Try completed appointments
      for (var appointment in _completedAppointments) {
        if (appointment.id == appointmentId) {
          return appointment;
        }
      }
      
      // Try canceled appointments
      for (var appointment in _canceledAppointments) {
        if (appointment.id == appointmentId) {
          return appointment;
        }
      }
      
      return null;
    } catch (e) {
      print('Error finding appointment: $e');
      return null;
    }
  }

  // Helper method to remove appointment from all lists
  void _removeAppointmentFromAllLists(String appointmentId) {
    _upcomingAppointments.removeWhere((a) => a.id == appointmentId);
    _completedAppointments.removeWhere((a) => a.id == appointmentId);
    _canceledAppointments.removeWhere((a) => a.id == appointmentId);
  }

  // Get all appointments
  List<AppointmentModel> getAllAppointments() {
    return [
      ..._upcomingAppointments,
      ..._completedAppointments,
      ..._canceledAppointments
    ];
  }

  // Get appointment by ID
  AppointmentModel? getAppointmentById(String appointmentId) {
    return _findAppointmentInAllLists(appointmentId);
  }
  
  // Get appointment by ID directly from Firestore
  Future<AppointmentModel?> getAppointmentByIdFromFirestore(String appointmentId) async {
    try {
      final doc = await _appointmentCollection.doc(appointmentId).get();
      if (doc.exists) {
        return AppointmentModel.fromFirestore(doc);
      } else {
        print('Appointment not found in Firestore: $appointmentId');
        return null;
      }
    } catch (e) {
      print('Error fetching appointment from Firestore: $e');
      return null;
    }
  }
} 