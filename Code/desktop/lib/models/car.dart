import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String customerId;
  final String brand;
  final String model;
  final String carNumber;
  final String carLicense;
  final String color;
  final String engine;
  final String modelYear;
  final String trim;
  final String version;
  final DateTime createdAt;
  
  Car({
    required this.id,
    required this.customerId,
    required this.brand,
    required this.model,
    required this.carNumber,
    required this.carLicense,
    required this.color,
    required this.engine,
    required this.modelYear,
    required this.trim,
    required this.version,
    required this.createdAt,
  });
  
  factory Car.fromFirestore(Map<String, dynamic> data, String id) {
    return Car(
      id: id,
      customerId: data['customerId'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      carNumber: data['carNumber'] ?? '',
      carLicense: data['carLicense'] ?? '',
      color: data['color'] ?? '',
      engine: data['engine'] ?? '',
      modelYear: data['modelYear'] ?? '',
      trim: data['trim'] ?? '',
      version: data['version'] ?? '',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'brand': brand,
      'model': model,
      'carNumber': carNumber,
      'carLicense': carLicense,
      'color': color,
      'engine': engine,
      'modelYear': modelYear,
      'trim': trim,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  String get displayName => '$brand $model $modelYear';
} 