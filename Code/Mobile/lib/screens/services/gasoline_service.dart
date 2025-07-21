import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/car.dart';
import '../../payment/payment_details_screen.dart';
import '../../screens/cars/my_cars_screen.dart';
import '../../models/payment_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';


class GasolineServicePage extends StatefulWidget {
  const GasolineServicePage({super.key});

  @override
  State<GasolineServicePage> createState() => _GasolineServicePageState();
}

class _GasolineServicePageState extends State<GasolineServicePage> with SingleTickerProviderStateMixin {
  // Variables to track selected options
  String _selectedFuelType = 'Gasoline 92';
  double _fuelAmount = 20;
  DateTime _deliveryDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _deliveryTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 2)),
  );
  // New variable to store price per liter
  double _pricePerLiter = 0.0;
  // Variable for vehicle type
  // Selected car
  Car? _selectedCar;
  List<Car> _userCars = [];
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // List of fuel types
  final List<String> _fuelTypes = [
    'Gasoline 95',
    'Gasoline 92',
    'Gasoline 90',
    'Gasoline 80',
    'Diesel',
    'Natural Gas',
    'Solar'
  ];

  
  // Function to determine price per liter based on fuel type
  double getFuelPrice(String fuelType) {
    switch (fuelType) {
      case 'Gasoline 95':
        return 17.25;
      case 'Gasoline 92':
        return 15.20;
      case 'Gasoline 90':
        return 13.75;
      case 'Gasoline 80':
        return 11.50;
      case 'Diesel':
        return 12.90;
      case 'Natural Gas':
        return 8.75;
      case 'Solar':
        return 12.40;
      default:
        return 15.20; // Default price
    }
  }

  // Function to determine fuel icon color based on type
  Color getFuelColor(String fuelType) {
    switch (fuelType) {
      case 'Gasoline 95':
        return Colors.purple;
      case 'Gasoline 92':
        return Colors.red.shade700;
      case 'Gasoline 90':
        return Colors.orange.shade800;
      case 'Gasoline 80':
        return Colors.amber.shade600;
      case 'Diesel':
        return Colors.grey.shade800;
      case 'Natural Gas':
        return Colors.blue.shade700;
      case 'Solar':
        return Colors.brown.shade600;
      default:
        return Colors.teal;
    }
  }

  // Function to determine fuel icon based on type
  IconData getFuelIcon(String fuelType) {
    if (fuelType.contains('Gasoline')) {
      return FontAwesomeIcons.gasPump;
    } else if (fuelType == 'Diesel' || fuelType == 'Solar') {
      return FontAwesomeIcons.truck;
    } else if (fuelType == 'Natural Gas') {
      return FontAwesomeIcons.fire;
    } else {
      return FontAwesomeIcons.oilCan;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
    // Set initial price based on default fuel type
    _pricePerLiter = getFuelPrice(_selectedFuelType);
    
    // Load user cars
    _loadUserCars();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Fuel Service',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade500],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    // _buildFuelLevelMonitor(),
                    _buildFuelCalculator(),
                    _buildFuelOrderForm(),
                    // _buildEmergencyFuelServiceCard(),
                    // _buildPackagesButton(context, features, packages),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const MyPackagesScreen(),
      //       ),
      //     );
      //   },
      //   icon: const Icon(Icons.inventory_2),
      //   label: const Text('باقاتي'),
      //   backgroundColor: Colors.green,
      // ),
    );
  }

  // Header section with background image
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://img.freepik.com/free-photo/gas-station-night_1127-3006.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color.fromRGBO(0, 0, 0, 0.6),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            // color: Colors.black.withValues(alpha: 51),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.gasPump,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Smart Fuel Delivery',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 179),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'The best way to get fuel wherever you are',
                style: GoogleFonts.cairo(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Fuel calculator
  Widget _buildFuelCalculator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 26),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.calculator,
                  size: 18,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Fuel Consumption Calculator',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fuel quantity indicator
          Text(
            'Fuel Quantity (Liters)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              activeTrackColor: Colors.teal.shade600,
              inactiveTrackColor: Colors.teal.withValues(alpha: 26),
              thumbColor: Colors.teal.shade700,
              overlayColor: Colors.teal.withValues(alpha: 51),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: Slider(
              value: _fuelAmount,
              min: 5,
              max: 120,
              divisions: 55,
              label: _fuelAmount.round().toString(),
              onChanged: (value) {
                setState(() {
                  _fuelAmount = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 Liters',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_fuelAmount.round()} Liters',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ),
              Text(
                '120 Liters',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Calculations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildCalculationRow('Price per Liter', '${_pricePerLiter.toStringAsFixed(2)} EGP'),
                const SizedBox(height: 8),
                _buildCalculationRow('Total Quantity', '${_fuelAmount.round()} Liters'),
                const SizedBox(height: 8),
                _buildCalculationRow('Delivery Fee', '15 EGP'),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildCalculationRow(
                  'Total',
                  '${(_fuelAmount * _pricePerLiter + 15).toStringAsFixed(2)} EGP',
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 8),
                _buildCalculationRow(
                  'Estimated Distance',
                  getEstimatedConsumptionForCar(_selectedCar, _selectedFuelType),
                  isInfo: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Vehicle information section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 1),
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
                    Text(
                      'My Cars',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to My Cars screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyCarsScreen(),
                          ),
                        ).then((_) {
                          // Reload cars on return
                          _loadUserCars();
                        });
                      },
                      icon: const Icon(Icons.directions_car, size: 16),
                      label: Text(
                        'Change Car',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_userCars.isEmpty)
                  Center(
                    child: Text(
                      'No cars registered',
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Car>(
                        isExpanded: true,
                        value: _selectedCar,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        borderRadius: BorderRadius.circular(12),
                        onChanged: (car) {
                          if (car != null) {
                            setState(() {
                              _selectedCar = car;
                            });
                          }
                        },
                        items: _userCars.map((car) {
                          IconData vehicleIcon = _getVehicleIcon(car);
                          Color carColor = _getCarColor(car);
                          
                          return DropdownMenuItem<Car>(
                            value: car,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: carColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    vehicleIcon,
                                    color: carColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${car.brand} ${car.model ?? ''}',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${car.modelYear} • ${car.carNumber}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_selectedCar != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Vehicle Type: ${_selectedCar!.model ?? 'Car'}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
        ],
      ),
    );
  }
  
  Widget _buildCalculationRow(String label, String value, {bool isTotal = false, bool isInfo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : isInfo ? Colors.teal.shade800 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.teal.shade800 : isInfo ? Colors.teal.shade700 : Colors.black,
          ),
        ),
      ],
    );
  }
  
  // Fuel order form
  Widget _buildFuelOrderForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 26),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.gasPump,
                  size: 18,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Request Fuel Delivery',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Select fuel type
          Text(
            'Fuel Type',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedFuelType,
                items: _fuelTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          getFuelIcon(type),
                          color: getFuelColor(type),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type,
                style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '(${getFuelPrice(type).toStringAsFixed(2)} EGP)',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFuelType = value!;
                    // Update price when fuel type changes
                    _pricePerLiter = getFuelPrice(_selectedFuelType);
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Select vehicle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Vehicle',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedCar == null)
                  Text(
                    'No car selected',
                    style: GoogleFonts.cairo(color: Colors.grey.shade600),
                  )
                else
                  Row(
                    children: [
                      Icon(
                        _getVehicleIcon(_selectedCar!),
                        color: Colors.teal.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedCar!.brand} (${_selectedCar!.modelYear})',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'License Plate: ${_selectedCar!.carNumber}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
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
                          foregroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        child: Text(
                          'Change',
                          style: GoogleFonts.cairo(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Delivery option
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver Fuel to Your Location',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fuel will be delivered to your registered address',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Select delivery time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Date',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.teal.shade700,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _deliveryDate = pickedDate;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
                              style: GoogleFonts.cairo(),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.teal.shade700,
                            ),
                          ],
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
                    Text(
                      'Delivery Time',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _deliveryTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.teal.shade700,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _deliveryTime = pickedTime;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_deliveryTime.hour}:${_deliveryTime.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.cairo(),
                            ),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.teal.shade700,
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
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.teal.withValues(alpha: 128),
              ),
              child: Text(
                'Confirm Order',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  
  // Function to estimate fuel consumption based on car type and fuel type
  String getEstimatedConsumptionForCar(Car? car, String fuelType) {
    if (car == null) {
      return '0 km';
    }
    
    double baseConsumption = 0.0;
    String model = (car.model ?? '').toLowerCase();
    String brand = car.brand.toLowerCase();
    
    // Determine consumption based on car model/brand keywords
    if (model.contains('pickup') || brand.contains('hilux') || brand.contains('f-150') || brand.contains('silverado')) {
      baseConsumption = 14.0; // Pickup
    } 
    else if (model.contains('suv') || model.contains('crossover') || model.contains('rav4') || 
             model.contains('explorer') || model.contains('patrol') || model.contains('land cruiser')) {
      baseConsumption = 12.0; // SUV
    } 
    else if (model.contains('van') || model.contains('caravan') || model.contains('odyssey')) {
      baseConsumption = 10.0; // Van
    }
    else if (model.contains('coupe') || model.contains('sport') || model.contains('convertible') ||
             brand.contains('ferrari') || brand.contains('lamborghini')) {
      baseConsumption = 15.0; // Sports car
    }
    else if (model.contains('hatchback') || model.contains('compacto')) {
      baseConsumption = 7.5; // Hatchback
    }
    else {
      baseConsumption = 8.0; // Default (sedan)
    }
    
    // Adjust consumption rate based on fuel type
    double fuelFactor = 1.0;
    switch (fuelType) {
      case 'Gasoline 95':
        fuelFactor = 0.95;
        break;
      case 'Gasoline 92':
        fuelFactor = 0.98;
        break;
      case 'Gasoline 90':
        fuelFactor = 1.0;
        break;
      case 'Gasoline 80':
        fuelFactor = 1.1;
        break;
      case 'Diesel':
        fuelFactor = 0.8;
        break;
      case 'Natural Gas':
        fuelFactor = 0.9;
        break;
      default:
        fuelFactor = 1.0;
    }
    
    double adjustedConsumption = baseConsumption * fuelFactor;
    
    // Estimated distance
    double estimatedDistance = _fuelAmount / (adjustedConsumption / 100);
    
    return '${estimatedDistance.toStringAsFixed(0)} km approximately';
  }

  // Load user cars
  Future<void> _loadUserCars() async {
    try {
      final customerId = Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      
      if (customerId.isEmpty) {
        setState(() {
          _userCars = [];
        });
        return;
      }
      
      final QuerySnapshot carDocs = await FirebaseFirestore.instance
          .collection("cars")
          .where("customerId", isEqualTo: customerId)
          .get();

      if (carDocs.docs.isEmpty) {
        setState(() {
          _userCars = [];
        });
        return;
      }

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
          customerId: data['customerId'] ?? customerId,
          color: data['color'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _userCars = loadedCars;
          if (_userCars.isNotEmpty && _selectedCar == null) {
            _selectedCar = _userCars.first;
          }
        });
      }
    } catch (e) {
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
  
  IconData _getVehicleIcon(Car car) {
    car.brand.toLowerCase();
    String model = (car.model ?? '').toLowerCase();
    
    // Trucks and pickups
    if (model.contains('pickup') || model.contains('f-150') || model.contains('silverado') || 
        model.contains('hilux') || model.contains('tacoma')) {
      return FontAwesomeIcons.truckPickup;
    }
    // Vans
    else if (model.contains('van') || model.contains('caravan') || model.contains('odyssey') ||
             model.contains('sienna')) {
      return FontAwesomeIcons.vanShuttle;
    }
    // SUVs
    else if (model.contains('suv') || model.contains('explorer') || model.contains('rav4') ||
            model.contains('patrol') || model.contains('land cruiser') || model.contains('jeep')) {
      return FontAwesomeIcons.truck;
    }
    // Sports cars, coupes, luxury cars
    else if (model.contains('coupe') || model.contains('convertible') || model.contains('mustang') ||
            model.contains('camaro') || model.contains('corvette') || model.contains('bmw') ||
            model.contains('mercedes') || model.contains('audi')) {
      return FontAwesomeIcons.carSide;
    }
    // Default (sedan)
    else {
      return FontAwesomeIcons.car;
    }
  }

  // Function to submit order
  void _submitOrder() {
    // Send order
    HapticFeedback.heavyImpact();
    
    // Calculate total cost and delivery
    final double deliveryCost = 15.0; // Fixed delivery fee
    final double fuelCost = _fuelAmount * _pricePerLiter; // Fuel cost
    
    // Calculate tax (if applicable) - assuming 14% VAT on service 
    final double taxRate = 0.14; // Tax rate
    final double taxAmount = fuelCost * taxRate; // Tax amount
    
    // Total cost with tax
    final double totalCost = fuelCost + taxAmount + deliveryCost;
    
  
    
    
    // Navigate to payment page with necessary information
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateToPaymentPage(fuelCost, deliveryCost, totalCost, taxAmount);
    });
  }
  
  // Function to navigate to payment page
  void _navigateToPaymentPage(double fuelCost, double deliveryCost, double totalCost, double taxAmount) {
    // Create a unique order ID
    final String orderId = 'FUEL-${DateTime.now().millisecondsSinceEpoch}';
    
    // Get user information from provider if available
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    final String customerName = userProvider.user != null 
        ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
        : "Guest";
    final String? customerPhone = userProvider.user?.mobile;
    final String? customerEmail = userProvider.user?.email;
    
    // Create payment summary object
    final paymentSummary = PaymentSummary(
      subtotal: fuelCost,
      tax: taxAmount, // Tax amount calculated
      deliveryFee: deliveryCost,
      discount: 0.0, // Discount can be applied if available
      total: totalCost,
      currency: 'EGP', // Local currency
      items: [
        {
          'id': 'fuel_service_${_selectedFuelType.replaceAll(" ", "_").toLowerCase()}',
          'serviceType': 'Fuel Service',
          'name': '$_selectedFuelType (${_fuelAmount.round()} Liters)',
          'price': fuelCost,
          'quantity': 1,
          'category': 'Service',
          'description': 'Fuel delivery service for $_selectedFuelType'
        }
      ],
      additionalData: {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'orderId': orderId,
        'serviceType': 'Fuel Service',
        'serviceName': '$_selectedFuelType Delivery',
        'packageName': '$_selectedFuelType Delivery' ' (${_fuelAmount.round()} Liters)',
        'fuelType': _selectedFuelType,
        'fuelAmount': _fuelAmount.round(),
        'pricePerLiter': _pricePerLiter,
        'deliveryDate': '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
        'deliveryTime': '${_deliveryTime.hour}:${_deliveryTime.minute.toString().padLeft(2, '0')}',
        'carInfo': _selectedCar != null ? '${_selectedCar!.brand} - ${_selectedCar!.modelYear}' : 'Not specified',
        'title': 'Fuel Payment',
        'showDelivery': true,
        'orderDate': DateTime.now().toIso8601String(),
        'orderStatus': 'pending',
      },
    );
    
    // Navigate to payment page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(
          paymentSummary: paymentSummary,
          orderId: orderId,
        ),
      ),
    );
  }

  double getEstimatedConsumption(String vehicleType) {
    // Determine base consumption rate by vehicle type
    double baseConsumption;
    
    // Use car model to determine consumption
    if (_selectedCar != null) {
      String model = (_selectedCar!.model ?? '').toLowerCase();
      String brand = _selectedCar!.brand.toLowerCase();
      
      if (model.contains('pickup') || brand.contains('hilux') || brand.contains('f-150') || brand.contains('silverado')) {
        baseConsumption = 14.0; // Pickup
      } 
      else if (model.contains('suv') || model.contains('crossover') || model.contains('rav4') || 
               model.contains('explorer') || model.contains('patrol') || model.contains('land cruiser')) {
        baseConsumption = 12.0; // SUV
      } 
      else if (model.contains('van') || model.contains('caravan') || model.contains('odyssey')) {
        baseConsumption = 10.0; // Van
      }
      else if (model.contains('coupe') || model.contains('sport') || model.contains('convertible') ||
               brand.contains('ferrari') || brand.contains('lamborghini')) {
        baseConsumption = 15.0; // Sports car
      }
      else if (model.contains('hatchback') || model.contains('compacto')) {
        baseConsumption = 7.5; // Hatchback
      }
      else {
        baseConsumption = 8.0; // Default (sedan)
      }
    } else {
      baseConsumption = 8.0; // Default consumption
    }

    // Adjust consumption based on fuel type
    switch (_selectedFuelType) {
      case 'Gasoline 95':
        baseConsumption *= 0.95;
        break;
      case 'Gasoline 92':
        baseConsumption *= 0.98;
        break;
      case 'Gasoline 90':
        baseConsumption *= 1.0;
        break;
      case 'Gasoline 80':
        baseConsumption *= 1.1;
        break;
      case 'Diesel':
        baseConsumption *= 0.8;
        break;
      case 'Natural Gas':
        baseConsumption *= 0.9;
        break;
      default:
        baseConsumption *= 1.0;
    }

    return baseConsumption;
  }

  // Get appropriate car color
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
    return Colors.teal.shade700;
  }
} 