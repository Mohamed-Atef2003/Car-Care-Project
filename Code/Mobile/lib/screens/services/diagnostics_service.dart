import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/constants/colors.dart';
import '../../models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/user_provider.dart';
import '../cars/add_car_screen.dart';
import '../../models/car.dart';

class DiagnosticsServicePage extends StatefulWidget {
  const DiagnosticsServicePage({super.key});

  @override
  State<DiagnosticsServicePage> createState() => _DiagnosticsServicePageState();
}

class _DiagnosticsServicePageState extends State<DiagnosticsServicePage> {
  int _selectedPackage = 0;
  int _currentStep = 0;
  String? _selectedCarId;
  
  // Variables para cargar coches desde Firestore
  List<Car> _userCars = [];
  bool _isLoading = false;
  
  // Controller for additional notes TextField
  final TextEditingController _notesController = TextEditingController();
  
  final List<String> _selectedSymptoms = [];
  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Strange noise from engine', 'icon': FontAwesomeIcons.gear},
    {'name': 'Engine overheating', 'icon': FontAwesomeIcons.temperatureHigh},
    {'name': 'Poor performance', 'icon': FontAwesomeIcons.chartLine},
    {'name': 'Electrical problems', 'icon': FontAwesomeIcons.bolt},
    {'name': 'Excessive fuel consumption', 'icon': FontAwesomeIcons.gasPump},
    {'name': 'Vehicle vibration', 'icon': FontAwesomeIcons.car},
    {'name': 'Transmission problems', 'icon': FontAwesomeIcons.gears},
    {'name': 'Starting difficulty', 'icon': FontAwesomeIcons.powerOff},
  ];
  
  final features = [
    {
      'title': 'Comprehensive Engine Inspection',
      'description': 'Detailed inspection of engine systems and identification of existing or potential problems',
    },
    {
      'title': 'Electronics System Check',
      'description': 'Accurate diagnosis of electrical and electronic problems using the latest equipment',
    },
    {
      'title': 'Vehicle Performance Analysis',
      'description': 'Evaluation of vehicle performance and identification of weaknesses affecting performance',
    },
    {
      'title': 'Fuel System Inspection',
      'description': 'Inspection of the fuel injection system and detection of fuel consumption-related issues',
    },
    {
      'title': 'Comprehensive Diagnostic Report',
      'description': 'Detailed report showing the vehicle condition, existing problems, and repair recommendations',
    },
  ];

  final packages = [
    {
      'name': 'Basic Inspection',
      'price': 149,
      'features': [
        'Basic engine check',
        'Error code reading',
        'Charging system check',
        'Battery check',
        'Report of main issues',
      ],
    },
    {
      'name': 'Comprehensive Inspection',
      'price': 349,
      'features': [
        'Comprehensive engine check',
        'Reading and interpreting error codes',
        'Charging and electrical system check',
        'Fuel system check',
        'Exhaust system check',
        'Transmission check',
        'Detailed report of all issues',
        'Repair recommendations',
      ],
    },
    {
      'name': 'Advanced Professional Inspection',
      'price': 599,
      'features': [
        'All comprehensive inspection services',
        'Advanced safety system check',
        'Engine performance testing under load',
        'Electronic control system check',
        'Suspension and steering system check',
        'Exhaust emissions test',
        'Detailed diagnostic report',
        'Regular follow-up for 3 months',
      ],
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserCars();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  // Load user cars from Firestore
  Future<void> _loadUserCars() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must log in first')),
          );
        }
        setState(() {
          _userCars = [];
          _isLoading = false;
        });
        return;
      }

      print('====== Start loading cars ======');
      print('Customer ID: $userId');

      final carsSnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: userId)
          .get();

      print('Query result: ${carsSnapshot.docs.length} cars');

      if (carsSnapshot.docs.isEmpty) {
        print('No cars found for user: $userId');
        if (mounted) {
          setState(() {
            _userCars = [];
            _isLoading = false;
          });
        }
        return;
      }

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
          customerId: data['customerId'] ?? userId,
          color: data['color'],
        );
      }).toList();

      print('Found ${cars.length} cars for user');

      if (mounted) {
        setState(() {
          _userCars = cars;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cars: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cars: $e')),
        );
        setState(() {
          _userCars = [];
          _isLoading = false;
        });
      }
    }
  }
  
  // Update car list
  void _refreshCars() {
    _loadUserCars();
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Car Diagnostics',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _showResultDialog();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep == 0 && _selectedCarId == null
                          ? null
                          : (_currentStep == 1 && _selectedSymptoms.isEmpty
                              ? null
                              : details.onStepContinue),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_currentStep < 3 ? 'Next' : 'Finish'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Car Type'),
              content: _buildCarTypeSelector(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Symptoms & Problems'),
              content: _buildSymptomsSelector(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Service Packages'),
              content: _buildPackageSelector(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Final Details'),
              content: _buildFinalDetails(),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCarTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Car',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrange,
                ),
              )
            : _userCars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No cars available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddCarScreen()),
                          ).then((_) {
                            _refreshCars();
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add New Car'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _userCars.length + 1, // +1 for add new car button
                  itemBuilder: (context, index) {
                    if (index < _userCars.length) {
                      // Display user cars
                      final car = _userCars[index];
                      final isSelected = _selectedCarId == car.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCarId = car.id;
                          });
                        },
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Car image or icon
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.deepOrange.withOpacity(0.2) : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: car.imageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        car.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          _getCarTypeIcon(car.model ?? 'Sedan'),
                                          color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
                                          size: 24,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _getCarTypeIcon(car.model ?? 'Sedan'),
                                      color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
                                      size: 24,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                car.brand,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.deepOrange : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${car.modelYear} - ${car.carNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.deepOrange.withOpacity(0.8) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Add new car button
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.deepOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add Car',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
      ],
    );
  }
  
  IconData _getCarTypeIcon(String carType) {
    switch (carType) {
      case 'Sedan':
        return FontAwesomeIcons.car;
      case 'Hatchback':
        return FontAwesomeIcons.carSide;
      case 'SUV':
        return FontAwesomeIcons.truck;
      case 'Pickup':
        return FontAwesomeIcons.truck;
      case 'Van':
        return FontAwesomeIcons.vanShuttle;
      case 'Sports':
        return FontAwesomeIcons.car;
      default:
        return FontAwesomeIcons.car;
    }
  }
  
  Widget _buildSymptomsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Problems and Symptoms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can select multiple symptoms',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _symptoms.length,
          itemBuilder: (context, index) {
            final symptom = _symptoms[index];
            final isSelected = _selectedSymptoms.contains(symptom['name']);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSymptoms.remove(symptom['name']);
                    } else {
                      _selectedSymptoms.add(symptom['name'] as String);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        symptom['icon'] as IconData,
                        color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          symptom['name'] as String,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.deepOrange : Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildPackageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose the Appropriate Service Package',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < packages.length; i++)
          _buildPackageCard(i),
      ],
    );
  }
  
  Widget _buildPackageCard(int index) {
    final package = packages[index];
    final isSelected = _selectedPackage == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackage = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      package['name'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.deepOrange : Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${package['price']} EGP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              for (var feature in package['features'] as List<String>)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isSelected ? Colors.deepOrange : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.black87 : Colors.grey.shade700,
                          ),
                        ),
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
  
  Widget _buildFinalDetails() {
    // Get selected car data
    Car? selectedCar;
    if (_selectedCarId != null) {
      selectedCar = _userCars.firstWhere(
        (car) => car.id == _selectedCarId,
        orElse: () => Car(
          id: '',
          brand: 'Not specified',
          modelYear: DateTime.now().year,
          carNumber: '',
          carLicense: '',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Request Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildSummaryItem('Car:', selectedCar != null 
            ? '${selectedCar.brand} ${selectedCar.modelYear} - ${selectedCar.carNumber}'
            : 'Not specified'),
        _buildSummaryItem('Selected symptoms:', '${_selectedSymptoms.length} symptoms'),
        _buildSummaryItem('Selected package:', packages[_selectedPackage]['name'] as String),
        _buildSummaryItem('Price:', '${packages[_selectedPackage]['price']} EGP'),
        const SizedBox(height: 20),
        const Text(
          'Additional notes:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any additional notes about your car problem here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'We will contact you within 24 hours to schedule a suitable inspection appointment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showResultDialog() {
    final package = packages[_selectedPackage];
    final price = package['price'] as int;
    final packageName = package['name'] as String;
    
    // Make sure order ID is always longer than 8 characters
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderId = 'DIAG-$timestamp';
    
    // Get user data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    final String customerName = userProvider.user != null 
        ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
        : "Guest";
    final String? customerPhone = userProvider.user?.mobile;
    final String? customerEmail = userProvider.user?.email;
    
    // Check if user is logged in
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must log in to request this service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get selected car data
    Car? selectedCar;
    String carDescription = 'Unspecified car';
    
    if (_selectedCarId != null) {
      selectedCar = _userCars.firstWhere(
        (car) => car.id == _selectedCarId,
        orElse: () => Car(
          id: '',
          brand: 'Unspecified',
          modelYear: DateTime.now().year,
          carNumber: '',
          carLicense: '',
        ),
      );
      
      if (selectedCar.id.isNotEmpty) {
        carDescription = '${selectedCar.brand} ${selectedCar.modelYear}';
      }
    }
    
    // Calculate tax and total
    final double subtotal = price.toDouble();
    final double tax = subtotal * 0.15; // 15% VAT
    final double total = subtotal + tax;
    
    // Collect selected symptoms
    final List<String> selectedSymptomsList = List<String>.from(_selectedSymptoms);
    
    // Get user's additional notes from TextField
    final String userNotes = _notesController.text.trim();
    
    // Prepare additional service data
    final Map<String, dynamic> additionalData = {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'orderId': orderId,
      'serviceType': 'Car Diagnostics',
      'packageName': packageName,
      'symptoms': selectedSymptomsList,
      'carId': selectedCar?.id,
      'carBrand': selectedCar?.brand,
      'carModel': selectedCar?.model,
      'carYear': selectedCar?.modelYear,
      'orderDate': DateTime.now().toIso8601String(),
      'orderStatus': 'pending',
    };
    
    // Create payment summary
    final PaymentSummary paymentSummary = PaymentSummary(
      subtotal: subtotal,
      tax: tax,
      deliveryFee: 0.0, // No delivery fee for services
      discount: 0.0,
      total: total,
      currency: 'EGP',
      items: [
        {
          'id': 'diagnostics_${packageName.replaceAll(" ", "_").toLowerCase()}',
          'name': packageName,
          'description': 'Car Diagnostics Service - $carDescription',
          'price': subtotal,
          'quantity': 1,
          'category': 'Service',
          'serviceType': 'Car Diagnostics',
          'packageName': packageName,
          'notes': 'Car: ${selectedCar?.brand ?? "Unknown"} ${selectedCar?.modelYear ?? ""} - Symptoms: ${_selectedSymptoms.length} (${selectedSymptomsList.join(", ")})${userNotes.isNotEmpty ? "\n\nAdditional notes: $userNotes" : ""}',
        }
      ],
      additionalData: additionalData,
    );
    
    // Navigate to payment details page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(
          paymentSummary: paymentSummary,
          orderId: orderId,
        ),
      ),
    );
  }
} 