import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../../models/car.dart';
import 'edit_car_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final String carId;
  
  const CarDetailsScreen({
    super.key,
    required this.carId,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  // final _selectedColor = AppColors.primary;
  late Car? _car;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCarDetails();
  }
  
  // Get customer ID from UserProvider
  String getCustomerId() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.user?.id ?? '';
  }
  
  // Load car data from Firestore
  Future<void> _loadCarDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Print debug information
      final customerId = getCustomerId();
      print('====== Start loading car details ======');
      print('Car ID: ${widget.carId}');
      print('Current customer ID: $customerId');
      
      // Load data from Firestore directly
      final DocumentReference carRef = FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId);
          
      print('Document reference created: ${carRef.path}');
      
      // Execute the query
      final DocumentSnapshot carSnapshot = await carRef.get();
      
      print('Query executed, document exists: ${carSnapshot.exists}');
      
      if (!carSnapshot.exists) {
        // If car is not found in Firestore
        print('Car not found with ID: ${widget.carId}');
        setState(() {
          _car = null;
          _isLoading = false;
        });
        return;
      }
      
      // Load car data from Firestore
      final data = carSnapshot.data() as Map<String, dynamic>;
      
      // Print document contents
      print('Car document contents:');
      data.forEach((key, value) {
        print('$key: $value');
      });
      
      // Verify car belongs to current user
      final carCustomerId = data['customerId'] as String?;
      
      if (customerId.isNotEmpty && carCustomerId != null && carCustomerId != customerId) {
        // Car doesn't belong to current user
        print('Car does not belong to current user. User ID: $customerId, Car owner ID: $carCustomerId');
        setState(() {
          _car = null;
          _isLoading = false;
        });
        return;
      }
      
      // Parse the model year value - handle both string and int formats
      int modelYear = 0;
      if (data['modelYear'] is int) {
        modelYear = data['modelYear'];
      } else if (data['modelYear'] is String) {
        modelYear = int.tryParse(data['modelYear'] ?? '0') ?? 0;
      }
      
      // Convert data to Car object
      final car = Car(
        id: carSnapshot.id,
        brand: data['brand'] ?? '',
        model: data['model'],
        trim: data['trim'],
        engine: data['engine'],
        version: data['version'],
        modelYear: modelYear,
        carNumber: data['carNumber'] ?? '',
        carLicense: data['carLicense'] ?? '',
        imageUrl: data['imageUrl'],
        customerId: data['customerId'],
        color: data['color'],
      );
      
      print('Car object created: ${car.brand} ${car.model ?? ""} ${car.trim ?? ""} (${car.modelYear})');
      
      setState(() {
        _car = car;
        _isLoading = false;
      });
      
      print('====== Finished loading car details ======');
    } catch (e) {
      print('Error loading car details: $e');
      print('====== Failed to load car details ======');
      setState(() {
        _car = null;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading car data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCarScreen(car: _car!),
                ),
              ).then((_) {
                // Reload car details after editing
                _loadCarDetails();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteCar,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car banner with image
                  _buildCarBanner(),
                  
                  // Car details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCarInfoCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCarBanner() {
    final car = _car!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: car.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      car.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          FontAwesomeIcons.car,
                          size: 60,
                          color: Colors.indigo,
                        );
                      },
                    ),
                  )
                : const Icon(
                    FontAwesomeIcons.car,
                    size: 60,
                    color: Colors.indigo,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            car.brand,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (car.model != null && car.model!.isNotEmpty) ...[
            Text(
              car.model!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (car.trim != null && car.trim!.isNotEmpty)
              Text(
                car.trim!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.indigo,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            'Model ${car.modelYear}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (car.engine != null && car.engine!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                car.engine!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildCarInfoCard() {
    final car = _car!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Car Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const Divider(height: 24),
            // Car brand and model
            _buildInfoRow(
              'Brand',
              car.brand,
              Icons.directions_car,
            ),
            const SizedBox(height: 12),
            
            // Car model
            if (car.model != null)
              _buildInfoRow(
                'Model',
                car.model!,
                Icons.car_crash,
              ),
              
            // Car trim level
            if (car.trim != null && car.trim!.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Trim Level',
                    car.trim!,
                    Icons.star,
                  ),
                ],
              ),
              
            // Car engine
            if (car.engine != null && car.engine!.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Engine',
                    car.engine!,
                    Icons.settings,
                  ),
                ],
              ),
              
            // Car version
            if (car.version != null && car.version!.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Version',
                    car.version!,
                    Icons.new_releases,
                  ),
                ],
              ),
              
            const SizedBox(height: 12),
            
            // Model year
            _buildInfoRow(
              'Model Year',
              car.modelYear.toString(),
              Icons.calendar_today,
            ),
            
            const SizedBox(height: 12),
            
            // Car color
            _buildInfoRow(
              'Color',
              car.color ?? 'Not specified',
              Icons.color_lens,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.indigo,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
  
  
  // Delete car
  void _deleteCar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: const Text(
          'Are you sure you want to delete this car? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete car from Firestore only
                await FirebaseFirestore.instance
                    .collection('cars')
                    .doc(widget.carId)
                    .delete();
                
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Close details page with true result
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Car deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error deleting car: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting car'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context); // Close dialog only
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 