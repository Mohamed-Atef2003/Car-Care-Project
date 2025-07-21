import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'service_detail_page.dart';
import '../../models/car.dart';
import '../../screens/cars/my_cars_screen.dart';
import '../appointments/my_appointments_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'service_centers_screen.dart'; // Import service centers screen
import 'package:geolocator/geolocator.dart';

class ElectricityServicePage extends StatefulWidget {
  const ElectricityServicePage({super.key});

  @override
  State<ElectricityServicePage> createState() => _ElectricityServicePageState();
}

class _ElectricityServicePageState extends State<ElectricityServicePage> {
  // Variables to track selected options
  String _selectedServiceType = 'Electrical System Check';
  bool _needsEmergencyService = false;
  DateTime _serviceDate = DateTime.now().add(const Duration(days: 1));
  late TimeOfDay _serviceTime;
  final TextEditingController _problemDescriptionController = TextEditingController();
  final TextEditingController _vehicleDetailsController = TextEditingController();

  // Add variables for cars
  Car? _selectedCar;
  List<Car> _userCars = [];
  
  // Add variable for selected service center
  Map<String, dynamic>? _selectedServiceCenter;
  
  // Current user position for distance calculation
  Position? _currentPosition;

  // List of electrical service types
  late List<String> _serviceTypes = [
    'Electrical System Check',
    'Battery Repair',
    'Lighting System Maintenance',
    'Starter System Repair',
    'Alternator Repair',
    'Electronic Control Systems Repair',
    'Audio and Entertainment System Repair',
    'Sensors and Detection Systems Repair',
    'Electrical AC System Repair',
    'Electrical Circuit Problems Repair',
    'Electrical Inspection'
  ];
  
  bool _isLoading = false; // Add loading variable
  
  @override
  void initState() {
    super.initState();
    
    // Set default service time to 8:00 AM
    _serviceTime = const TimeOfDay(hour: 8, minute: 0);
    
    // Ensure no duplicate values in the service types list in a more comprehensive way
    final List<String> uniqueServiceTypes = [];
    final Set<String> serviceSet = {};
    
    for (final type in _serviceTypes) {
      if (!serviceSet.contains(type)) {
        serviceSet.add(type);
        uniqueServiceTypes.add(type);
      }
    }
    
    _serviceTypes = uniqueServiceTypes;
    
    // Make sure the selected value exists in the list
    if (!_serviceTypes.contains(_selectedServiceType)) {
      _selectedServiceType = _serviceTypes.first;
    }
    
    _loadUserCars();
    
    // Initialize selected service center if available
    if (ServiceCentersScreen.serviceCenters.isNotEmpty) {
      _selectedServiceCenter = ServiceCentersScreen.serviceCenters.first;
    }
    
    // Get current location for distance calculation
    _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        return;
      }
      
