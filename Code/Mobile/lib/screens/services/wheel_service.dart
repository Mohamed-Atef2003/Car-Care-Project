import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart'; // إضافة مكتبة تحديد الموقع
import 'package:geocoding/geocoding.dart'; // إضافة مكتبة تحويل الإحداثيات إلى عنوان
import '../../constants/colors.dart';
import '../../models/payment_model.dart';
import '../../payment/payment_details_screen.dart';
import '../appointments/my_appointments_screen.dart';
import '../../models/car.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../cars/add_car_screen.dart';
import 'service_centers_screen.dart';


// Simple location class to replace LatLng
class _Location {
  final double latitude;
  final double longitude;
  String? address;
  
  _Location(this.latitude, this.longitude, {this.address});
}

class WheelServicePage extends StatefulWidget {
  const WheelServicePage({super.key});

  @override
  State<WheelServicePage> createState() => _WheelServicePageState();
}

class _WheelServicePageState extends State<WheelServicePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Advanced wheel service options
  final List<String> _wheelTypes = ['Sport', 'Standard', 'Off-road', 'Large size', 'Small size'];
  String _selectedWheelType = 'Sport';
  int _selectedWheelSize = 17;
  bool _needsAlignment = false;
  bool _needsBalancing = true;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _vehicleInfoController = TextEditingController();
  final TextEditingController _specialRequestsController = TextEditingController();
  // Use the _Location class
