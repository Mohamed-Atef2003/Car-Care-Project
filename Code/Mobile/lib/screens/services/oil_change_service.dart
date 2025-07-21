import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/constants/colors.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../cars/add_car_screen.dart';
import '../../models/car.dart';
import 'package:intl/intl.dart';

class OilChangeServicePage extends StatefulWidget {
  const OilChangeServicePage({super.key});

  @override
  State<OilChangeServicePage> createState() => _OilChangeServicePageState();
}

class _OilChangeServicePageState extends State<OilChangeServicePage> {
  // Selected car model
  String? _selectedCarId;
  // Selected oil type
  String? _selectedOilType;
  // Selected package
  int? _selectedPackageIndex;
  // Odometer reading
  final TextEditingController _odometerController = TextEditingController();
  // Order placed
  bool _isOrderPlaced = false;
  // Order number
  String? _orderNumber;
  // Discount amount
  final double _discountAmount = 0.0;
  // Discount code
  final String _discountCode = '';
  // Car list
  List<Car> _userCars = [];
  // Loading state
  bool _isLoading = false;
  
  // Car types
  
  // Oil types
  final List<Map<String, dynamic>> _oilTypes = [
    {
      'name': 'Mineral Oil',
      'description': 'Basic mineral oil, suitable for older vehicles',
      'changeInterval': '5,000 km',
      'price': 120,
      'color': Colors.amber.shade800,
      'viscosity': '20W-50',
      'apiRating': 'SJ',
      'suitableFor': ['Older vehicles', 'Simple engines'],
      'benefits': ['Cost-effective', 'Basic protection'],
    },
    {
      'name': 'Semi-Synthetic Oil',
      'description': 'Semi-synthetic oil, balanced performance and cost',
      'changeInterval': '7,500 km',
      'price': 180,
      'color': Colors.green.shade700,
      'viscosity': '10W-40',
      'apiRating': 'SL',
      'suitableFor': ['Modern vehicles', 'Daily use'],
      'benefits': ['Better protection', 'Improved fuel economy'],
    },
    {
      'name': 'High Mileage Oil',
      'description': 'Specially formulated for high mileage vehicles (100,000+ km)',
      'changeInterval': '5,000 km',
      'price': 200,
      'color': Colors.purple.shade700,
      'viscosity': '10W-40',
      'apiRating': 'SL',
      'suitableFor': ['High mileage vehicles', 'Older engines'],
      'benefits': ['Reduces oil consumption', 'Prevents leaks'],
    },
    {
      'name': 'Fully Synthetic Oil',
      'description': 'Full synthetic oil, maximum engine performance and protection',
      'changeInterval': '10,000 km',
      'price': 250,
      'color': Colors.blue.shade700,
      'viscosity': '5W-30',
      'apiRating': 'SM',
      'suitableFor': ['New vehicles', 'Sports cars'],
      'benefits': ['Maximum protection', 'Enhanced performance in high temperatures'],
    },
    
  ];
  