      // Get the current position
      Position position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _currentPosition = position;
        // Update distances after getting location
        _updateServiceCenterDistances();
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }
  
  // Calculate real distances between user location and service centers
  void _updateServiceCenterDistances() {
    if (_currentPosition == null) {
      // If no position is available, set default distance
      for (var center in ServiceCentersScreen.serviceCenters) {
        if (center['distance'] == null) {
          center['distance'] = 0.0; // Default value when location is not available
        }
      }
      return;
    }
    
    // Update distances in all service centers
    for (var center in ServiceCentersScreen.serviceCenters) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        center['latitude'],
        center['longitude']
      );
      
      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = (distanceInMeters / 1000);
      center['distance'] = double.parse(distanceInKm.toStringAsFixed(1));
    }
    
    // If a center is selected, update its distance too
    if (_selectedServiceCenter != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _selectedServiceCenter!['latitude'],
        _selectedServiceCenter!['longitude']
      );
      
      double distanceInKm = (distanceInMeters / 1000);
      _selectedServiceCenter!['distance'] = double.parse(distanceInKm.toStringAsFixed(1));
    }
    
    // Rebuild UI to reflect new distances
    if (mounted) {
      setState(() {});
    }
  }

  // Load user cars
  void _loadUserCars() async {
    try {
      // Get current user ID from the user provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null || userProvider.user!.id == null) {
        setState(() {
          _userCars = []; // No registered user
        });
        return;
      }
      
      final userId = userProvider.user!.id;
      
      // Fetch cars from Firestore
      final QuerySnapshot carSnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: userId)
          .get();
      
      if (!mounted) return; // Check if the widget is still mounted
      
      if (carSnapshot.docs.isEmpty) {
        setState(() {
          _userCars = [];
        });
        return;
      }
      
      final List<Car> cars = [];
      for (var doc in carSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Process model year (could be text or number)
        int modelYear;
        if (data['modelYear'] is String) {
          modelYear = int.tryParse(data['modelYear'] ?? '0') ?? 0;
        } else {
          modelYear = (data['modelYear'] ?? 0) as int;
        }
        
        cars.add(Car(
          id: doc.id,
          brand: data['brand'] ?? '',
          model: data['model'] ?? '',
          modelYear: modelYear,
          carNumber: data['carNumber'] ?? '',
          customerId: data['customerId'] ?? '',
          carLicense: data['carLicense'] ?? '',
        ));
      }
      
      if (!mounted) return; // Check again if the widget is still mounted
      
      setState(() {
        _userCars = cars;
        // Select the first car if the list is not empty
        if (_userCars.isNotEmpty) {
          _selectedCar = _userCars.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading cars: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _userCars = [];
      });
    }
  }

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    _vehicleDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (picked != null && picked != _serviceDate) {
      setState(() {
        _serviceDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _serviceTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue[700]!, // Use app primary color
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700], // Text color
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: child!,
            ),
          ),
        );
      },
      // Restrict time selection between 8:00 AM and 8:00 PM
      initialEntryMode: TimePickerEntryMode.dial,
    );
    
    if (time != null) {
      // Check if the selected time is within the allowed range
      final selectedDateTime = DateTime(
        _serviceDate.year,
        _serviceDate.month,
        _serviceDate.day,
        time.hour,
        time.minute,
      );
      
      final minTime = DateTime(
        _serviceDate.year,
        _serviceDate.month,
        _serviceDate.day,
        8, // 8:00 AM
        0,
      );
      
      final maxTime = DateTime(
        _serviceDate.year,
        _serviceDate.month,
        _serviceDate.day,
        20, // 8:00 PM
        0,
      );
      
      if (selectedDateTime.isBefore(minTime)) {
        // If before 8:00 AM, set to 8:00 AM
        setState(() {
          _serviceTime = const TimeOfDay(hour: 8, minute: 0);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Service hours start at 8:00 AM', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (selectedDateTime.isAfter(maxTime)) {
        // If after 8:00 PM, set to 8:00 PM
        setState(() {
          _serviceTime = const TimeOfDay(hour: 20, minute: 0);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Service hours end at 8:00 PM', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Time is within range, use it
        setState(() {
          _serviceTime = time;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Comprehensive Electrical System Diagnosis',
        'description': 'Complete inspection of all electrical systems in your car with a detailed report'
      },
      {
        'title': 'Advanced Battery Repair and Maintenance',
        'description': 'Battery condition diagnosis, charging or replacement with modern technologies'
      },
      {
        'title': 'Hybrid and Electric Vehicle Repair Service',
        'description': 'Specialized team for maintenance and repair of advanced systems in modern vehicles'
      },
      {
        'title': 'Electronic Control Systems Repair',
        'description': 'Maintenance and repair of Electronic Control Units (ECU) and related systems'
      },
      {
        'title': 'Advanced Lighting Systems Maintenance',
        'description': 'Repair and upgrade of LED, Xenon and smart lighting systems'
      },
      {
        'title': 'Electrical Emergency Service',
        'description': 'Fast 24/7 service for electrical emergencies'
      },
    ];

    final packages = [
      {
        'name': 'Basic Electrical Inspection',
        'price': 299,
        'features': [
          'Car battery check',
          'Diagnosis of simple electrical problems',
          'Basic lighting system check',
          'Starter system check',
          'Vehicle electrical condition report',
        ],
      },
      {
        'name': 'Comprehensive Electrical Maintenance',
        'price': 599,
        'features': [
          'Complete electrical system check',
          'Battery and charging system maintenance',
          'Electrical circuit repair',
          'Lighting system check and repair',
          'Sensor devices check and repair',
          '3-month warranty on all repairs',
        ],
      },
      {
        'name': 'Smart and Electric Vehicles Service',
        'price': 999,
        'features': [
          'Advanced diagnosis with latest equipment',
          'Electric and hybrid vehicle systems maintenance',
          'Advanced electronic control unit repair',
          'Smart vehicle system programming',
          'Electric vehicle battery check and maintenance',
          '6-month warranty on all repairs',
          'Regular follow-up service',
        ],
      },
    ];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 131, 190, 238),
          elevation: 0,
          title: const Text(
            'Electrical Systems Services',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildServiceBanner(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                _buildServiceOptions(),
                      const SizedBox(height: 20),
                _buildSchedulingSection(),
                      const SizedBox(height: 20),
                _buildProblemDescriptionSection(),
                      const SizedBox(height: 20),
                _buildEmergencyServiceSection(),
                const SizedBox(height: 24),
                _buildViewDetailedServicesButton(features, packages),
                      const SizedBox(height: 24),
                _buildSubmitButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceBanner() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.blue[500]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -50,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          // Icon
          Positioned(
            right: 30,
            bottom: 20,
            child: Icon(
              FontAwesomeIcons.boltLightning,
              size: 70,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.bolt,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Available 24/7',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Expert Electrical System Solutions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Professional diagnostics and repair for all car electrical systems',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildBannerFeature(FontAwesomeIcons.shield, 'Certified Experts'),
                    const SizedBox(width: 16),
                    _buildBannerFeature(FontAwesomeIcons.thumbsUp, 'Guaranteed Service'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBannerFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: Padding(
        padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.screwdriverWrench,
                  color: Colors.blue[700],
                  size: 16,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
                // Service type
                const Text(
                  'Select Electrical Service Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedServiceType,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
                  items: _serviceTypes.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedServiceType = value!;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Service Center
            const Text(
              'Select Service Center',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  _selectedServiceCenter == null 
                      ? 'Select a service center'
                      : _selectedServiceCenter!['name'],
                  style: TextStyle(
                    color: _selectedServiceCenter == null ? Colors.grey : Colors.grey[800],
                    fontSize: 15,
                  ),
                ),
                subtitle: _selectedServiceCenter == null
                    ? null
                    : Text(
                        '${_selectedServiceCenter!['distance'] ?? 'Unknown'} km | Rating: ${_selectedServiceCenter!['rating']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                trailing: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  // Update distances before showing bottom sheet
                  _updateServiceCenterDistances();
                  _showServiceCenterBottomSheet();
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // My Car
                const Text(
                  'My Car',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_userCars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              FontAwesomeIcons.car,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No cars available',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<Car>(
                            value: _selectedCar,
                            isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
                            items: _userCars.map((car) {
                              // Get car color
                              Color carColor = _getCarColor(car.brand);
                              
                              return DropdownMenuItem<Car>(
                                value: car,
                                child: Row(
                                  children: [
                                    Container(
                                    width: 40,
                                    height: 40,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                      color: carColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.directions_car,
                                        color: carColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${car.brand} ${car.model}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '${car.modelYear} | ${car.carNumber}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Car? newValue) {
                              setState(() {
                                _selectedCar = newValue;
                              });
                            },
                          ),
                        ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                            icon: Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                            label: Text(
                              'Add Car',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                MaterialPageRoute(
                                  builder: (context) => const MyCarsScreen(),
                                ),
                                ).then((_) {
                                  _loadUserCars();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                            ),
                          ],
                      ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
  
  void _showServiceCenterBottomSheet() {
    // Sort centers by distance before showing the bottom sheet
    List<Map<String, dynamic>> sortedCenters = List.from(ServiceCentersScreen.serviceCenters);
    
    // Ensure all centers have a distance value
    for (var center in sortedCenters) {
      if (center['distance'] == null) {
        center['distance'] = 0.0;
      }
    }
    
    sortedCenters.sort((a, b) {
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.locationDot,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Service Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Add refresh button
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      onPressed: () {
                        _getCurrentLocation();
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _showServiceCenterBottomSheet();
                        });
                      },
                      tooltip: 'Refresh distances',
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedCenters.length,
                  itemBuilder: (context, index) {
                    final center = sortedCenters[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: center['isOpen'] 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FontAwesomeIcons.locationDot,
                          color: center['isOpen'] ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        center['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center['address'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${center['distance']} km',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${center['rating']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: center['isOpen']
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          center['isOpen'] ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            color: center['isOpen'] ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedServiceCenter = center;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSchedulingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.calendarDays,
                  color: Colors.blue[700],
                  size: 16,
                ),
                const SizedBox(width: 10),
            const Text(
              'Service Scheduling',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${_serviceDate.day}/${_serviceDate.month}/${_serviceDate.year}',
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 15,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                  size: 18,
                                  color: Colors.blue[700],
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  _formatTimeOfDay(_serviceTime),
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 15,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                  size: 18,
                                  color: Colors.blue[700],
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemDescriptionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.message,
                  color: Colors.blue[700],
                  size: 16,
                ),
                const SizedBox(width: 10),
            const Text(
              'Problem Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Please describe the electrical issue you are experiencing',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _problemDescriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the problem here...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyServiceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.truckMedical,
                  color: _needsEmergencyService ? Colors.red[600] : Colors.blue[700],
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
              'Emergency Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                    color: _needsEmergencyService ? Colors.red[600] : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _needsEmergencyService ? Colors.red[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _needsEmergencyService ? Colors.red[100]! : Colors.blue[100]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _needsEmergencyService ? Icons.warning_amber : Icons.info_outline,
                        color: _needsEmergencyService ? Colors.red[600] : Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Emergency service is available 24/7 with technician arrival within one hour. Additional charges apply.',
              style: TextStyle(
                fontSize: 14,
                            color: _needsEmergencyService ? Colors.red[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
            Row(
              children: [
                Switch(
                  value: _needsEmergencyService,
                            activeColor: Colors.red[600],
                            activeTrackColor: Colors.red[100],
                            inactiveThumbColor: Colors.blue[600],
                            inactiveTrackColor: Colors.blue[100],
                  onChanged: (value) {
                    setState(() {
                      _needsEmergencyService = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                            _needsEmergencyService ? 'Emergency' : 'Standard',
                  style: TextStyle(
                              fontWeight: FontWeight.bold,
                    fontSize: 16,
                              color: _needsEmergencyService ? Colors.red[600] : Colors.blue[600],
                  ),
                ),
              ],
                      ),
                      if (_needsEmergencyService)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '+100 EGP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewDetailedServicesButton(
    List<Map<String, String>> features,
    List<Map<String, dynamic>> packages,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[700]!.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailPage(
                icon: FontAwesomeIcons.bolt,
                title: 'Electrical Systems Services',
                color: Colors.blue[600]!,
                features: features,
                packages: packages,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility),
            const SizedBox(width: 10),
            const Text(
              'View Service Packages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
          ],
        ),
      ),
    );
  }

  // Helper method to format TimeOfDay to string
  String _formatTimeOfDay(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedHour = time.hour > 12 ? (time.hour - 12).toString() : time.hour.toString();
    return '$formattedHour:$minute $period';
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            Color.fromARGB(255, 93, 150, 255),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          // Check if a car is selected
          if (_selectedCar == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a car first'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          // Check if a service center is selected
          if (_selectedServiceCenter == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a service center'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          try {
            // Show loading indicator
            setState(() {
              _isLoading = true;
            });

            // Create unique appointment ID
            final appointmentId = 'APT-${DateTime.now().millisecondsSinceEpoch}';
            final referenceCode = 'APT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${(appointmentId.hashCode % 10000).abs()}';

            // Get current user ID
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final userId = userProvider.user?.id;

            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You must log in first to book an appointment')),
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }

            // Convert appointment time to text format
            final formattedTime = _formatTimeOfDay(_serviceTime);
            

            // Prepare appointment data according to the unified model
            final appointmentData = {
              // Basic information
              'id': appointmentId,
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),

              // Customer information
              'customerId': userId,
              // Vehicle information (basic only)
              'carId': _selectedCar!.id,
              // Service information
              'serviceCategory': 'Electrical Service',

              // Service center information
              'serviceCenter': {
                'id': _selectedServiceCenter!['id'],
                'name': _selectedServiceCenter!['name'],
                'address': _selectedServiceCenter!['address'],
                'phone': _selectedServiceCenter!['phone'] ?? 'N/A'
              },

              // Appointment information
              'date': Timestamp.fromDate(_serviceDate),
              'time': formattedTime,
              'appointmentDate': '${_serviceDate.day}/${_serviceDate.month}/${_serviceDate.year}',
              'appointmentTime': formattedTime,

              // Issue details and requirements
              'issue': {
                'type': _selectedServiceType,
                'description': _problemDescriptionController.text,
                'urgencyLevel': _needsEmergencyService ? 'high' : 'normal',
                'needsPickup': false
              },


              // Service specific data
              'serviceDetails': {
              }
            };

            // Send data to Firestore
            await FirebaseFirestore.instance
                .collection('appointment')
                .doc(appointmentId)
                .set(appointmentData);
          
            // Show success message
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            
            // Show confirmation dialog instead of snackbar
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Appointment Confirmed', textAlign: TextAlign.center),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.boltLightning,
                        color: Colors.blue[700],
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Electrical service appointment has been successfully booked\nReference Number: $referenceCode\nDate: ${_serviceDate.day}/${_serviceDate.month}/${_serviceDate.year}\nTime: ${_formatTimeOfDay(_serviceTime)}\nService: $_selectedServiceType',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _needsEmergencyService ? Colors.red[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _needsEmergencyService ? 'Emergency Service' : 'Standard Service',
                          style: TextStyle(
                            color: _needsEmergencyService ? Colors.red[700] : Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Thank you for choosing our electrical service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Navigate to appointments page
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MyAppointmentsScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                    child: const Text('View Appointments'),
                  ),
                ],
              ),
            );
          } catch (e) {
            // Show error message
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error booking appointment: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.transparent,
        ),
        child: _isLoading 
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.boltLightning,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Text(
              'Book Appointment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
              ],
            ),
      ),
    );
  }

  // Function to get car color based on brand
  Color _getCarColor(String brand) {
    brand = brand.toLowerCase();
    
    if (brand.contains('toyota') || brand.contains('تويوتا')) {
      return Colors.red;
    } else if (brand.contains('mercedes') || brand.contains('مرسيدس')) {
      return Colors.grey;
    } else if (brand.contains('bmw') || brand.contains('بي إم دبليو')) {
      return Colors.blue;
    } else if (brand.contains('ford') || brand.contains('فورد')) {
      return Colors.blue[800]!;
    } else if (brand.contains('honda') || brand.contains('هوندا')) {
      return Colors.red[700]!;
    } else if (brand.contains('nissan') || brand.contains('نيسان')) {
      return Colors.grey[700]!;
    } else if (brand.contains('hyundai') || brand.contains('هيونداي')) {
      return Colors.blue[400]!;
    } else if (brand.contains('kia') || brand.contains('كيا')) {
      return Colors.red[900]!;
    } else if (brand.contains('audi') || brand.contains('أودي')) {
      return Colors.blueGrey[800]!;
    } else if (brand.contains('lexus') || brand.contains('لكزس')) {
      return Colors.grey[900]!;
    } else {
      return Colors.teal;
    }
  }

  // New function to convert weekday name
  
  // New function to get car color name
}
