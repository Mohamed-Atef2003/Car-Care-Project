import 'dart:math';

import '../models/car.dart';

// Car Management Service (can be changed to use a real database later)
class CarService {
  static final CarService _instance = CarService._internal();
  
  factory CarService() {
    return _instance;
  }
  
  CarService._internal();
  
  // Car list (can be replaced with a real database)
  final List<Car> _cars = [];
  
  // Cars for display as examples
  List<Car> get exampleCars {
    
    return _cars;
  }
  
  // Get all car brands
  List<String> getAllBrands() {
    return CarBrands.all;
  }
  
  // Get list of categorized car brands
  Map<String, List<String>> getCategorizedBrands() {
    return CarBrands.categorized;
  }
  
  // Get all cars
  List<Car> getAllCars() {
    return _cars;
  }
  

  // Add a new car
  void addCar(Car car) {
    final newCar = Car(
      id: _generateId(),
      brand: car.brand,
      model: car.model,
      trim: car.trim,
      engine: car.engine,
      version: car.version,
      modelYear: car.modelYear,
      carNumber: car.carNumber,
      carLicense: car.carLicense,
      imageUrl: car.imageUrl,
      customerId: car.customerId,
      color: car.color,
    );
    
    _cars.add(newCar);
  }
  
  // Add a new car using Firebase
  
  // Update existing car
  void updateCar(Car updatedCar) {
    final index = _cars.indexWhere((car) => car.id == updatedCar.id);
    if (index >= 0) {
      _cars[index] = updatedCar;
    }
  }
  
  // Delete a car
  void deleteCar(String id) {
    _cars.removeWhere((car) => car.id == id);
  }
  
  // Get a car by ID
  Car? getCarById(String id) {
    try {
      return _cars.firstWhere((car) => car.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }
} 