  // Service packages
  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Basic',
      'items': [
        'Oil Change',
        'Oil Filter Replacement',
        'Air Filter Check',
        'Fluid Levels Check',
      ],
      'price': 0,
      'icon': FontAwesomeIcons.oilCan,
      'duration': '30-45 minutes',
      'warranty': '30 days',
    },
    {
      'name': 'Standard',
      'items': [
        'Oil Change',
        'Oil Filter Replacement',
        'Air Filter Replacement',
        'Fluid Levels Check',
        'Battery Check',
        'Lubricate Moving Parts',
        'Tire Pressure Check',
        'Brake Inspection',
      ],
      'price': 150,
      'icon': FontAwesomeIcons.wrench,
      'duration': '60-90 minutes',
      'warranty': '60 days',
    },
    {
      'name': 'Comprehensive',
      'items': [
        'Oil Change',
        'Oil Filter Replacement',
        'Air Filter Replacement',
        'Fuel Filter Replacement',
        'Fluid Levels Check',
        'Battery Check and Cleaning',
        'Brake Inspection',
        'Suspension System Check',
        'Lubricate All Moving Parts',
        'Tire Rotation',
        'Wheel Alignment Check',
        'Exhaust System Inspection',
      ],
      'price': 300,
      'icon': FontAwesomeIcons.toolbox,
      'duration': '120-150 minutes',
      'warranty': '90 days',
    },
    {
      'name': 'Premium',
      'items': [
        'Oil Change',
        'Oil Filter Replacement',
        'Air Filter Replacement',
        'Fuel Filter Replacement',
        'Cabin Air Filter Replacement',
        'Complete Fluid Check and Top-up',
        'Battery Check and Cleaning',
        'Complete Brake Inspection',
        'Suspension System Check',
        'Lubricate All Moving Parts',
        'Tire Rotation and Balance',
        'Wheel Alignment',
        'Exhaust System Inspection',
        'Engine Performance Check',
        'Computer Diagnostics',
      ],
      'price': 450,
      'icon': FontAwesomeIcons.crown,
      'duration': '180-210 minutes',
      'warranty': '120 days',
    },
  ];
  
  // Add service history tracking

  // Add maintenance schedule
  
  @override
  void initState() {
    super.initState();
    _loadUserCars();
    _loadServiceHistory();
    _loadMaintenanceSchedule();
  }
  
  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Oil Change Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isOrderPlaced ? _buildOrderConfirmation() : _buildServiceForm(),
    );
  }
  
  Widget _buildServiceForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          _buildSectionTitle('Car Type'),
          _buildCarTypeSelector(),
          _buildSectionTitle('Select Oil Type'),
          _buildOilTypeSelector(),
          _buildSectionTitle('Select Service Package'),
          _buildPackageSelector(),
          _buildSectionTitle('Odometer Reading (km)'),
          _buildOdometerInput(),
          if (_selectedCarId != null && _selectedOilType != null && 
              _selectedPackageIndex != null && _odometerController.text.isNotEmpty)
            _buildServicePreview(),
          _buildSubmitButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  Widget _buildHeroSection() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Oil Change Service',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The Most Important Regular Maintenance for Your Car',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildInfoItem(
                    FontAwesomeIcons.clock,
                    '20-30 minutes',
                    'Service Duration',
                  ),
                  _buildInfoItem(
                    FontAwesomeIcons.calendarCheck,
                    'Every 5-15,000 km',
                    'Regular Maintenance',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Regular oil changes extend the life of your engine and improve car performance while reducing fuel consumption',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedOilType != null && _odometerController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.calendarAlt,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next Service Due',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _calculateNextServiceWithDetails(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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
              ),
            ],
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.oilCan,
              color: Colors.white.withOpacity(0.8),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
  
  Widget _buildCarTypeSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                      foregroundColor: AppColors.primary,
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
                  final car = _userCars[index];
                  final isSelected = _selectedCarId == car.id;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCarId = car.id;
                      });
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Car Image or Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: car.imageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    car.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      FontAwesomeIcons.car,
                                      color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Icon(
                                  FontAwesomeIcons.car,
                                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                  size: 24,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            car.brand,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${car.modelYear} - ${car.carNumber}',
                            style: TextStyle(
                              color: isSelected ? AppColors.primary.withOpacity(0.8) : Colors.grey.shade600,
                              fontSize: 12,
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
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Car',
                            style: TextStyle(
                              color: AppColors.primary,
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
    );
  }
  
  Widget _buildOilTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _oilTypes.map((oilType) {
          final isSelected = _selectedOilType == oilType['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedOilType = oilType['name'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? oilType['color'] : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: oilType['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isSelected 
                            ? Icons.check_circle 
                            : FontAwesomeIcons.droplet,
                        color: oilType['color'],
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oilType['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          oilType['description'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Change Interval: ${oilType['changeInterval']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${oilType['price']} EGP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPackageSelector() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final package = _packages[index];
          final isSelected = _selectedPackageIndex == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPackageIndex = index;
              });
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        package['icon'] as IconData,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          package['price'] > 0 
                              ? '+ ${package['price']} EGP' 
                              : 'Free',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    package['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: package['items'].length > 3 
                          ? 3 
                          : package['items'].length,
                      itemBuilder: (context, itemIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  package['items'][itemIndex],
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (package['items'].length > 3)
                    Text(
                      '+ ${package['items'].length - 3} Additional Services',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildOdometerInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _odometerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter Current Odometer Reading',
              suffixText: 'km',
              prefixIcon: const Icon(FontAwesomeIcons.gaugeHigh),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                // This triggers a rebuild to update the UI
              });
            },
          ),
          if (_selectedOilType != null && _odometerController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          FontAwesomeIcons.calendarCheck,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Oil Change Due',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _calculateNextService(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildServiceDateEstimate(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.exclamationTriangle,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Based on $_selectedOilType with a change interval of ${_oilTypes.firstWhere((oil) => oil['name'] == _selectedOilType)['changeInterval']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
  
  String _calculateNextService() {
    if (_selectedOilType == null || _odometerController.text.isEmpty) {
      return '';
    }

    final selectedOil = _oilTypes.firstWhere(
      (oil) => oil['name'] == _selectedOilType,
      orElse: () => {'changeInterval': '5000'},
    );

    final currentOdometer = int.tryParse(_odometerController.text) ?? 0;
    final intervalKm = int.parse(selectedOil['changeInterval'].replaceAll(RegExp(r'[^\d]'), ''));
    final nextServiceKm = currentOdometer + intervalKm;

    return '$nextServiceKm km';
  }
  
  String _calculateNextServiceWithDetails() {
    if (_selectedOilType == null || _odometerController.text.isEmpty) {
      return '';
    }

    final selectedOil = _oilTypes.firstWhere(
      (oil) => oil['name'] == _selectedOilType,
      orElse: () => {'changeInterval': '5000'},
    );

    final currentOdometer = int.tryParse(_odometerController.text) ?? 0;
    final intervalKm = int.parse(selectedOil['changeInterval'].replaceAll(RegExp(r'[^\d]'), ''));
    final nextServiceKm = currentOdometer + intervalKm;
    
    // Estimate date based on average daily driving
    final averageDailyKm = 50; // Assuming average of 50km per day
    final daysUntilService = intervalKm / averageDailyKm;
    final nextServiceDate = DateTime.now().add(Duration(days: daysUntilService.round()));
    final formattedDate = DateFormat('dd MMM yyyy').format(nextServiceDate);
    
    return '$nextServiceKm km (Est. $formattedDate)';
  }
  
  Widget _buildServiceDateEstimate() {
    if (_selectedOilType == null || _odometerController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedOil = _oilTypes.firstWhere(
      (oil) => oil['name'] == _selectedOilType,
      orElse: () => {'changeInterval': '5000'},
    );

    final intervalKm = int.parse(selectedOil['changeInterval'].replaceAll(RegExp(r'[^\d]'), ''));
    
    // Calculate date based on realistic driving patterns
    final lightUse = intervalKm / 20; // 20km per day (city driving)
    final averageUse = intervalKm / 40; // 40km per day (mixed city/highway)
    final heavyUse = intervalKm / 60; // 60km per day (frequent highway)
    
    final lightDate = DateFormat('dd MMM').format(DateTime.now().add(Duration(days: lightUse.round())));
    final averageDate = DateFormat('dd MMM').format(DateTime.now().add(Duration(days: averageUse.round())));
    final heavyDate = DateFormat('dd MMM').format(DateTime.now().add(Duration(days: heavyUse.round())));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Date (based on usage):',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _buildUsageEstimate('City', lightDate, Colors.green),
            const SizedBox(width: 8),
            _buildUsageEstimate('Mixed', averageDate, Colors.orange),
            const SizedBox(width: 8),
            _buildUsageEstimate('Highway', heavyDate, Colors.red),
          ],
        ),
      ],
    );
  }
  
  Widget _buildUsageEstimate(String label, String date, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    // Calculate total price
    double totalPrice = 0;
    if (_selectedOilType != null) {
      // Find selected oil price
      final selectedOil = _oilTypes.firstWhere(
        (oil) => oil['name'] == _selectedOilType,
        orElse: () => {'price': 0},
      );
      totalPrice += (selectedOil['price'] as int).toDouble();
    }
    
    if (_selectedPackageIndex != null) {
      // Add package price
      totalPrice += (_packages[_selectedPackageIndex!]['price'] as int).toDouble();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalPrice EGP',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _canSubmit() ? _placeOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text(
              'Place Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _canSubmit() {
    return _selectedCarId != null && 
           _selectedOilType != null && 
           _selectedPackageIndex != null &&
           _odometerController.text.isNotEmpty;
  }
  
  void _placeOrder() {
    // Get selected car data
    Car? selectedCar;
    if (_selectedCarId != null) {
      selectedCar = _userCars.firstWhere(
        (car) => car.id == _selectedCarId,
        orElse: () => Car(
          id: '',
          brand: 'Unknown',
          modelYear: 0,
          carNumber: '',
          carLicense: '',
        ),
      );
    }

    // Get user information
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    
    // Check if user is logged in
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must log in to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate total price
    double totalPrice = 0;
    double oilPrice = 0;
    double packagePrice = 0;
    String packageName = "";
    
    // Oil price
    if (_selectedOilType != null) {
      final selectedOil = _oilTypes.firstWhere(
        (oil) => oil['name'] == _selectedOilType,
        orElse: () => {'price': 0, 'name': ''},
      );
      oilPrice = (selectedOil['price'] as int).toDouble();
      totalPrice += oilPrice;
    }
    
    // Package price
    if (_selectedPackageIndex != null) {
      packagePrice = (_packages[_selectedPackageIndex!]['price'] as int).toDouble();
      packageName = _packages[_selectedPackageIndex!]['name'] as String;
      totalPrice += packagePrice;
    }
    
    // Calculate tax
    double taxAmount = totalPrice * 0.15; // 15% VAT
    
    // Create payment summary
    final paymentSummary = PaymentSummary(
      subtotal: totalPrice, // Total service cost
      tax: taxAmount, // 15% VAT
      deliveryFee: 0, // No delivery fee
      discount: _discountAmount, // Discount amount if any
      total: totalPrice + taxAmount - _discountAmount, // Final total after adding tax and discount
      currency: 'EGP',
      items: [
        {
          'id': 'oil_change_service',
          'name': 'Oil Change Service',
          'price': oilPrice,
          'quantity': 1,
          'category': 'Service',
          'serviceType': 'Oil Change',
        },
        {
          'id': 'oil_change_package_${_selectedPackageIndex ?? 0}',
          'name': packageName,
          'price': packagePrice,
          'quantity': 1,
          'category': 'Package',
        }
      ],
      additionalData: {
        'carId': _selectedCarId,
        'carBrand': selectedCar?.brand,
        'carModel': selectedCar?.model,
        'carYear': selectedCar?.modelYear,
        'carNumber': selectedCar?.carNumber,
        'oilType': _selectedOilType,
        'serviceType': 'Oil Change',
        'packageName': packageName,  // Add package name to additionalData
        'odometer': _odometerController.text,
        'customerId': customerId,
        'customerName': userProvider.user != null 
            ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
            : "Guest",
        'customerPhone': userProvider.user?.mobile,
        'customerEmail': userProvider.user?.email,
        'discountCode': _discountCode.isNotEmpty ? _discountCode : null,
        'orderDate': DateTime.now().toIso8601String(),
        'orderStatus': 'pending',
        'nextServiceKm': _calculateNextService(),
        'nextServiceDate': DateTime.now().add(Duration(days: (int.parse(_calculateNextService().split(' ')[0]) / 50).round())).toIso8601String(),
      },
    );
    
    // Create unique order number
    final now = DateTime.now();
    final String orderId = 'OC${now.year}${now.month}${now.day}${now.hour}${now.minute}';
    
    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => PaymentProvider(),
          child: PaymentDetailsScreen(
            paymentSummary: paymentSummary,
            orderId: orderId,
          ),
        ),
      ),
    ).then((result) {
      // Store order number
      _orderNumber = orderId;
      
      // Show success dialog only if payment completed successfully
      // and not when returning from payment screen
      if (result == 'payment_success') {
        _saveServiceToHistory();
        _showSuccessDialog();
        _resetForm();
      }
    }
    );
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Confirmed Successfully!'),
          content: Text('Order Number: $_orderNumber'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _resetForm() {
    setState(() {
      _selectedCarId = null;
      _selectedOilType = null;
      _selectedPackageIndex = null;
      _odometerController.clear();
      _isOrderPlaced = false;
    });
  }
  
  Widget _buildOrderConfirmation() {
    // Get selected car data
    Car? selectedCar;
    if (_selectedCarId != null) {
      selectedCar = _userCars.firstWhere(
        (car) => car.id == _selectedCarId,
        orElse: () => Car(
          id: '',
          brand: 'Unknown',
          modelYear: 0,
          carNumber: '',
          carLicense: '',
        ),
      );
    }

    // Calculate total price
    double totalPrice = 0;
    if (_selectedOilType != null) {
      final selectedOil = _oilTypes.firstWhere(
        (oil) => oil['name'] == _selectedOilType,
        orElse: () => {'price': 0},
      );
      totalPrice += (selectedOil['price'] as int).toDouble();
    }
    
    if (_selectedPackageIndex != null) {
      totalPrice += (_packages[_selectedPackageIndex!]['price'] as int).toDouble();
    }
    
    // Get selected package data
    final selectedPackage = _selectedPackageIndex != null
        ? _packages[_selectedPackageIndex!]
        : null;
    
    // Get selected oil data
    final selectedOil = _oilTypes.firstWhere(
      (oil) => oil['name'] == _selectedOilType,
      orElse: () => {
        'name': '',
        'changeInterval': '',
        'color': Colors.grey,
      },
    );
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Order Confirmed Successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Order Number: $_orderNumber',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildOrderDetail(
                  'Car Type',
                  selectedCar != null ? '${selectedCar.brand} ${selectedCar.modelYear}' : '-',
                  FontAwesomeIcons.car,
                ),
                _buildOrderDetail(
                  'Oil Type',
                  _selectedOilType ?? '-',
                  FontAwesomeIcons.droplet,
                  selectedOil['color'],
                ),
                _buildOrderDetail(
                  'Service Package',
                  selectedPackage?['name'] ?? '-',
                  FontAwesomeIcons.box,
                ),
                _buildOrderDetail(
                  'Odometer Reading',
                  '${_odometerController.text} km',
                  FontAwesomeIcons.gaugeHigh,
                ),
                _buildOrderDetail(
                  'New Oil',
                  'After ${selectedOil['changeInterval']}',
                  FontAwesomeIcons.calendar,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Oil Price',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_oilTypes.firstWhere(
                              (oil) => oil['name'] == _selectedOilType,
                              orElse: () => {'price': 0},
                            )['price']} EGP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Package Price',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${selectedPackage?['price'] ?? 0} EGP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax (15%)',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(totalPrice * 0.15).toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Show discount if any
                      if (_discountAmount > 0)
                      ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Discount',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_discountCode.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '($_discountCode)',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '- ${_discountAmount.toStringAsFixed(2)} EGP',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            // If there's a discount, apply it to the total
                            _discountAmount > 0
                              ? '${(totalPrice - _discountAmount).toStringAsFixed(2)} EGP'
                              : '$totalPrice EGP',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Important Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Regular oil changes according to manufacturer recommendations is crucial for maintaining engine performance and extending its life. Refer to your car\'s manual for specific recommendations.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Return to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderDetail(String label, String value, IconData icon, [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

      print('====== Starting to load cars ======');
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
          SnackBar(content: Text('An error occurred while loading cars: $e')),
        );
        setState(() {
          _userCars = [];
          _isLoading = false;
        });
      }
    }
  }

  // Refresh car list
  void _refreshCars() {
    _loadUserCars();
  }

  // Load service history from Firestore
  Future<void> _loadServiceHistory() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null) return;
      
      
      setState(() {
      });
    } catch (e) {
      print('Error loading service history: $e');
    }
  }

  // Load maintenance schedule from Firestore
  Future<void> _loadMaintenanceSchedule() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null) return;
      
      
      setState(() {
      });
    } catch (e) {
      print('Error loading maintenance schedule: $e');
    }
  }

  // Save service to history
  Future<void> _saveServiceToHistory() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null || _selectedCarId == null || _selectedOilType == null || _selectedPackageIndex == null) return;
      
      // Calculate next service date based on oil type
      final selectedOil = _oilTypes.firstWhere(
        (oil) => oil['name'] == _selectedOilType,
        orElse: () => {'changeInterval': '5000'},
      );
      
      final intervalKm = int.parse(selectedOil['changeInterval'].replaceAll(RegExp(r'[^\d]'), ''));
      final nextServiceKm = int.parse(_odometerController.text) + intervalKm;
      
      // Save to Firestore
      await FirebaseFirestore.instance.collection('service_history').add({
        'userId': userId,
        'carId': _selectedCarId,
        'serviceType': 'Oil Change',
        'oilType': _selectedOilType,
        'package': _packages[_selectedPackageIndex!]['name'],
        'odometer': int.parse(_odometerController.text),
        'date': FieldValue.serverTimestamp(),
        'nextServiceKm': nextServiceKm,
      });
      
      // Update maintenance schedule
      await FirebaseFirestore.instance
          .collection('maintenance_schedule')
          .doc(_selectedCarId)
          .set({
            'userId': userId,
            'carId': _selectedCarId,
            'nextServiceKm': nextServiceKm,
            'lastServiceKm': int.parse(_odometerController.text),
            'lastServiceDate': FieldValue.serverTimestamp(),
          });
      
      // Refresh data
      _loadServiceHistory();
      _loadMaintenanceSchedule();
    } catch (e) {
      print('Error saving service history: $e');
    }
  }

  // Build service history

  // Build maintenance schedule

  // Add a new widget to show service preview before order
  Widget _buildServicePreview() {
    // Calculate total price
    if (_selectedOilType != null) {
      _oilTypes.firstWhere(
        (oil) => oil['name'] == _selectedOilType,
        orElse: () => {'price': 0},
      );
    }
    
    if (_selectedPackageIndex != null) {
    }
    
// 15% VAT

    // Get car details
    final selectedCar = _userCars.firstWhere(
      (car) => car.id == _selectedCarId,
      orElse: () => Car(
        id: '',
        brand: 'Unknown',
        modelYear: 0,
        carNumber: '',
        carLicense: '',
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Review',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildSummaryItem(
            icon: FontAwesomeIcons.car,
            title: 'Vehicle',
            value: '${selectedCar.brand} ${selectedCar.modelYear}',
          ),
          _buildSummaryItem(
            icon: FontAwesomeIcons.oilCan,
            title: 'Oil Type',
            value: _selectedOilType ?? '-',
          ),
          _buildSummaryItem(
            icon: FontAwesomeIcons.tools,
            title: 'Service Package',
            value: _selectedPackageIndex != null ? _packages[_selectedPackageIndex!]['name'] : '-',
          ),
          _buildSummaryItem(
            icon: FontAwesomeIcons.tachometerAlt,
            title: 'Current Odometer',
            value: '${_odometerController.text} km',
          ),
          _buildSummaryItem(
            icon: FontAwesomeIcons.calendarAlt,
            title: 'Next Service',
            value: _calculateNextService(),
          ), 
        ],
      ),
    );
  }

  // Helper method for summary items
  Widget _buildSummaryItem({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for price items
} 