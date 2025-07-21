import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyUpdate {
  final String message;
  final String author;
  final DateTime timestamp;

  EmergencyUpdate({
    required this.message,
    required this.author,
    required this.timestamp,
  });

  factory EmergencyUpdate.fromMap(Map<String, dynamic> map) {
    return EmergencyUpdate(
      message: map['message'] ?? '',
      author: map['author'] ?? '',
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'author': author,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class Emergency {
  final String id;
  // Customer information
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerId;
  // Vehicle information
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleNumber;
  final String? vehicleLicense;
  final int? vehicleYear;
  final String? vehicleId;
  // Service information
  final String serviceTitle;
  final String? serviceCost;
  final String? serviceEta;
  final bool isUrgent;
  // General information
  final String location;
  final String notes;
  final DateTime requestTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final List<EmergencyUpdate>? updates;

  Emergency({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.customerId,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleNumber,
    this.vehicleLicense,
    this.vehicleYear,
    this.vehicleId,
    required this.serviceTitle,
    this.serviceCost,
    this.serviceEta,
    required this.isUrgent,
    required this.location,
    required this.notes,
    required this.requestTime,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.updates,
  });

  factory Emergency.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Date parser function
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is DateTime) {
        return date;
      } else {
        return DateTime.now();
      }
    }

    // Extract customer data
    Map<String, dynamic>? customerData;
    if (data['customer'] is Map) {
      customerData = Map<String, dynamic>.from(data['customer'] as Map);
    }
    
    // Extract vehicle data
    Map<String, dynamic>? vehicleData;
    if (data['vehicle'] is Map) {
      vehicleData = Map<String, dynamic>.from(data['vehicle'] as Map);
    }
    
    // Extract service data
    Map<String, dynamic>? serviceData;
    if (data['service'] is Map) {
      serviceData = Map<String, dynamic>.from(data['service'] as Map);
    }

    // Parse updates if they exist
    List<EmergencyUpdate> parseUpdates(dynamic updatesData) {
      if (updatesData == null) return [];
      if (updatesData is List) {
        return updatesData
            .map((update) => EmergencyUpdate.fromMap(update as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    // Convert English status to English display text
    String getEnglishStatus(String englishStatus) {
      switch (englishStatus.toLowerCase()) {
        case 'new':
        case 'pending':
          return 'Pending';
        case 'confirmed':
        case 'in_progress':
        case 'assigned':
          return 'In Progress';
        case 'completed':
        case 'resolved':
          return 'Resolved';
        case 'cancelled':
          return 'Cancelled';
        default:
          return englishStatus;
      }
    }

    return Emergency(
      id: documentId,
      // Customer information
      customerName: customerData != null && customerData['name'] != null 
          ? customerData['name'] 
          : data['customerName'] ?? '',
      customerPhone: customerData != null && customerData['phone'] != null
          ? customerData['phone']
          : data['customerPhone'] ?? data['phoneNumber'] ?? '',
      customerEmail: customerData != null ? customerData['email'] : null,
      customerId: customerData != null ? customerData['id'] : null,
      // Vehicle information
      vehicleBrand: vehicleData != null ? vehicleData['brand'] : null,
      vehicleModel: vehicleData != null && vehicleData['model'] != null
          ? vehicleData['model']
          : data['carModel'],
      vehicleNumber: vehicleData != null ? vehicleData['carNumber'] : null,
      vehicleLicense: vehicleData != null ? vehicleData['carLicense'] : null,
      vehicleYear: vehicleData != null && vehicleData['modelYear'] is int 
          ? vehicleData['modelYear'] as int
          : null,
      vehicleId: vehicleData != null ? vehicleData['id'] : null,
      // Service information
      serviceTitle: serviceData != null && serviceData['title'] != null
          ? serviceData['title']
          : data['issue'] ?? '',
      serviceCost: serviceData != null ? serviceData['cost'] : null,
      serviceEta: serviceData != null ? serviceData['eta'] : null,
      isUrgent: serviceData != null && serviceData['urgent'] == true,
      // General information
      location: data['location'] ?? '',
      notes: data['notes'] ?? '',
      requestTime: data['requestTime'] != null 
          ? parseDate(data['requestTime']) 
          : parseDate(data['createdAt']),
      createdAt: data['createdAt'] != null ? parseDate(data['createdAt']) : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? parseDate(data['updatedAt']) : DateTime.now(),
      status: getEnglishStatus(data['status'] ?? 'pending'),
      updates: parseUpdates(data['updates']),
    );
  }

  // Convert Arabic status to English for Firebase
  static String getEnglishStatus(String arabicStatus) {
    switch (arabicStatus) {
      case 'Pending':
        return 'Pending';
      case 'In Progress':
        return 'In Progress';
      case 'Resolved':
        return 'Resolved';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return arabicStatus.toLowerCase();
    }
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'status': getEnglishStatus(status),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    
    // Only add structured fields if we have all necessary information
    if (customerId != null && customerName.isNotEmpty && customerPhone.isNotEmpty) {
      Map<String, dynamic> customerMap = {
        'id': customerId,
        'name': customerName,
        'phone': customerPhone,
      };
      
      if (customerEmail != null) {
        customerMap['email'] = customerEmail;
      }
      
      data['customer'] = customerMap;
    } else {
      // Otherwise, add flat fields
      data['customerName'] = customerName;
      data['phoneNumber'] = customerPhone;
      if (customerEmail != null) data['customerEmail'] = customerEmail;
    }
    
    // Add vehicle data if it exists
    if (vehicleId != null && vehicleModel != null) {
      Map<String, dynamic> vehicleMap = {
        'id': vehicleId,
        'model': vehicleModel,
      };
      
      if (vehicleBrand != null) vehicleMap['brand'] = vehicleBrand;
      if (vehicleNumber != null) vehicleMap['carNumber'] = vehicleNumber;
      if (vehicleLicense != null) vehicleMap['carLicense'] = vehicleLicense;
      if (vehicleYear != null) vehicleMap['modelYear'] = vehicleYear;
      
      data['vehicle'] = vehicleMap;
    } else if (vehicleModel != null) {
      data['carModel'] = vehicleModel;
    }
    
    // Add service data
    if (serviceTitle.isNotEmpty) {
      Map<String, dynamic> serviceMap = {
        'title': serviceTitle,
        'urgent': isUrgent,
      };
      
      if (serviceCost != null) serviceMap['cost'] = serviceCost;
      if (serviceEta != null) serviceMap['eta'] = serviceEta;
      
      data['service'] = serviceMap;
    } else {
      data['issue'] = serviceTitle;
    }
    
    // Add general information
    data['location'] = location;
    if (notes.isNotEmpty) data['notes'] = notes;
    data['requestTime'] = Timestamp.fromDate(requestTime);
    data['createdAt'] = Timestamp.fromDate(createdAt);
    
    // Add updates
    if (updates != null && updates!.isNotEmpty) {
      data['updates'] = updates!.map((update) => update.toMap()).toList();
    }
    
    return data;
  }
  
  // Helper method to get priority based on urgency
  String getPriorityText() {
    return isUrgent ? 'High' : 'Medium';
  }
  
  // Method to get formatted vehicle info
  String getVehicleInfo() {
    List<String> parts = [];
    
    if (vehicleBrand != null && vehicleBrand!.isNotEmpty) {
      parts.add(vehicleBrand!);
    }
    
    if (vehicleModel != null && vehicleModel!.isNotEmpty) {
      parts.add(vehicleModel!);
    }
    
    if (vehicleYear != null) {
      parts.add(vehicleYear.toString());
    }
    
    if (vehicleNumber != null && vehicleNumber!.isNotEmpty) {
      parts.add('(${vehicleNumber!})');
    }
    
    return parts.isNotEmpty ? parts.join(' ') : 'Not specified';
  }
} 