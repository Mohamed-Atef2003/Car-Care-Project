import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/car.dart';
import 'add_car_screen.dart';
import 'car_details_screen.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final _selectedColor = AppColors.primary;
  List<Car> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarsFromFirestore();
    
    // Schedule user car verification after UI build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyCarsInFirestore();
    });
  }

  // Get customer ID from UserProvider
  String getCustomerId() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Ensure we have the correct user ID
    final userId = userProvider.user?.id ?? '';
    if (userId.isEmpty) {
      print('Warning: User ID not available');
    }
    return userId;
  }

  // Load car data from Firestore
  Future<void> _loadCarsFromFirestore() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customerId = getCustomerId();
      
      // Print debug information
      print('====== Start loading cars ======');
      print('Customer ID: $customerId');
      
      if (customerId.isEmpty) {
        // If user is not logged in, display empty list
        setState(() {
          _cars = [];
          _isLoading = false;
        });
        print('Cannot load cars: User not logged in');
        return;
      }
      
      print('Loading user cars with ID: $customerId');
      
      // Direct and simplified Firestore query (like the example you provided)
      final QuerySnapshot carDocs = await FirebaseFirestore.instance
          .collection("cars")
          .where("customerId", isEqualTo: customerId)
          .get();
      
      print('Query result: ${carDocs.docs.length} cars');
      
      // Print information for each car for debugging
      for (var doc in carDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Car: ID=${doc.id}, Brand=${data['brand']}, Customer ID=${data['customerId']}');
      }

      if (carDocs.docs.isEmpty) {
        print('No cars found for user: $customerId');
        setState(() {
          _cars = [];
          _isLoading = false;
        });
        return;
      }

      print('Found ${carDocs.docs.length} cars for user');

      // Convert data to Car objects
      final List<Car> loadedCars = carDocs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
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
          // Make sure to also store customer ID in the car object
          customerId: data['customerId'] ?? customerId,
          color: data['color'],
        );
      }).toList();

      setState(() {
        _cars = loadedCars;
        _isLoading = false;
      });
      
      print('====== Finished loading cars ======');
    } catch (e) {
      print('Error loading cars: $e');
      setState(() {
        _cars = [];
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred while loading cars'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Refresh the list
  void _refreshCars() {
    _loadCarsFromFirestore();
  }

  // Verify user's cars in Firestore
  Future<void> _verifyCarsInFirestore() async {
    try {
      final customerId = getCustomerId();
      
      if (customerId.isEmpty) {
        print('Cannot verify cars: User not logged in');
        return;
      }
      
      print('\n===== Direct verification of user cars =====');
      print('Customer ID: $customerId');
      
      // Simple query
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: customerId)
          .get();
          
      print('Number of cars: ${result.docs.length}');
      
      // Display data for each car
      for (var doc in result.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('--------------------');
        print('Car ID: ${doc.id}');
        data.forEach((key, value) {
          print('$key: $value');
        });
      }
      
      print('===== End of verification =====\n');
    } catch (e) {
      print('Error verifying user cars: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Cars',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshCars,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: _isLoading
            ? _buildLoadingState()
            : (_cars.isEmpty ? _buildEmptyState() : _buildCarsList()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCarScreen()),
          );
          
          if (result == true) {
            _refreshCars();
          }
        },
        backgroundColor: _selectedColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Car',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  // Display loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading cars...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Display empty state when no cars
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.car,
                size: 60,
                color: _selectedColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Cars Found',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first car to start tracking maintenance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCarScreen()),
                );
                
                if (result == true) {
                  _refreshCars();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Car'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display cars list
  Widget _buildCarsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: _cars.length,
        itemBuilder: (context, index) {
          final car = _cars[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildCarCard(car),
              ),
            ),
          );
        },
      ),
    );
  }

  // Car display card
  Widget _buildCarCard(Car car) {
    final carColor = _getCarColor(car);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CarDetailsScreen(carId: car.id)),
          );
          
          if (result == true) {
            _refreshCars();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.white,
                carColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header with brand and model
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: carColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      car.brand,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: carColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        car.model ?? 'Car',
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
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Car image or default icon
                    Hero(
                      tag: 'car_image_${car.id}',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: car.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  car.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      FontAwesomeIcons.car,
                                      size: 40,
                                      color: carColor.withOpacity(0.5),
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                FontAwesomeIcons.car,
                                size: 40,
                                color: carColor.withOpacity(0.5),
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Car information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Model',
                            value: car.modelYear.toString(),
                            color: carColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.confirmation_number,
                            label: 'Plate Number',
                            value: car.carNumber,
                            color: carColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.card_membership,
                            label: 'License',
                            value: car.carLicense,
                            color: carColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Button section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CarDetailsScreen(carId: car.id)),
                    );
                    
                    if (result == true) {
                      _refreshCars();
                    }
                  },
                  icon: Icon(
                    Icons.directions_car,
                    color: carColor,
                  ),
                  label: Text(
                    'View Details',
                    style: TextStyle(
                      color: carColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Car info row
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
          size: 18,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Get appropriate color for the car
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
    return _selectedColor;
  }
} 