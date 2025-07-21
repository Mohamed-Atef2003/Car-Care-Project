import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../constants/colors.dart';
import '../../widgets/custom_button.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

// Define all classes at the top level
class EmergencyService {
  final String title;
  final IconData icon;
  final String description;
  final bool urgent;
  final String eta;
  final String cost;

  EmergencyService({
    required this.title,
    required this.icon,
    required this.description,
    required this.urgent,
    required this.eta,
    required this.cost,
  });
}

class EmergencyRequest {
  final EmergencyService service;
  final DateTime requestTime;
  EmergencyRequestStatus status;
  final String location;
  final String vehicle;
  final String notes;
  
  EmergencyRequest({
    required this.service,
    required this.requestTime,
    required this.status,
    required this.location,
    required this.vehicle,
    required this.notes,
  });
}

enum EmergencyRequestStatus {
  Pending,
  InProgress,
  Resolved,
  Cancelled,
}

class StatusInfo {
  final String message;
  final Color color;
  final IconData icon;
  
  StatusInfo({
    required this.message,
    required this.color,
    required this.icon,
  });
}

class EmergencyContact {
  final String name;
  final String phone;
  
  EmergencyContact({
    required this.name,
    required this.phone,
  });
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  // Add CarService
  final CarService _carService = CarService();
  late List<Car> _userCars = [];
  
  // Location variables
  
  // Controlador de texto para la dirección
  final TextEditingController _addressController = TextEditingController();
  
  // Remove _savedVehicles list since we'll use _userCars instead
  String? _selectedVehicleId;
  
  // Tab controller for emergency tips
  late TabController _tabController;
  
