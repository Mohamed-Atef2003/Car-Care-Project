import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String service;
  final DateTime date;
  final String time;
  final String carModel;
  final String carId;
  final String center;
  final Map<String, dynamic>? serviceCenter;
  final String? notes;
  final String status;

  AppointmentModel({
    required this.id,
    required this.service,
    required this.date,
    required this.time,
    required this.carModel,
    required this.carId,
    required this.center,
    this.serviceCenter,
    this.notes,
    this.status = 'pending', // Default status is 'pending'
  });

  // Convert from Firestore document
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    try {
      print('Converting document ${doc.id} to AppointmentModel');
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Extract id (use document ID if not specified)
      String id = data['id'] ?? doc.id;
      print('Document ID: $id');
      
      // Extract service type from any possible field
      String service = '';
      if (data['service'] != null) {
        service = data['service'].toString();
      } else if (data['serviceType'] != null) {
        service = data['serviceType'].toString();
      } else if (data['serviceCategory'] != null) {
        service = data['serviceCategory'].toString();
      } else if (data['type'] != null) {
        service = data['type'].toString();
      } else {
        service = 'Maintenance Service';
      }
      print('Service: $service');
      
      // Extract date from any possible field
      DateTime date = DateTime.now();
      if (data['date'] != null) {
        if (data['date'] is Timestamp) {
          date = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          try {
            date = DateTime.parse(data['date']);
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      } else if (data['appointmentDate'] != null) {
        if (data['appointmentDate'] is Timestamp) {
          date = (data['appointmentDate'] as Timestamp).toDate();
        } else if (data['appointmentDate'] is String) {
          try {
            date = DateTime.parse(data['appointmentDate']);
          } catch (e) {
            print('Error parsing appointmentDate: $e');
          }
        }
      } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
        date = (data['createdAt'] as Timestamp).toDate();
      }
      print('Date: $date');
      
      // Extract time from any possible field
      String time = '';
      if (data['time'] != null) {
        time = data['time'].toString();
      } else if (data['appointmentTime'] != null) {
        time = data['appointmentTime'].toString();
      }
      print('Time: $time');
      
      // Extract car info from any possible field
      String carModel = '';
      if (data['carModel'] != null) {
        carModel = data['carModel'].toString();
      } else if (data['car'] != null) {
        // If car is a map
        if (data['car'] is Map) {
          Map<String, dynamic> car = data['car'];
          List<String> carParts = [];
          
          if (car['brand'] != null) {
            carParts.add(car['brand'].toString());
          }
          
          if (car['model'] != null) {
            carParts.add(car['model'].toString());
          }
          
          if (car['year'] != null) {
            carParts.add(car['year'].toString());
          }
          
          carModel = carParts.join(' ');
        } 
        // If car is a string
        else if (data['car'] is String) {
          carModel = data['car'].toString();
        }
      } else if (data['vehicle'] != null) {
        if (data['vehicle'] is Map) {
          Map<String, dynamic> vehicle = data['vehicle'];
          List<String> vehicleParts = [];
          
          if (vehicle['brand'] != null) {
            vehicleParts.add(vehicle['brand'].toString());
          }
          
          if (vehicle['model'] != null) {
            vehicleParts.add(vehicle['model'].toString());
          }
          
          if (vehicle['year'] != null) {
            vehicleParts.add(vehicle['year'].toString());
          }
          
          carModel = vehicleParts.join(' ');
        } else if (data['vehicle'] is String) {
          carModel = data['vehicle'].toString();
        }
      }
      print('Car Model: $carModel');
      
      // Extract car ID from any possible field
      String carId = '';
      if (data['carId'] != null) {
        carId = data['carId'].toString();
      } else if (data['car'] != null && data['car'] is Map && data['car']['id'] != null) {
        carId = data['car']['id'].toString();
      } else if (data['vehicleId'] != null) {
        carId = data['vehicleId'].toString();
      } else if (data['vehicle'] != null && data['vehicle'] is Map && data['vehicle']['id'] != null) {
        carId = data['vehicle']['id'].toString();
      }
      print('Car ID: $carId');
      
      // Extract service center from any possible field
      String center = '';
      Map<String, dynamic>? serviceCenter;
      if (data['serviceCenter'] != null) {
        if (data['serviceCenter'] is Map) {
          serviceCenter = Map<String, dynamic>.from(data['serviceCenter']);
          center = serviceCenter['name']?.toString() ?? '';
        } else {
          center = data['serviceCenter'].toString();
        }
      } else if (data['center'] != null) {
        center = data['center'].toString();
      } else if (data['location'] != null) {
        center = data['location'].toString();
      }
      print('Service Center: $center');
      
      // Extract notes from any possible field
      String? notes;
      if (data['notes'] != null) {
        notes = data['notes'].toString();
      } else if (data['problemDescription'] != null) {
        notes = data['problemDescription'].toString();
      } else if (data['description'] != null) {
        notes = data['description'].toString();
      } else if (data['comment'] != null) {
        notes = data['comment'].toString();
      }
      print('Notes: $notes');
      
      // Extract status and convert to English
      String status = 'pending';
      if (data['status'] != null) {
        status = data['status'].toString().toLowerCase();
      }
      
      // Convert English status to appropriate format
      String englishStatus;
      switch (status) {
        case 'pending':
          englishStatus = 'pending';
          break;
        case 'completed':
          englishStatus = 'completed';
          break;
        case 'cancelled':
        case 'canceled':
          englishStatus = 'canceled';
          break;
        case 'قادم':
          englishStatus = 'pending';
          break;
        case 'مكتمل':
          englishStatus = 'completed';
          break;
        case 'ملغي':
          englishStatus = 'canceled';
          break;
        default:
          englishStatus = 'pending'; // Default
      }
      print('Status: $englishStatus');
      
      return AppointmentModel(
        id: id,
        service: service,
        date: date,
        time: time,
        carModel: carModel.isEmpty ? 'Not specified' : carModel,
        carId: carId.isEmpty ? 'Not specified' : carId,
        center: center.isEmpty ? 'Not specified' : center,
        serviceCenter: serviceCenter,
        notes: notes,
        status: englishStatus,
      );
    } catch (e) {
      print('Error converting document to AppointmentModel: $e');
      // Return a default appointment in case of error
      return AppointmentModel(
        id: doc.id,
        service: 'Unknown Service',
        date: DateTime.now(),
        time: '',
        carModel: 'Not specified',
        carId: 'Not specified',
        center: 'Not specified',
        status: 'pending',
      );
    }
  }

  // Create from Map
  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    DateTime date;
    if (map['date'] is DateTime) {
      date = map['date'];
    } else if (map['date'] is Timestamp) {
      date = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      try {
        date = DateTime.parse(map['date']);
      } catch (e) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    return AppointmentModel(
      id: map['id'] ?? '',
      service: map['service'] ?? '',
      date: date,
      time: map['time'] ?? '',
      carModel: map['carModel'] ?? '',
      carId: map['carId'] ?? '',
      center: map['center'] ?? '',
      serviceCenter: map['serviceCenter'],
      notes: map['notes'],
      status: map['status'] ?? 'pending',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'service': service,
      'date': date,
      'time': time,
      'carModel': carModel,
      'carId': carId,
      'center': center,
      'serviceCenter': serviceCenter,
      'notes': notes,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to Map (for local usage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service': service,
      'date': date,
      'time': time,
      'carModel': carModel,
      'carId': carId,
      'center': center,
      'serviceCenter': serviceCenter,
      'notes': notes,
      'status': status,
    };
  }

  // Create a copy of the appointment with some fields updated
  AppointmentModel copyWith({
    String? id,
    String? service,
    DateTime? date,
    String? time,
    String? carModel,
    String? carId,
    String? center,
    Map<String, dynamic>? serviceCenter,
    String? notes,
    String? status,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      service: service ?? this.service,
      date: date ?? this.date,
      time: time ?? this.time,
      carModel: carModel ?? this.carModel,
      carId: carId ?? this.carId,
      center: center ?? this.center,
      serviceCenter: serviceCenter ?? this.serviceCenter,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
} 