// Default to Riyadh
  
  // Vehicle selection
  bool _isSelectingFromMyCars = false;
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(); // Controller for address input
  final TextEditingController _trimController = TextEditingController(); // For car trim
  final TextEditingController _engineController = TextEditingController(); // For car engine
  final TextEditingController _versionController = TextEditingController(); // For car version
  final TextEditingController _colorController = TextEditingController(); // For car color
  
  // CarService for user cars
  
  // User cars
  late List<Car> _myCars = [];
  String? _selectedCarId;
  
  // Add a new variable to store the current location
  _Location? _currentLocation;

  // For service center selection
  late List<Map<String, dynamic>> _serviceCenters;
  int _selectedServiceCenter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed from 3 to 2 tabs
    
    // Load user cars
    _loadUserCars();
    
    // Saved address list (sample addresses)
    
    // Schedule car verification after the UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyCarsInFirestore();
    });
    
    // Get service centers data
    _serviceCenters = _getServiceCentersData();
    
    // Get user location to calculate service center distances
    _getUserLocation();
  }
  
  // Get service centers data
  List<Map<String, dynamic>> _getServiceCentersData() {
    // Use service centers list directly from ServiceCentersScreen
    return ServiceCentersScreen.serviceCenters;
  }
  
  // Load user cars
  Future<void> _loadUserCars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerId = getCustomerId();
      
      // Print debug information
      print('====== Starting car loading ======');
      print('Customer ID: $customerId');
      
      if (customerId.isEmpty) {
        // If user is not logged in, display empty list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login first')),
          );
          setState(() {
            _myCars = [];
            _isLoading = false;
          });
        }
        print('Cannot load cars: User is not logged in');
        return;
      }

      // Direct and simplified Firestore query
      final carsSnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: customerId)
          .get();

      print('Query result: ${carsSnapshot.docs.length} cars');
      
      // Print information about each car for debugging
      for (var doc in carsSnapshot.docs) {
        final data = doc.data();
        print('Car: ID=${doc.id}, Brand=${data['brand']}, CustomerID=${data['customerId']}');
      }

      if (carsSnapshot.docs.isEmpty) {
        print('No cars found for user: $customerId');
        if (mounted) {
          setState(() {
            _myCars = [];
            _isLoading = false;
          });
        }
        return;
      }

      print('Found ${carsSnapshot.docs.length} cars for the user');

      final cars = carsSnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Parse the model year value - handle both string and int formats
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
          customerId: data['customerId'] ?? customerId,
          color: data['color'],
        );
      }).toList();

      print('Found ${cars.length} cars for the user');

      if (mounted) {
        setState(() {
          _myCars = cars;
          _isLoading = false;
        });
      }
      
      print('====== End of car loading ======');
    } catch (e) {
      print('Error loading cars: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while loading cars: $e')),
        );
        setState(() {
          _myCars = [];
          _isLoading = false;
        });
      }
    }
  }
  
  // الحصول على معرف العميل من UserProvider
  String getCustomerId() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // التأكد من أن لدينا معرف المستخدم الصحيح
    final userId = userProvider.user?.id ?? '';
    if (userId.isEmpty) {
      print('تحذير: معرف المستخدم غير متوفر');
    }
    return userId;
  }

  // التحقق من وجود سيارات المستخدم في Firestore
  Future<void> _verifyCarsInFirestore() async {
    try {
      final customerId = getCustomerId();
      
      if (customerId.isEmpty) {
        print('لا يمكن التحقق من السيارات: المستخدم غير مسجل الدخول');
        return;
      }
      
      print('\n===== التحقق المباشر من سيارات المستخدم =====');
      print('معرف العميل: $customerId');
      
      // استعلام بسيط
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: customerId)
          .get();
          
      print('عدد السيارات: ${result.docs.length}');
      
      // عرض بيانات كل سيارة
      for (var doc in result.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('--------------------');
        print('معرف السيارة: ${doc.id}');
        data.forEach((key, value) {
          print('$key: $value');
        });
      }
      
      print('===== انتهاء التحقق =====\n');
    } catch (e) {
      print('خطأ في التحقق من سيارات المستخدم: $e');
    }
  }

  // إضافة دالة لتحديث السيارات
  void _refreshCars() {
    print('جاري تحديث قائمة السيارات...');
    _loadUserCars().then((_) {
      // التحقق مما إذا كانت السيارة المحددة لا تزال موجودة بعد التحديث
      if (_selectedCarId != null && !_myCars.any((car) => car.id == _selectedCarId)) {
        print('السيارة المحددة لم تعد موجودة. إعادة تعيين الاختيار.');
        setState(() {
          _selectedCarId = null;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _vehicleInfoController.dispose();
    _specialRequestsController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _addressController.dispose(); // Dispose the address controller
    _trimController.dispose(); // Dispose the trim controller
    _engineController.dispose(); // Dispose the engine controller
    _versionController.dispose(); // Dispose the version controller
    _colorController.dispose(); // Dispose the color controller
    super.dispose();
  }

  Future<void> _saveAppointment() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get user information
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null) {
        throw "Please login first";
      }
      
      final customerId = user.id;
      
      if (_selectedCarId == null && !_isSelectingFromMyCars) {
        throw "Please select a car or add car details";
      }
      
      // Define the selected car
      final selectedCar = _myCars.firstWhere(
        (car) => car.id == _selectedCarId,
        orElse: () => Car(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          brand: _manufacturerController.text.isEmpty ? 'Not specified' : _manufacturerController.text,
          model: _modelController.text,
          modelYear: int.tryParse(_yearController.text) ?? 2023,
          carNumber: _licensePlateController.text.isEmpty ? 'Not specified' : _licensePlateController.text,
          customerId: customerId,
          carLicense: _licensePlateController.text.isEmpty ? 'Not specified' : _licensePlateController.text,
        ),
      );
      
      // Create a unique ID for the appointment
      final appointmentId = 'APT-${DateTime.now().millisecondsSinceEpoch}';
      final referenceCode = 'APT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${(appointmentId.hashCode % 10000).abs()}';
      
      // Convert appointment time to text format
      final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}';
      
      // Prepare additional service options
      final serviceOptions = <String>[];
      if (_needsAlignment) serviceOptions.add('Wheel Alignment');
      if (_needsBalancing) serviceOptions.add('Wheel Balancing');
      
      // Create service description
      final serviceName = 'Wheel Maintenance - $_selectedWheelType ($_selectedWheelSize inches)';
      final serviceDetails = serviceOptions.isEmpty 
        ? serviceName 
        : '$serviceName - ${serviceOptions.join(' - ')}';
      
      // Calculate estimated cost
// Base price + $5 per inch
// 15% VAT

      // Prepare appointment data according to the unified model
      final appointmentData = {
        // Basic information
        'id': appointmentId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Customer information
        'customerId': customerId,

        // Vehicle information (basic only)
        'carId': selectedCar.id,
        
        // Service information
        'serviceCategory': 'wheel-service',
        
        // Service center information
        'serviceCenter': {
          'id': _serviceCenters.isNotEmpty ? _serviceCenters[_selectedServiceCenter]['id'] : 'default',
          'name': _serviceCenters.isNotEmpty ? _serviceCenters[_selectedServiceCenter]['name'] : 'Wheel Maintenance Service Center',
          'address': _serviceCenters.isNotEmpty ? _serviceCenters[_selectedServiceCenter]['address'] : 'N/A',
          'phone': _serviceCenters.isNotEmpty ? _serviceCenters[_selectedServiceCenter]['phone'] ?? 'N/A' : 'N/A'
        },
        
        // Appointment information
        'date': Timestamp.fromDate(_selectedDate),
        'time': formattedTime,
        'appointmentDate': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        'appointmentTime': formattedTime,
        
        // Issue details and requirements
        'issue': {
          'type': serviceDetails,
          'description': _specialRequestsController.text,
          'urgencyLevel': 'normal',
          'needsPickup': false,
        },
            
        // Service specific data
        'serviceDetails': {
          'wheelType': _selectedWheelType,
          'wheelSize': _selectedWheelSize,
          'needsAlignment': _needsAlignment,
          'needsBalancing': _needsBalancing,
        }
      };

      // Send data to Firestore
      await FirebaseFirestore.instance
          .collection('appointment')
          .doc(appointmentId)
          .set(appointmentData);
          
      print('Appointment added to Firestore: $appointmentId');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Appointment Confirmed', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                    height: 120,
                    repeat: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wheel maintenance appointment has been successfully booked\nReference Number: $referenceCode\nDate: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}\nTime: ${_selectedTime.format(context)}\nService: $_selectedWheelType Wheels ($_selectedWheelSize inches)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getWheelIcon(_selectedWheelType),
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_needsAlignment ? "Alignment & " : ""}${_needsBalancing ? "Balancing" : "Standard"} Service',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thank you for choosing our wheel service.',
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
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('View Appointments'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('An error occurred while saving the appointment: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while saving the appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
 
  // Function to select a car from My Cars
  void _selectCar(Car car) {
    setState(() {
      _selectedCarId = car.id;
      
      // Use direct values from Car object
      _manufacturerController.text = car.brand;
      _modelController.text = car.model ?? '';
      _yearController.text = car.modelYear.toString();
      _licensePlateController.text = car.carNumber;
      
      // Compile additional car information into vehicle info field
      List<String> vehicleDetails = [];
      
      if (car.model != null && car.model!.isNotEmpty) {
        vehicleDetails.add('Model: ${car.model}');
      }
      
      if (car.trim != null && car.trim!.isNotEmpty) {
        vehicleDetails.add('Trim: ${car.trim}');
      }
      
      if (car.engine != null && car.engine!.isNotEmpty) {
        vehicleDetails.add('Engine: ${car.engine}');
      }
      
      if (car.version != null && car.version!.isNotEmpty) {
        vehicleDetails.add('Version: ${car.version}');
      }
      
      if (car.color != null && car.color!.isNotEmpty) {
        vehicleDetails.add('Color: ${car.color}');
      }
      
      if (car.carLicense.isNotEmpty) {
        vehicleDetails.add('License: ${car.carLicense}');
      }
      
      _vehicleInfoController.text = vehicleDetails.join(', ');
      
      // Use the model value from the car or default to 'car'
      // Simply use car.model directly where needed
      
      print('Car selected: ${car.brand} ${car.model ?? ''} (${car.id})');
      _isSelectingFromMyCars = false;
      
      // Show confirmation message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${car.brand} ${car.model ?? ''} selected'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  // Build service center selection section
  Widget _buildServiceCenterSelectionSection() {
    // Handle case when service centers list is empty
    if (_serviceCenters.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Text(
              "Select Service Center",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: const Center(
              child: Text(
                "No service centers available. Please check your connection.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _serviceCenters = _getServiceCentersData();
                  _getUserLocation();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Service Centers'),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Text(
            "Select Service Center",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _serviceCenters.length,
            itemBuilder: (context, index) {
              final center = _serviceCenters[index];
              final isSelected = _selectedServiceCenter == index;

              return Card(
                elevation: isSelected ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedServiceCenter = index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(center['images'][0]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                center['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                center['address'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${center['distance'] ?? 'N/A'} km',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 20,
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
        Padding(
          padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Working Hours:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                _serviceCenters[_selectedServiceCenter]['openHours'] as String,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_serviceCenters[_selectedServiceCenter]['services']
                        as List)
                    .map((service) => Chip(
                          label: Text(service),
                          backgroundColor: Colors.grey[100],
                          labelStyle: const TextStyle(fontSize: 12),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceCentersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('View more service centers'),
          ),
        ),
      ],
    );
  }

  // Function to get current location
  Future<void> _getUserLocation() async {
    setState(() {
// Close suggestions list
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
        });
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Convert coordinates to address using geocoding
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        // Create detailed address from place data
        final String address = 
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        
        // Update address field and selected location variable
        setState(() {
          _addressController.text = address.trim().replaceAll(RegExp(r',\s*,'), ',').replaceAll(RegExp(r'^,\s*'), '');
          _currentLocation = _Location(
            position.latitude,
            position.longitude,
            address: _addressController.text,
          );
          
          // Update distances to service centers
          _updateServiceCenterDistances();
          
          // Show success message for a short time
          
        });
      } else {
        setState(() {
          _addressController.text = 'Your current location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          _currentLocation = _Location(
            position.latitude,
            position.longitude,
            address: _addressController.text,
          );
        });
      }
    } catch (e) {
      setState(() {
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update service center distances based on current location
  void _updateServiceCenterDistances() {
    if (_currentLocation == null) return;
    
    for (var center in _serviceCenters) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        center['latitude'] as double,
        center['longitude'] as double
      );
      
      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = (distanceInMeters / 1000);
      center['distance'] = double.parse(distanceInKm.toStringAsFixed(1));
    }
    
    // Sort centers by distance
    _serviceCenters.sort((a, b) {
      double distanceA = a['distance'] ?? double.maxFinite;
      double distanceB = b['distance'] ?? double.maxFinite;
      return distanceA.compareTo(distanceB);
    });
    
    // Update the state to refresh the UI
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Tire Replacement and Installation',
        'description': 'Professional service for replacing and installing new tires with comprehensive inspection of suspension and brake systems',
        'icon': Icons.tire_repair,
        'price': 150,
        'details': [
          'Inspection of current tire condition and tread depth measurement',
          'Installation of new tires with precise balancing',
          'Air pressure check and adjustment according to manufacturer specifications',
          'Air valve inspection and replacement when needed',
          'Tire rotation to ensure even wear',
        ]
      },
      {
        'title': 'Wheel Balancing and Adjustment',
        'description': 'Precision wheel balancing using advanced equipment to ensure comfortable, vibration-free driving',
        'icon': Icons.balance,
        'price': 120,
        'details': [
          'Dynamic balancing for each wheel individually',
          'Removal of old weights and installation of new high-quality weights',
          'Rim alignment check and repair when needed',
          'Vibration measurement and elimination',
          'Tire rubber mounts inspection',
        ]
      },
      {
        'title': 'Punctured Tire Repair',
        'description': 'Fast and professional repair of punctured tires with guaranteed tire safety and leak-free results',
        'icon': Icons.build,
        'price': 80,
        'details': [
          'Tire inspection and precise puncture location',
          'Permanent repair of punctures using high-quality materials',
          'Complete tire inspection to detect any other damage',
          'Air pressure adjustment after repair',
          '3-month warranty on repairs',
        ]
      },
      {
        'title': 'Wheel Alignment',
        'description': 'Precise geometric adjustment of wheel angles to improve vehicle stability, reduce tire wear, and save fuel',
        'icon': Icons.settings,
        'price': 200,
        'details': [
          'Camber angle adjustment to improve tire grip on the road',
          'Caster angle adjustment to improve vehicle stability',
          'Toe angle adjustment to reduce tire wear',
          'Suspension and steering components inspection',
          'Detailed report of angle measurements before and after adjustment',
        ]
      },
      {
        'title': 'Smart Tire Inspection',
        'description': 'Comprehensive tire inspection using AI technology and advanced sensors to detect any problems',
        'icon': Icons.search,
        'price': 100,
        'details': [
          '3D inspection of tire wear patterns',
          'Tread depth measurement at multiple points with micrometer precision',
          'Detection of invisible internal damage',
          'Tire temperature and pressure distribution measurement',
          'Detailed digital report on the condition of each tire',
        ]
      },
      {
        'title': 'Mobile Wheel Service',
        'description': 'Comprehensive mobile service that comes to your location to perform wheel maintenance with workshop-quality results',
        'icon': Icons.location_on,
        'price': 250,
        'details': [
          'Fast arrival within 60 minutes of request',
          'Complete equipment and trained technicians',
          'On-site replacement, balancing, and repair services',
          'Coverage of all city areas',
          'Available 24 hours for emergency cases',
        ]
      },
    ];

    // Maintenance schedule data
    final maintenanceSchedule = [
      {
        'title': 'Every 5,000 km',
        'icon': Icons.speed,
        'color': Colors.green,
        'tasks': [
          'Check tire air pressure',
          'Check tire tread depth',
          'Rotate tires (according to manufacturer recommendations)'
        ]
      },
      {
        'title': 'Every 15,000 km',
        'icon': Icons.settings,
        'color': Colors.blue,
        'tasks': [
          'Wheel balancing',
          'Suspension system check',
          'Wheel alignment if necessary'
        ]
      },
      {
        'title': 'Every 30,000 km',
        'icon': Icons.update,
        'color': Colors.orange,
        'tasks': [
          'Comprehensive suspension system check',
          'Replace tires if they\'ve reached wear limit',
          'Check for power steering fluid leaks'
        ]
      },
      {
        'title': 'Every 50,000 km',
        'icon': Icons.change_circle,
        'color': Colors.red,
        'tasks': [
          'Replace tires with new ones',
          'Check and repair steering system',
          'Check shock absorbers and ball joints'
        ]
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wheel and Tire Services'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'Book Appointment'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade50,
                  Colors.white,
                ],
              ),
            ),
          ),
          TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              // First Tab - Services
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 220),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/image/wheel.png'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black38,
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.6),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Professional Wheel Services',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'We provide comprehensive wheel and tire services with the highest quality standards and service guarantee',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _tabController.animateTo(1);
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: const Text('Book Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      elevation: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fade(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
                    
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Wheel Maintenance Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return GestureDetector(
                        onTap: () {
                          // Show detailed service dialog
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => buildServiceDetailSheet(feature),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Container(
                            height: 180, // تحديد ارتفاع ثابت للبطاقة
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start, // تغيير من center إلى start
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, // جعل العمود يأخذ أقل مساحة ممكنة
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10), // تقليل الـpadding من 12 إلى 10
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    feature['icon'] as IconData,
                                    size: 24, // تقليل حجم الأيقونة من 30 إلى 24
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12), // تقليل المسافة من 16 إلى 12
                                Text(
                                  feature['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 15, // تقليل حجم الخط من 16 إلى 15
                                    fontWeight: FontWeight.bold,
                                    height: 1.1, // تقليل ارتفاع السطر من 1.2 إلى 1.1
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6), // تقليل المسافة من 8 إلى 6
                                Text(
                                  feature['description'] as String,
                                  style: TextStyle(
                                    fontSize: 11, // تقليل حجم الخط من 12 إلى 11
                                    color: Colors.grey[600],
                                    height: 1.2, // تقليل ارتفاع السطر من 1.3 إلى 1.2
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${feature['price']} EGP',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppColors.primary,
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
                  
                  const SizedBox(height: 32),
                  
                  // Maintenance Schedule Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Periodic Maintenance Schedule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To maintain the performance and safety of your car tires, we recommend following this maintenance schedule:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...maintenanceSchedule.map((schedule) => buildMaintenanceItem(schedule)),
                          ],
                        ),
                      ),
                    ],
                  ).animate()
                   .fade(duration: 500.ms, delay: 300.ms)
                   .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut, delay: 300.ms),
                   
                  const SizedBox(height: 32),
                  
                  // Tire Health Tips
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.lightbulb,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Tips for Tire Maintenance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          buildTireHealthTip(
                            'Check Air Pressure Monthly',
                            'Proper pressure extends tire life, improves fuel efficiency, and increases safety',
                            Icons.air,
                          ),
                          const Divider(height: 24),
                          buildTireHealthTip(
                            'Avoid Sudden Stops',
                            'Hard braking leads to faster tire wear and may cause damage',
                            Icons.speed,
                          ),
                          const Divider(height: 24),
                          buildTireHealthTip(
                            'Avoid Heavy Loads',
                            'Excess weight puts additional pressure on tires and reduces their lifespan',
                            Icons.fitness_center,
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                   .fade(duration: 500.ms, delay: 600.ms)
                   .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad, delay: 600.ms),
                
                  const SizedBox(height: 32),
                  
                  // Why Choose Us Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Why Choose Our Services?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          buildAdvantageItem(
                            icon: Icons.verified,
                            title: 'Certified Technicians',
                            description: 'All our technicians are certified and trained to the highest level by global academies specialized in wheel maintenance',
                          ),
                          const Divider(height: 24),
                          buildAdvantageItem(
                            icon: Icons.speed,
                            title: 'Fast Service',
                            description: 'We commit to completing the service on time while ensuring quality work and keeping you informed at every step',
                          ),
                          const Divider(height: 24),
                          buildAdvantageItem(
                            icon: Icons.thumb_up,
                            title: 'Quality Guarantee',
                            description: 'We provide a 6-month warranty on all our services with free inspection and evaluation options',
                          ),
                          const Divider(height: 24),
                          buildAdvantageItem(
                            icon: Icons.attach_money,
                            title: 'Competitive Prices',
                            description: 'We offer the best prices while maintaining service quality and using genuine certified parts',
                          ),
                        ],
                      ),
                    ),
                  ),
                
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _tabController.animateTo(1);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text(
                        'Book Appointment Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ).animate()
                   .fade(duration: 500.ms, delay: 800.ms)
                   .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 500.ms, delay: 800.ms),
                ],
              ),
              
              // Second Tab - Booking
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.tune,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Wheel Maintenance Service Booking',
                                      style: TextStyle(
                                        fontSize:15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Choose the required service details and a \n suitable maintenance appointment',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Vehicle Information
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.directions_car, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: const Text(
                                      'Vehicle Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Toggle between manual entry and 'My Cars'
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isSelectingFromMyCars = !_isSelectingFromMyCars;
                                      });
                                    },
                                    icon: Icon(
                                      _isSelectingFromMyCars ? Icons.edit : Icons.car_rental,
                                      color: AppColors.primary,
                                    ),
                                    label: Text(
                                      _isSelectingFromMyCars ? 'Back' : 'My Cars',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Select from My Cars
                              if (_isSelectingFromMyCars) ...[
                                const Text(
                                  'Select from your cars',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                _myCars.isEmpty 
                                  ? _buildEmptyCarsMessage() 
                                  : SizedBox(
                                      height: 180,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _myCars.length + 1, // +1 لزر إضافة سيارة جديدة
                                        itemBuilder: (context, index) {
                                          if (index < _myCars.length) {
                                            // سيارات المستخدم
                                            final car = _myCars[index];
                                            final isSelected = _selectedCarId == car.id;
                                            final carColor = _getCarColor(car);
                                            
                                            return GestureDetector(
                                              onTap: () => _selectCar(car),
                                              child: Container(
                                                width: 200,
                                                margin: const EdgeInsets.only(right: 16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isSelected ? carColor.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: isSelected ? carColor : Colors.grey.shade200,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                  gradient: isSelected
                                                    ? LinearGradient(
                                                        begin: Alignment.topRight,
                                                        end: Alignment.bottomLeft,
                                                        colors: [
                                                          Colors.white,
                                                          carColor.withOpacity(0.1),
                                                        ],
                                                      )
                                                    : null,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Car header
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: carColor.withOpacity(0.1),
                                                        borderRadius: const BorderRadius.vertical(
                                                          top: Radius.circular(16),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            car.brand,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                              color: Colors.grey[800],
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: carColor.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              car.model ?? 'سيارة',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: carColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    Expanded(
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(12),
                                                        child: Row(
                                                          children: [
                                                            // Car image
                                                            Hero(
                                                              tag: 'car_image_${car.id}',
                                                              child: Container(
                                                                width: 60,
                                                                height: 60,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.grey[200],
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: car.imageUrl != null
                                                                  ? ClipRRect(
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      child: Image.network(
                                                                        car.imageUrl!,
                                                                        fit: BoxFit.cover,
                                                                        errorBuilder: (context, error, stackTrace) => 
                                                                          Icon(
                                                                            FontAwesomeIcons.car,
                                                                            size: 30,
                                                                            color: carColor.withOpacity(0.5),
                                                                          ),
                                                                      ),
                                                                    )
                                                                  : Icon(
                                                                      FontAwesomeIcons.car,
                                                                      size: 30,
                                                                      color: carColor.withOpacity(0.5),
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            
                                                            // Car info
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  _buildInfoRow(
                                                                    icon: Icons.calendar_today,
                                                                    label: 'Model',
                                                                    value: car.modelYear.toString(),
                                                                    color: carColor,
                                                                  ),
                                                                  const SizedBox(height: 8),
                                                                  _buildInfoRow(
                                                                    icon: Icons.confirmation_number,
                                                                    label: 'License Plate',
                                                                    value: car.carNumber,
                                                                    color: carColor,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Selection indicator
                                                    if (isSelected)
                                                      Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: carColor.withOpacity(0.2),
                                                          borderRadius: const BorderRadius.vertical(
                                                            bottom: Radius.circular(16),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.check_circle,
                                                              size: 16,
                                                              color: carColor,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Selected',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: carColor,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else {
                                            // زر إضافة سيارة جديدة
                                            return Container(
                                              width: 160,
                                              margin: const EdgeInsets.only(right: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.grey.shade300, width: 1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.03),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const AddCarScreen()),
                                                  ).then((_) {
                                                    _refreshCars();
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(16),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withOpacity(0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: AppColors.primary,
                                                        size: 32,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Add a Car',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Add your car now',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                const SizedBox(height: 24),
                                
                                  
                               
                              ] else ...[
                                // Vehicle Make and Model
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _manufacturerController,
                                        decoration: InputDecoration(
                                          labelText: 'Manufacturer',
                                          hintText: 'Toyota',
                                          prefixIcon: const Icon(Icons.business),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          filled: true,
                                          enabled: false,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the manufacturer';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _modelController,
                                        decoration: InputDecoration(
                                          labelText: 'Model',
                                          hintText: 'Camry',
                                          prefixIcon: const Icon(Icons.car_repair),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          filled: true,
                                          enabled: false,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the model';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Year and License Plate
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _yearController,
                                        decoration: InputDecoration(
                                          labelText: 'Year of Manufacture',
                                          hintText: '2022',
                                          prefixIcon: const Icon(Icons.date_range),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          filled: true,
                                          enabled: false,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the year of manufacture';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _licensePlateController,
                                        decoration: InputDecoration(
                                          labelText: 'License Plate',
                                          hintText: 'Optional',
                                          prefixIcon: const Icon(Icons.text_format),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          filled: true,
                                          enabled: false,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Wheel Type selection
                      Text(
                        'Wheel Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: _wheelTypes.map((type) {
                            final isSelected = type == _selectedWheelType;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedWheelType = type;
                                });
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      getWheelIcon(type),
                                      color: isSelected ? AppColors.primary : Colors.grey[600],
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppColors.primary : Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Wheel Size Slider
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(FontAwesomeIcons.circleNotch, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Wheel Size (in inches)',
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
                                  const Text('13"', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Expanded(
                                    child: Slider(
                                      value: _selectedWheelSize.toDouble(),
                                      min: 13,
                                      max: 24,
                                      divisions: 11,
                                      label: _selectedWheelSize.toString(),
                                      activeColor: AppColors.primary,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedWheelSize = value.toInt();
                                        });
                                      },
                                    ),
                                  ),
                                  const Text('24"', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Selected Size: $_selectedWheelSize inches',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Service Options Card
                      Card(
                        elevation: 0,
                        color: Colors.grey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                              child: Text(
                                'Additional Services',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CheckboxListTile(
                              title: const Text('Adjust Wheel Angles'),
                              subtitle: const Text('Improves vehicle stability and reduces tire wear', style: TextStyle(fontSize: 12)),
                              value: _needsAlignment,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() {
                                  _needsAlignment = value!;
                                });
                              },
                            ),
                            
                            Divider(height: 1, indent: 16, endIndent: 16),
                            
                            CheckboxListTile(
                              title: const Text('Wheel Balancing'),
                              subtitle: const Text('Reduces vibration and improves smoothness', style: TextStyle(fontSize: 12)),
                              value: _needsBalancing,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() {
                                  _needsBalancing = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Service Center selection
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.location_city, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Service Center',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              _buildServiceCenterSelectionSection(),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      
                      
                      // Date and Time pickers in responsive layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // For wider screens, show date and time pickers side by side
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildDatePicker(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimePicker(),
                                ),
                              ],
                            );
                          } else {
                            // For narrower screens, stack them vertically
                            return Column(
                              children: [
                                _buildDatePicker(),
                                _buildTimePicker(),
                              ],
                            );
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Special Requests
                      TextFormField(
                        controller: _specialRequestsController,
                        decoration: InputDecoration(
                          labelText: 'Special Notes (Optional)',
                          hintText: 'Any additional requirements or notes',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confirm Booking',
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Confetti Effect
          Align(
            alignment: Alignment.topCenter,
            child: Container(),  // Placeholder for confetti widget
          ),
        ],
      ),
    );
  }
  
  Widget buildAdvantageItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTireHealthTip(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.orange[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMaintenanceItem(Map<String, dynamic> schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (schedule['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    schedule['icon'] as IconData,
                    color: schedule['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  schedule['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...(schedule['tasks'] as List<String>).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget buildServiceDetailSheet(Map<String, dynamic> service) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            service['icon'] as IconData,
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['title'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${service['price']} EGP',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '30-60 minutes',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Service Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'What does this service include?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(
                      (service['details'] as List<String>).length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                service['details'][index],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Get user information from provider
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final String? customerId = userProvider.user?.id;
                      final String customerName = userProvider.user != null 
                          ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
                          : "Guest";
                      final String? customerPhone = userProvider.user?.mobile;
                      final String? customerEmail = userProvider.user?.email;
                      
                      // Create a unique ID for the order
                      final String orderId = 'WHS-${DateTime.now().millisecondsSinceEpoch}';
                      
                      // Prepare additional data for the service
                      final Map<String, dynamic> additionalData = {
                        'customerId': customerId,
                        'customerName': customerName,
                        'customerPhone': customerPhone,
                        'customerEmail': customerEmail,
                        'orderId': orderId,
                        'serviceType': 'Wheel Service',
                        'serviceName': service['title'] as String,
                        'packageName': service['title'] as String,
                        'orderDate': DateTime.now().toIso8601String(),
                        'orderStatus': 'pending',
                      };
                              // Navigate to payment details screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PaymentDetailsScreen(
                                    paymentSummary: PaymentSummary(
                                      subtotal: (service['price'] as int).toDouble(),
                                      tax: ((service['price'] as int) * 0.15).toDouble(),
                                      discount: 0.0,
                                      total: ((service['price'] as int) * 1.15).toDouble(),
                                      currency: 'EGP',
                                      items: [
                                        {
                                          'id': 'wheel_service_${service['title'].replaceAll(" ", "_").toLowerCase()}',
                                          'serviceType': 'Wheel Service',
                                          'name': service['title'] as String,
                                          'price': (service['price'] as int).toDouble(),
                                          'quantity': 1,
                                          'category': 'Service',
                                          'packageName': service['title'] as String,
                                          'description': service['description'] as String
                                        }
                                      ],
                                      additionalData: additionalData,
                                    ),
                                    orderId: orderId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Buy Service'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Our services include a 6-month warranty. Terms and conditions apply.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Appointment Date'),
        subtitle: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: const TextStyle(color: AppColors.primary),
        ),
        leading: const Icon(Icons.calendar_today),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildTimePicker() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Appointment Time'),
        subtitle: Text(
          _selectedTime.format(context),
          style: const TextStyle(color: AppColors.primary),
        ),
        leading: Icon(Icons.access_time, color: AppColors.primary),
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: _selectedTime,
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  alwaysUse24HourFormat: false,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary, // Use app primary color
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary, // Text color
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
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              time.hour,
              time.minute,
            );
            
            final minTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              8, // 8:00 AM
              0,
            );
            
            final maxTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              20, // 8:00 PM
              0,
            );
            
            if (selectedDateTime.isBefore(minTime)) {
              // If before 8:00 AM, set to 8:00 AM
              setState(() {
                _selectedTime = const TimeOfDay(hour: 8, minute: 0);
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
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (selectedDateTime.isAfter(maxTime)) {
              // If after 8:00 PM, set to 8:00 PM
              setState(() {
                _selectedTime = const TimeOfDay(hour: 20, minute: 0);
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
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              // Time is within range, use it
              setState(() {
                _selectedTime = time;
              });
            }
          }
        },
      ),
    );
  }
  
  // Helper methods for vehicle and wheel icons
  IconData getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'Sedan':
        return Icons.directions_car;
      case 'SUV':
        return Icons.directions_car; // Use SUV icon if available
      case 'Van':
        return Icons.airport_shuttle;
      case 'Pickup':
        return Icons.local_shipping;
      case 'Coupe':
        return Icons.directions_car; // Use coupe icon if available
      default:
        return Icons.directions_car;
    }
  }
  
  IconData getWheelIcon(String wheelType) {
    switch (wheelType) {
      case 'Sport':
        return Icons.sports_motorsports;
      case 'Standard':
        return FontAwesomeIcons.circle;
      case 'Off-road':
        return FontAwesomeIcons.truck;
      case 'Large size':
        return FontAwesomeIcons.expand;
      case 'Small size':
        return FontAwesomeIcons.compress;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  // Function to display a message when no cars are available
  Widget _buildEmptyCarsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.car,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          const Text(
            'No cars available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can enter your car details manually',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  
  // Add function to build an information row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Add function to get appropriate color for the car
  Color _getCarColor(Car car) {
    // Assign colors based on car brands
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

    // Default color if no match
    return AppColors.primary;
  }
} 