  // Emergency contacts
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(name: 'Highway Rescue', phone: '+2 012-2111-0000'),
    EmergencyContact(name: 'Ambulance', phone: '123'),
    EmergencyContact(name: 'Traffic Police', phone: '128'),
    EmergencyContact(name: 'Fire Department', phone: '180'),
    EmergencyContact(name: 'Electricity Emergency', phone: '121'),
    EmergencyContact(name: 'Gas Emergency', phone: '129'),
    EmergencyContact(name: 'Car Care Center', phone: '+2 012-0000-0000'),
  ];

  // List of emergency services
  final List<EmergencyService> _emergencyServices = [
    EmergencyService(
      title: 'Roadside Assistance',
      icon: Icons.car_repair,
      description: 'Get help with breakdowns, flat tires, or if you\'re stranded.',
      urgent: true,
      eta: '15-25 minutes',
      cost: '50-100 EGP',
    ),
    EmergencyService(
      title: 'Car Towing',
      icon: Icons.engineering,
      description: 'Towing service for complete breakdowns or accidents.',
      urgent: true,
      eta: '20-30 minutes',
      cost: '100-200 EGP',
    ),
    EmergencyService(
      title: 'Battery Replacement',
      icon: Icons.battery_alert,
      description: 'Replace or recharge your car battery if it\'s depleted.',
      urgent: false,
      eta: '15-20 minutes',
      cost: '30-80 EGP',
    ),
    EmergencyService(
      title: 'Tire Change',
      icon: Icons.tire_repair,
      description: 'Service to change or repair punctured or damaged tires.',
      urgent: false,
      eta: '15-20 minutes',
      cost: '40-60 EGP',
    ),
  ];

  String? _selectedLocation;
  final TextEditingController _noteController = TextEditingController();
  
  // Active emergency request
  EmergencyRequest? _activeRequest;
  
  // Firebase stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot>? _requestSubscription;
  
  // Request ID from Firebase
  String? _activeRequestId;
  
  // Timer for ETA countdown
  Timer? _etaTimer;
  int _etaMinutes = 0;
  
  // Add these variables at the top of the class with other variables
  double _progressValue = 0.0;
  int _totalMinutes = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserCars();
    _checkForActiveRequests();
  }

  // Get customer ID from UserProvider
  String _getCustomerId(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Make sure we have the correct user ID
    final userId = userProvider.user?.id;
    if (userId == null || userId.isEmpty) {
      print('Warning: User ID not available');
      return '';
    }
    return userId;
  }

  void _loadUserCars() async {
    try {
      final customerId = _getCustomerId(context);
      
      print('====== Starting car loading ======');
      print('Customer ID: $customerId');
      
      if (customerId.isEmpty) {
        // If user is not logged in, use example cars
        setState(() {
          _userCars = _carService.exampleCars;
        });
        print('Using example cars: User not logged in');
        return;
      }
      
      print('Loading user cars with ID: $customerId');
      
      // Firestore query to fetch user cars
      final QuerySnapshot carDocs = await FirebaseFirestore.instance
          .collection("cars")
          .where("customerId", isEqualTo: customerId)
          .get();
      
      print('Query result: ${carDocs.docs.length} cars');
      
      if (carDocs.docs.isEmpty) {
        print('No cars for user, will use example cars');
        setState(() {
          _userCars = _carService.exampleCars;
        });
        return;
      }

      // Convert data to Car objects
      final List<Car> loadedCars = carDocs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Convert model year - handle different types
        int modelYear;
        if (data['modelYear'] is int) {
          modelYear = data['modelYear'];
        } else if (data['modelYear'] is String) {
          modelYear = int.tryParse(data['modelYear'] ?? '0') ?? 0;
        } else {
          modelYear = 0;
        }
        
        return Car(
          id: doc.id,
          brand: data['brand'] ?? '',
          model: data['model'],
          trim: data['trim'],
          engine: data['engine'],
          version: data['version'],
          modelYear: modelYear,
          carNumber: data['carNumber'] ?? '',
          carLicense: data['carLicense'] ?? '',
          imageUrl: data['imageUrl'],
          // Make sure to store customer ID in the car object as well
          customerId: data['customerId'] ?? customerId,
          color: data['color'],
        );
      }).toList();

      setState(() {
        _userCars = loadedCars;
      });
      
      print('Loaded ${_userCars.length} cars for user');
      print('====== Finished loading cars ======');
      
    } catch (e) {
      print('Error loading cars: $e');
      // In case of error, use example cars
      setState(() {
        _userCars = _carService.exampleCars;
      });
      
      // Show error message if appropriate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cars'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to get car description
  String _getCarDescription(Car car) {
    return '${car.brand} ${car.modelYear} - ${car.carNumber}';
  }

  @override
  void dispose() {
    _noteController.dispose();
    _addressController.dispose();
    _tabController.dispose();
    _etaTimer?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmation(EmergencyService service) {
    // Calculate payment details (just for display)
    double.parse(service.cost.split('-').first.replaceAll(RegExp(r'[^\d.]'), ''));
    
    // Check if a car is selected
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a car to request service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get selected car information
    final selectedCar = _userCars.firstWhere(
      (car) => car.id == _selectedVehicleId,
      orElse: () => _carService.exampleCars.first,
    );
    
    // Make sure location information is available
    if (_selectedLocation == null || _selectedLocation!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify your location to request service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Create unique ID for the request
    final String emergencyId = FirebaseFirestore.instance.collection('emergency').doc().id;
    _activeRequestId = emergencyId;
    
    // Show loading indicator while saving data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending emergency request...'),
          ],
        ),
      ),
    );
    
    // Get user ID
    final String customerId = _getCustomerId(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    // Create request data
    Map<String, dynamic> emergencyData = {
      'id': emergencyId,
      'service': {
        'title': service.title,
        'cost': service.cost,
        'eta': service.eta,
        'urgent': service.urgent,
      },
      'customer': {
        'id': customerId,
        'name': '${user?.firstName ?? ""} ${user?.lastName ?? ""}',
        'phone': user?.mobile ?? "",
        'email': user?.email ?? "",
      },
      'vehicle': {
        'id': selectedCar.id,
        'brand': selectedCar.brand,
        'model': selectedCar.model,
        'modelYear': selectedCar.modelYear,
        'carNumber': selectedCar.carNumber,
        'carLicense': selectedCar.carLicense,
      },
      'location': _selectedLocation,
      'notes': _noteController.text,
      'status': 'Pending',
      'requestTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Save request data to Firestore
    FirebaseFirestore.instance
        .collection('emergency')
        .doc(emergencyId)
        .set(emergencyData)
        .then((_) {
          // Close dialog
          Navigator.pop(context);
          
          // Start listening for updates to this request
          _listenToRequestUpdates(emergencyId);
          
          // Show success message
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Help is on the way!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 64,
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOut)
                      .then()
                      .shake(hz: 2, curve: Curves.easeInOut),
                  const SizedBox(height: 16),
                  Text(
                    'Your ${service.title} request has been confirmed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service Provider: Premium Car Services\nEstimated Arrival Time: ${service.eta}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cost: ${service.cost} - Cash payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You will be contacted soon. You will receive updates about your request status.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    
                    // Create active request
                    setState(() {
                      _activeRequest = EmergencyRequest(
                        service: service,
                        requestTime: DateTime.now(),
                        status: EmergencyRequestStatus.Pending,
                        location: _selectedLocation ?? 'Current Location',
                        vehicle: '${selectedCar.brand} ${selectedCar.carNumber}',
                        notes: _noteController.text,
                      );
                      
                      // Start ETA countdown
                      _startEtaCountdown();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        })
        .catchError((error) {
          // Close dialog
          Navigator.pop(context);
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending request: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }
  
  void _startEtaCountdown() {
    _etaTimer?.cancel();
    
    // Initialize countdown values
    _totalMinutes = int.parse(_activeRequest!.service.eta.split('-').first);
    // Convert _totalMinutes from minutes to seconds
    final int totalSeconds = _totalMinutes * 60;
    _etaMinutes = totalSeconds;
    _progressValue = 0.0;
    
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        // Calculate progress - adjust the equation to ensure value between 0 and 1
        _progressValue = 1 - (_etaMinutes / totalSeconds);
        
        // Make sure the value is between 0 and 1
        _progressValue = _progressValue.clamp(0.0, 1.0);
        
        if (_etaMinutes > 0) {
          _etaMinutes--;
          
          // Update request status based on progress
          if (_progressValue >= 0.25 && _activeRequest?.status == EmergencyRequestStatus.Pending) {
            _activeRequest?.status = EmergencyRequestStatus.InProgress;
          }
          
          if (_progressValue >= 0.75 && _activeRequest?.status == EmergencyRequestStatus.InProgress) {
            _activeRequest?.status = EmergencyRequestStatus.Resolved;
          }
          
        } else {
          // Time's up
          _activeRequest?.status = EmergencyRequestStatus.Resolved;
          _progressValue = 1.0;
          timer.cancel();
        }
      });
    });
  }
  
  void _makeEmergencyCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Numbers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose the appropriate number to call',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Emergency services first
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(
                  Icons.emergency,
                  color: Colors.white,
                            size: 24,
                ),
              ),
              title: const Text(
                          'Emergency Police (122)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: const Text(
                          'For life-threatening emergency situations',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                icon: const Icon(Icons.call),
                color: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                              // Use the number directly without changes
                              _makePhoneCall('122');
                            },
                          ),
                        ),
                      ),
                    ),
                    // Other emergency contacts
                    ...List.generate(
                      (_emergencyContacts.length / 2).ceil(),
                      (rowIndex) {
                        final startIndex = rowIndex * 2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              for (var i = 0; i < 2; i++)
                                if (startIndex + i < _emergencyContacts.length)
                                  Expanded(
                                    child: Card(
                                      margin: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == 1 ? 0 : 4),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          Navigator.pop(context);
                                          final contact = _emergencyContacts[startIndex + i];
                                          // Use the phone number directly from the contact
                                          _makePhoneCall(contact.phone);
                                        },
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _emergencyContacts[startIndex + i].name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _emergencyContacts[startIndex + i].phone,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.call,
                                                  size: 16,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
  
  
  Widget _buildActiveRequestCard() {
    if (_activeRequest == null) return const SizedBox.shrink();
    
    final request = _activeRequest!;
    
    // Status indicators
    final statusInfo = _getStatusInfo(request.status);
    
    // Format the remaining time for display in minutes:seconds format
    String formattedRemainingTime = '';
    if (_etaMinutes > 0) {
      final int minutes = _etaMinutes ~/ 60;
      final int seconds = _etaMinutes % 60;
      formattedRemainingTime = '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusInfo.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusInfo.color,
                  child: Icon(
                    statusInfo.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active ${_activeRequest!.service.title} Request',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusInfo.message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRequestInfoItem(
                      Icons.timer,
                      'Estimated Time',
                      request.status == EmergencyRequestStatus.Resolved
                          ? 'Completed'
                          : request.status == EmergencyRequestStatus.Cancelled
                            ? 'Cancelled'
                            : formattedRemainingTime.isEmpty ? 'In progress' : formattedRemainingTime,
                    ),
                    _buildRequestInfoItem(
                      Icons.location_on,
                      'Location',
                      request.location,
                    ),
                    _buildRequestInfoItem(
                      Icons.directions_car,
                      'Vehicle',
                      request.vehicle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress indicator - only show for Pending and InProgress
                if (request.status == EmergencyRequestStatus.Pending || request.status == EmergencyRequestStatus.InProgress)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(statusInfo.color),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getProgressText(request.status),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                // Action Buttons
                if (request.status == EmergencyRequestStatus.Resolved || request.status == EmergencyRequestStatus.Cancelled)
                  // For completed or cancelled requests, show a button to dismiss the card
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _activeRequest = null;
                        _activeRequestId = null;
                        _requestSubscription?.cancel();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Dismiss'),
                  )
                else
                  // For active requests, show call service provider button and cancel option
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Determine the appropriate phone number based on service type
                            String phoneNumber;
                            
                            if (request.service.title == 'Roadside Assistance') {
                              phoneNumber =  '+2 012-0000-0000';
                            } else if (request.service.title == 'Car Towing') {
                              phoneNumber =  '+2 012-0000-0000';
                            } else {
                              phoneNumber =  '+2 012-0000-0000';
                            }
                            
                            // Call the service provider directly
                            _makePhoneCall(phoneNumber);
                          },
                          icon: const Icon(Icons.call),
                          label: const Text('Call Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: request.service.urgent ? Colors.red : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Only show cancel button for requests that are not completed
                      if (request.status == EmergencyRequestStatus.Pending)
                        ElevatedButton.icon(
                          onPressed: () {
                            _showCancelConfirmationDialog();
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.1, end: 0).fadeIn();
  }
  
  // Show confirmation dialog before cancelling request
  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel your emergency assistance request?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No, Keep Request'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelEmergencyRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Request'),
          ),
        ],
      ),
    );
  }
  
  // Cancel the active emergency request
  void _cancelEmergencyRequest() async {
    if (_activeRequestId == null) return;
    
    try {
      // Update the request status in Firestore
      await FirebaseFirestore.instance
          .collection('emergency')
          .doc(_activeRequestId)
          .update({
            'status': 'Cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency request cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // State updates will happen through the Firestore listener
    } catch (e) {
      print('Error cancelling request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildRequestInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  StatusInfo _getStatusInfo(EmergencyRequestStatus status) {
    switch (status) {
      case EmergencyRequestStatus.Pending:
        return StatusInfo(
          message: 'Service provider is on the way',
          color: Colors.blue,
          icon: Icons.time_to_leave,
        );
      case EmergencyRequestStatus.Resolved:
        return StatusInfo(
          message: 'Service completed',
          color: Colors.green,
          icon: Icons.verified,
        );
      case EmergencyRequestStatus.InProgress:
        return StatusInfo(
          message: 'Service in progress',
          color: Colors.orange,
          icon: Icons.build,
        );
      case EmergencyRequestStatus.Cancelled:
        return StatusInfo(
          message: 'Service cancelled',
          color: Colors.red,
          icon: Icons.cancel,
        );
      }
  }
  
  String _getProgressText(EmergencyRequestStatus status) {
    switch (status) {
      case EmergencyRequestStatus.Pending:
        return 'Searching for nearby service provider...';
      case EmergencyRequestStatus.InProgress:
        return 'Service provider is on the way to you...';
      case EmergencyRequestStatus.Resolved:
        return 'Service completed';
      case EmergencyRequestStatus.Cancelled:
        return 'Service cancelled';
      }
  }
  
  Widget _buildEmergencyTips() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Breakdown'),
              Tab(text: 'Flat Tire'),
              Tab(text: 'Battery'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTipList([
                  'Stop in a safe place away from traffic',
                  'Turn on hazard lights and use reflectors if available',
                  'Stay in your car if that\'s safer',
                  'Call for roadside assistance through this app',
                  'If the situation is unsafe, call emergency services immediately',
                ]),
                _buildTipList([
                  'Stop in a safe place and away from traffic',
                  'Use hand brakes and wheel locks if available',
                  'Place the spare tire and jack near the car',
                  'Loosen the lug nuts before lifting the car',
                  'Do not over-tighten lug nuts when replacing the tire',
                ]),
                _buildTipList([
                  'Ensure the problem is related to the battery',
                  'Never start a dead or frozen battery',
                  'Connect the battery cables in the correct order',
                  'Let the good battery run for a few minutes',
                  'Disconnect the cables in the reverse order',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTipList(List<String> tips) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tips[index],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Emergency Services',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need urgent help?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'For life-threatening situations, call 122',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Open emergency numbers dialog
                        _makeEmergencyCall();
                      },
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text(
                        'Call Emergency Services',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Active request card
            if (_activeRequest != null) _buildActiveRequestCard(),
            // Emergency tips card (only show if no active request)
            if (_activeRequest == null) _buildEmergencyTips(),
            // Services list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _emergencyServices.length,
                itemBuilder: (context, index) {
                  final service = _emergencyServices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _requestAssistance(service),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: service.urgent ? Colors.red.shade50 : AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    service.icon,
                                    color: service.urgent ? Colors.red : AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        service.description,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'Request Service',
                              onPressed: () => _requestAssistance(service),
                              isFullWidth: true,
                              icon: Icon(service.icon, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (index * 100).ms)
                      .slideY(begin: 0.1, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestAssistance(EmergencyService service) {
    // Use the current values from the state for local variables
    
    // Refresh the state
    setState(() {
      // This ensures we're using the most up-to-date values for the modal
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: service.urgent ? Colors.red.shade50 : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              service.icon,
                              color: service.urgent ? Colors.red : AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Request ${service.title}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Estimated Time: ${service.eta} | Estimated Cost: ${service.cost}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      // Vehicle selection
                      const Text(
                        'Select Vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _userCars.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.car_repair, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No cars available',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _userCars.length,
                              separatorBuilder: (context, index) => Divider(height: 1),
                              itemBuilder: (context, index) {
                                final car = _userCars[index];
                                final isSelected = car.id == _selectedVehicleId;
                                
                                return InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedVehicleId = car.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon for car
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _getCarColor(car).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.directions_car,
                                            color: _getCarColor(car),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Car details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${car.brand} ${car.model ?? ""}',
                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Model ${car.modelYear} - ${car.carNumber}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Selection indicator
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                          )
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Location selection - Reemplazamos el InkWell con TextFormField
                      const Text(
                        'Where do you need assistance?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter delivery address',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.my_location, color: AppColors.primary, size: 20),
                              onPressed: () {
                                _getUserLocation();
                              },
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value;
                          });
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Additional Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Describe your emergency situation...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add photos option
                      
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Service', service.title),
                            _buildSummaryRow('Estimated Cost', service.cost),
                            _buildSummaryRow('Estimated Time', service.eta),
                            if (_selectedVehicleId != null) 
                              _buildSummaryRow(
                                'Vehicle', 
                                _getCarDescription(_userCars.firstWhere((car) => car.id == _selectedVehicleId))
                            ),
                            if (_addressController.text.isNotEmpty) 
                              _buildSummaryRow('Location', _addressController.text),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showConfirmation(service);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: service.urgent ? Colors.red : AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                service.urgent ? 'Request Emergency' : 'Request Now',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========== Add other functions ===========
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean phone number
    phoneNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '');
    
    // Create URI for calling
    final Uri uri = Uri.parse('tel:$phoneNumber');
    
    try {
      // Open phone app directly
      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call number: $phoneNumber')),
      );
      print('Error launching phone call: $e');
    }
  }

  // Function to get current location
  
  // Function to get address from coordinates
  
  // Función para obtener la ubicación del usuario y actualizar el campo de texto
  Future<void> _getUserLocation() async {
    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Please enable it in app settings'),
          ),
        );
        return;
      }
      
      // Update the use of desiredAccuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      // Convertir coordenadas a dirección
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        final String address = 
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
        
        // Actualizar el controlador de texto y la ubicación seleccionada
        setState(() {
          _addressController.text = address;
          _selectedLocation = address;
        });

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error determining location: $e')),
      );
    }
  }

  // Getting the appropriate car color
  Color _getCarColor(Car car) {
    // Set colors based on car brand
    final String brand = car.brand.toLowerCase();
    
    if (brand.contains('toyota')) return Colors.red;
    if (brand.contains('honda')) return Colors.blue;
    if (brand.contains('nissan')) return Colors.indigo;
    if (brand.contains('bmw')) return Colors.blue.shade800;
    if (brand.contains('mercedes')) return Colors.black87;
    if (brand.contains('audi')) return Colors.grey.shade800;
    if (brand.contains('volkswagen')) return Colors.blue.shade900;
    if (brand.contains('ford')) return Colors.blue;
    if (brand.contains('chevrolet')) return Colors.amber;
    if (brand.contains('hyundai')) return Colors.blue.shade700;
    if (brand.contains('kia')) return Colors.red.shade700;
    if (brand.contains('mazda')) return Colors.red.shade900;
    if (brand.contains('subaru')) return Colors.blue.shade300;
    if (brand.contains('lexus')) return Colors.grey.shade700;

    // Default color if no match found
    return AppColors.primary;
  }

  // Check for active requests in Firebase
  void _checkForActiveRequests() async {
    try {
      final customerId = _getCustomerId(context);
      if (customerId.isEmpty) return;
      
      // Query for active requests (not cancelled or resolved)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('emergency')
          .where('customer.id', isEqualTo: customerId)
          .where('status', whereNotIn: ['Resolved', 'Cancelled'])
          .orderBy('requestTime', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        
        // Set up listener for real-time updates
        _listenToRequestUpdates(doc.id);
        
        // Create EmergencyService from data
        final service = EmergencyService(
          title: data['service']['title'],
          icon: _getIconForServiceTitle(data['service']['title']),
          description: '',
          urgent: data['service']['urgent'] ?? false,
          eta: data['service']['eta'] ?? '15-30 minutes',
          cost: data['service']['cost'] ?? '50-150 EGP',
        );
        
        // Create EmergencyRequest from data
        setState(() {
          _activeRequestId = doc.id;
          _activeRequest = EmergencyRequest(
            service: service,
            requestTime: (data['requestTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: _getStatusFromString(data['status'] ?? 'Pending'),
            location: data['location'] ?? 'Unknown location',
            vehicle: '${data['vehicle']['brand'] ?? 'Car'} ${data['vehicle']['carNumber'] ?? ''}',
            notes: data['notes'] ?? '',
          );
          
          // Start countdown only if not resolved or cancelled
          if (_activeRequest!.status != EmergencyRequestStatus.Resolved && 
              _activeRequest!.status != EmergencyRequestStatus.Cancelled) {
            _startEtaCountdown();
          }
        });
      }
    } catch (e) {
      print('Error checking for active requests: $e');
    }
  }
  
  // Listen to real-time updates for the active request
  void _listenToRequestUpdates(String requestId) {
    // Cancel any existing subscription
    _requestSubscription?.cancel();
    
    // Set up new listener
    _requestSubscription = FirebaseFirestore.instance
        .collection('emergency')
        .doc(requestId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            final status = _getStatusFromString(data['status'] ?? 'Pending');
            
            setState(() {
              if (_activeRequest != null) {
                // Update the active request status
                _activeRequest!.status = status;
                
                // If status is Resolved or Cancelled, keep showing but update status
                if (status == EmergencyRequestStatus.Resolved || 
                    status == EmergencyRequestStatus.Cancelled) {
                  // Stop the timer if it's running
                  _etaTimer?.cancel();
                  _progressValue = 1.0;
                }
              }
            });
          } else {
            // Request document no longer exists
            setState(() {
              _activeRequest = null;
              _activeRequestId = null;
            });
            _requestSubscription?.cancel();
          }
        }, onError: (e) {
          print('Error listening to request updates: $e');
        });
  }
  
  // Convert string status to EmergencyRequestStatus enum
  EmergencyRequestStatus _getStatusFromString(String status) {
    switch (status) {
      case 'Pending':
        return EmergencyRequestStatus.Pending;
      case 'InProgress':
        return EmergencyRequestStatus.InProgress;
      case 'Resolved':
        return EmergencyRequestStatus.Resolved;
      case 'Cancelled':
        return EmergencyRequestStatus.Cancelled;
      default:
        return EmergencyRequestStatus.Pending;
    }
  }
  
  // Helper method to get icon for service title
  IconData _getIconForServiceTitle(String title) {
    switch (title.toLowerCase()) {
      case 'roadside assistance':
        return Icons.car_repair;
      case 'car towing':
        return Icons.engineering;
      case 'battery replacement':
        return Icons.battery_alert;
      case 'tire change':
        return Icons.tire_repair;
      default:
        return Icons.car_repair;
    }
  }
} 