import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? carId;
  final String? carModel;
  final String? carBrand;
  final String? carNumber;
  final int? carYear;
  final String service;
  final String? serviceType;
  final String? serviceCategory;
  final String? serviceCenter;
  final String? center;
  final Map<String, dynamic>? serviceCenterDetails;
  final DateTime date;
  final String time;
  final String status;
  final String? notes;
  final String? problemDescription;
  final Map<String, dynamic>? issueDetails;
  final double? estimatedCost;
  final bool? isEmergency;
  final String? urgencyLevel;
  final bool? needsPickup;
  final String? reference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? serviceDetails;
  
  // Customer and car document references
  DocumentReference? get customerRef => 
      customerId != null ? FirebaseFirestore.instance.collection('customer_account').doc(customerId) : null;
  
  DocumentReference? get carRef => 
      carId != null ? FirebaseFirestore.instance.collection('cars').doc(carId) : null;

  // Static caches for customer and car data to reduce Firebase calls
  static final Map<String, Map<String, dynamic>?> _customerCache = {};
  static final Map<String, Map<String, dynamic>?> _carCache = {};
  
  // Static method to pre-load customer data in batches
  static Future<void> preloadCustomerData(List<String> customerIds) async {
    if (customerIds.isEmpty) return;
    
    // Take only uncached IDs
    final idsToFetch = customerIds.where((id) => !_customerCache.containsKey(id)).toList();
    if (idsToFetch.isEmpty) return;
    
    try {
      // Process in smaller batches to avoid overwhelming the platform thread
      for (int i = 0; i < idsToFetch.length; i += 5) {
        final int end = (i + 5 < idsToFetch.length) ? i + 5 : idsToFetch.length;
        final batch = idsToFetch.sublist(i, end);
        
        // Use a more controlled approach for fetching
        for (final id in batch) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('customer_account')
                .doc(id)
                .get(const GetOptions(source: Source.serverAndCache));
                
            if (doc.exists) {
              _customerCache[id] = doc.data();
            } else {
              _customerCache[id] = null; // Mark as not found
            }
            
            // Small delay to avoid flooding the platform thread
            await Future.delayed(const Duration(milliseconds: 20));
          } catch (e) {
            print('Error preloading customer data for ID $id: $e');
          }
        }
      }
    } catch (e) {
      print('Error in preloadCustomerData: $e');
    }
  }
  
  // Static method to pre-load car data in batches
  static Future<void> preloadCarData(List<String> carIds) async {
    if (carIds.isEmpty) return;
    
    // Take only uncached IDs
    final idsToFetch = carIds.where((id) => !_carCache.containsKey(id)).toList();
    if (idsToFetch.isEmpty) return;
    
    try {
      // Process in smaller batches to avoid overwhelming the platform thread
      for (int i = 0; i < idsToFetch.length; i += 5) {
        final int end = (i + 5 < idsToFetch.length) ? i + 5 : idsToFetch.length;
        final batch = idsToFetch.sublist(i, end);
        
        // Use a more controlled approach for fetching
        for (final id in batch) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('cars')
                .doc(id)
                .get(const GetOptions(source: Source.serverAndCache));
                
            if (doc.exists) {
              _carCache[id] = doc.data();
            } else {
              _carCache[id] = null; // Mark as not found
            }
            
            // Small delay to avoid flooding the platform thread
            await Future.delayed(const Duration(milliseconds: 20));
          } catch (e) {
            print('Error preloading car data for ID $id: $e');
          }
        }
      }
    } catch (e) {
      print('Error in preloadCarData: $e');
    }
  }

  Appointment({
    required this.id,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.carId,
    this.carModel,
    this.carBrand,
    this.carNumber,
    this.carYear,
    required this.service,
    this.serviceType,
    this.serviceCategory,
    this.serviceCenter,
    this.center,
    this.serviceCenterDetails,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
    this.problemDescription,
    this.issueDetails,
    this.estimatedCost,
    this.isEmergency,
    this.urgencyLevel,
    this.needsPickup,
    this.reference,
    required this.createdAt,
    required this.updatedAt,
    this.serviceDetails,
  });

  // Factory constructor to create an instance from a Firestore document
  factory Appointment.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Function to convert Timestamp, String or Map to DateTime
    DateTime parseDate(dynamic value) {
      if (value == null) {
        return DateTime.now();
      } else if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          // Try several date formats
          try {
            // Format dd/MM/yyyy
            final parts = value.split('/');
            if (parts.length == 3) {
              return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            }
          } catch (e) {}
          
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Extract data according to different formats
    final String appointmentId = documentId;
    String appointmentStatus = '';
    
    // Extract car model first
    String? carModel;
    if (data['carModel'] != null) {
      carModel = data['carModel'].toString();
    } else if (data['vehicle'] != null && data['vehicle']['model'] != null) {
      carModel = data['vehicle']['model'].toString();
    }
    
    // Extract customer name
    String customerName = '';
    if (data['customerName'] != null && data['customerName'].toString().isNotEmpty) {
      customerName = data['customerName'].toString();
    } else if (data['customerId'] != null && data['customerId'].toString().isNotEmpty) {
      // We'll let the UI fetch the customer name using customerId
      customerName = ''; // Will be fetched later
    } else if (data['vehicle'] != null && data['vehicle']['model'] != null) {
      customerName = 'Owner of ${data['vehicle']['model']}';
    } else if (carModel != null && carModel.isNotEmpty) {
      customerName = 'Owner of $carModel';
    } else if (data['customerPhone'] != null && data['customerPhone'].toString().isNotEmpty) {
      customerName = 'Customer: ${data['customerPhone']}';
    } else {
      customerName = 'Unknown Customer';
    }

    // Normalize status (convert English to English or from English)
    if (data['status'] != null) {
      switch (data['status'].toString().toLowerCase()) {
        case 'pending':
          appointmentStatus = 'Upcoming';
          break;
        case 'completed':
          appointmentStatus = 'Completed';
          break;
        case 'cancelled':
          appointmentStatus = 'Cancelled';
          break;
        default:
          appointmentStatus = data['status'].toString();
          break;
      }
    } else {
      appointmentStatus = 'Upcoming';
    }

    // Extract appointment date
    DateTime appointmentDate;
    if (data['appointmentDate'] != null) {
      appointmentDate = parseDate(data['appointmentDate']);
    } else if (data['date'] != null) {
      appointmentDate = parseDate(data['date']);
    } else {
      appointmentDate = DateTime.now();
    }

    // Extract appointment time
    String appointmentTime = '';
    if (data['appointmentTime'] != null) {
      appointmentTime = data['appointmentTime'].toString();
    } else if (data['time'] != null) {
      appointmentTime = data['time'].toString();
    }

    // Extract car brand
    String? carBrand;
    if (data['carBrand'] != null) {
      carBrand = data['carBrand'].toString();
    } else if (data['vehicle'] != null && data['vehicle']['brand'] != null) {
      carBrand = data['vehicle']['brand'].toString();
    }

    // Extract car license plate number
    String? carNumber;
    if (data['carNumber'] != null) {
      carNumber = data['carNumber'].toString();
    } else if (data['vehicle'] != null && data['vehicle']['carNumber'] != null) {
      carNumber = data['vehicle']['carNumber'].toString();
    }

    // Extract service
    String service = '';
    if (data['service'] != null) {
      service = data['service'].toString();
    } else if (data['serviceType'] != null) {
      service = data['serviceType'].toString();
    } else if (data['issue'] != null && data['issue']['type'] != null) {
      service = data['issue']['type'].toString();
    }

    // Extract service center
    String? serviceCenter;
    Map<String, dynamic>? serviceCenterDetails;
    if (data['serviceCenter'] != null) {
      if (data['serviceCenter'] is Map) {
        serviceCenterDetails = Map<String, dynamic>.from(data['serviceCenter']);
        serviceCenter = serviceCenterDetails['name']?.toString();
      } else {
        serviceCenter = data['serviceCenter'].toString();
      }
    }

    // Extract issue details
    Map<String, dynamic>? issueDetails;
    String? problemDescription;
    bool? isEmergency;
    String? urgencyLevel;
    bool? needsPickup;
    if (data['issue'] != null) {
      issueDetails = Map<String, dynamic>.from(data['issue']);
      problemDescription = issueDetails['description']?.toString();
      isEmergency = issueDetails['isEmergency'] as bool?;
      urgencyLevel = issueDetails['urgencyLevel']?.toString();
      needsPickup = issueDetails['needsPickup'] as bool?;
    }

    // Extract notes
    String? notes;
    if (data['notes'] != null) {
      notes = data['notes'].toString();
    }

    // Extract service details
    Map<String, dynamic>? serviceDetails;
    if (data['serviceDetails'] != null) {
      serviceDetails = Map<String, dynamic>.from(data['serviceDetails']);
    }

    return Appointment(
      id: appointmentId,
      customerId: data['customerId']?.toString(),
      customerName: customerName,
      customerPhone: data['customerPhone']?.toString(),
      customerEmail: data['customerEmail']?.toString(),
      carId: data['carId']?.toString(),
      carModel: carModel,
      carBrand: carBrand,
      carNumber: carNumber,
      carYear: data['carYear'] is int ? data['carYear'] : null,
      service: service,
      serviceType: data['serviceType']?.toString(),
      serviceCategory: data['serviceCategory']?.toString(),
      serviceCenter: serviceCenter,
      center: data['center']?.toString(),
      serviceCenterDetails: serviceCenterDetails,
      date: appointmentDate,
      time: appointmentTime,
      status: appointmentStatus,
      notes: notes,
      problemDescription: problemDescription,
      issueDetails: issueDetails,
      estimatedCost: data['estimatedCost'] is num ? data['estimatedCost'].toDouble() : null,
      isEmergency: isEmergency,
      urgencyLevel: urgencyLevel,
      needsPickup: needsPickup,
      reference: data['reference']?.toString(),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt'] ?? data['createdAt']),
      serviceDetails: serviceDetails,
    );
  }

  // Convert the appointment to a map to save in Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'id': id,
      'customerName': customerName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'status': status == 'Upcoming' ? 'pending' : status == 'Completed' ? 'completed' : 'cancelled',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    
    // Only add fields if they are not null
    if (customerId != null) data['customerId'] = customerId;
    if (customerPhone != null) data['customerPhone'] = customerPhone;
    if (customerEmail != null) data['customerEmail'] = customerEmail;
    if (carId != null) data['carId'] = carId;
    if (carModel != null) data['carModel'] = carModel;
    if (carBrand != null) data['carBrand'] = carBrand;
    if (carNumber != null) data['carNumber'] = carNumber;
    if (carYear != null) data['carYear'] = carYear;
    if (center != null) data['center'] = center;
    if (serviceType != null) data['serviceType'] = serviceType;
    if (serviceCategory != null) data['serviceCategory'] = serviceCategory;
    
    // Handle issue details
    if (problemDescription != null || urgencyLevel != null || needsPickup != null) {
      data['issue'] = {
        'type': service,
        'description': problemDescription ?? notes ?? '',
        'urgencyLevel': urgencyLevel ?? (isEmergency == true ? 'high' : 'normal'),
        'needsPickup': needsPickup ?? false
      };
    }
    
    // Handle service center details
    if (serviceCenterDetails != null) {
      data['serviceCenter'] = serviceCenterDetails;
    } else if (serviceCenter != null) {
      data['serviceCenter'] = serviceCenter;
    }
    
    // Add service details if available
    if (serviceDetails != null) {
      data['serviceDetails'] = serviceDetails;
    }
    
    // Add appointment date/time in formatted string format
    data['appointmentDate'] = '${date.day}/${date.month}/${date.year}';
    data['appointmentTime'] = time;
    
    if (notes != null && notes != problemDescription) data['notes'] = notes;
    if (estimatedCost != null) data['estimatedCost'] = estimatedCost;
    if (isEmergency != null) data['isEmergency'] = isEmergency;
    if (reference != null) data['reference'] = reference;
    
    return data;
  }
  
  // Method to get complete vehicle information
  String getVehicleInfo() {
    List<String> parts = [];
    if (carBrand != null && carBrand!.isNotEmpty) {
      parts.add(carBrand!);
    }
    if (carModel != null && carModel!.isNotEmpty) {
      parts.add(carModel!);
    }
    if (carYear != null) {
      parts.add(carYear.toString());
    }
    if (carNumber != null && carNumber!.isNotEmpty) {
      parts.add('(${carNumber!})');
    }
    
    return parts.isNotEmpty ? parts.join(' ') : 'Not specified';
  }

  // Get complete car data from Firestore (now with caching)
  Future<String> getCarDetails() async {
    // If we already have brand and model, use them
    if ((carBrand != null && carBrand!.isNotEmpty) || 
        (carModel != null && carModel!.isNotEmpty)) {
      return getVehicleInfo();
    }
    
    // Try to fetch car details using carId (now uses cache)
    if (carId != null && carId!.isNotEmpty) {
      final carDetails = await fetchCarDetails();
      if (carDetails != null) {
        List<String> parts = [];
        
        if (carDetails['brand'] != null && carDetails['brand'].toString().isNotEmpty) {
          parts.add(carDetails['brand'].toString());
        }
        
        if (carDetails['model'] != null && carDetails['model'].toString().isNotEmpty) {
          parts.add(carDetails['model'].toString());
        }
        
        if (carDetails['modelYear'] != null) {
          parts.add(carDetails['modelYear'].toString());
        }
        
        if (carDetails['carNumber'] != null && carDetails['carNumber'].toString().isNotEmpty) {
          parts.add('(${carDetails['carNumber']})');
        }
        
        if (parts.isNotEmpty) {
          return parts.join(' ');
        }
      }
      return 'Car ID: $carId';
    }
    
    return 'Not specified';
  }

  // Helper methods to fetch additional data
  Future<Map<String, dynamic>?> fetchCustomerDetails() async {
    if (customerId == null || customerId!.isEmpty) return null;
    
    // Check cache first
    if (_customerCache.containsKey(customerId)) {
      return _customerCache[customerId];
    }
    
    try {
      // Wrap the Firestore call to ensure it runs on the platform thread
      final docSnapshot = await FirebaseFirestore.instance
          .collection('customer_account')
          .doc(customerId)
          .get(const GetOptions(source: Source.serverAndCache));
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _customerCache[customerId!] = data; // Update cache
        return data;
      } else {
        _customerCache[customerId!] = null; // Cache negative result
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> fetchCarDetails() async {
    if (carId == null || carId!.isEmpty) return null;
    
    // Check cache first
    if (_carCache.containsKey(carId)) {
      return _carCache[carId];
    }
    
    try {
      // Wrap the Firestore call to ensure it runs on the platform thread
      final docSnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .doc(carId)
          .get(const GetOptions(source: Source.serverAndCache));
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _carCache[carId!] = data; // Update cache
        return data;
      } else {
        _carCache[carId!] = null; // Cache negative result
      }
    } catch (e) {
      print('Error fetching car details: $e');
    }
    return null;
  }

  // Get customer name - returns actual name or generated name (now with caching)
  Future<String> getCustomerName() async {
    // If we already have a name, return it
    if (customerName.isNotEmpty && customerName != 'Unknown Customer') {
      return customerName;
    }
    
    // Try to fetch customer details (now uses cache)
    if (customerId != null && customerId!.isNotEmpty) {
      final customerDetails = await fetchCustomerDetails();
      if (customerDetails != null) {
        final firstName = customerDetails['firstName']?.toString() ?? '';
        final lastName = customerDetails['lastName']?.toString() ?? '';
        
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          return '$firstName $lastName'.trim();
        } else if (customerDetails['name'] != null) {
          return customerDetails['name'].toString();
        } else if (customerDetails['mobile'] != null) {
          return 'Customer: ${customerDetails['mobile']}';
        } else if (customerDetails['email'] != null) {
          return 'Customer: ${customerDetails['email']}';
        }
      }
      return 'Customer ID: $customerId';
    }
    
    // Fallback options if we don't have customer name
    if (carModel != null && carModel!.isNotEmpty) {
      return 'Owner of $carModel';
    } else if (customerPhone != null && customerPhone!.isNotEmpty) {
      return 'Customer: $customerPhone';
    }
    
    return 'Unknown Customer';
  }
} 