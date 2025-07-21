import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/constants/colors.dart';
import '../../models/payment_model.dart';
import '../../payment/payment_details_screen.dart';
import '../appointments/my_appointments_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/car.dart';
import 'package:geolocator/geolocator.dart';
import 'service_centers_screen.dart';

class ACServicePage extends StatefulWidget {
  const ACServicePage({super.key});

  @override
  State<ACServicePage> createState() => _ACServicePageState();
}

class _ACServicePageState extends State<ACServicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasBookedService = false;
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay(hour: 12, minute: 0);
  String? _selectedIssue;
  final TextEditingController _notesController = TextEditingController();

  // Car selection
  List<Car> _myCars = [];
  String? _selectedCarId;

  // Service center selection
  int _selectedServiceCenter = 0;
  List<Map<String, dynamic>> _serviceCenters = [];
  Position? _currentPosition;


  final List<Map<String, dynamic>> _commonIssues = [
    {
      'title': 'Weak Cooling',
      'icon': FontAwesomeIcons.temperatureLow,
      'description': 'AC works but cooling is weak or insufficient',
    },
    {
      'title': 'Bad Odors',
      'icon': FontAwesomeIcons.wind,
      'description': 'Unpleasant smells from vents when AC is running',
    },
    {
      'title': 'Strange Noises',
      'icon': FontAwesomeIcons.volumeHigh,
      'description': 'Unusual or annoying sounds from the AC system',
    },
    {
      'title': 'Water or Gas Leak',
      'icon': FontAwesomeIcons.droplet,
      'description': 'Coolant or water leaking inside the car',
    },
    {
      'title': 'AC Not Working',
      'icon': FontAwesomeIcons.powerOff,
      'description': 'AC system not working at all when turned on',
    },
    {
      'title': 'Other Issue',
      'icon': FontAwesomeIcons.circleQuestion,
      'description': 'An issue not listed here',
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Periodic AC Maintenance',
      'price': 199,
      'items': [
        'Condenser inspection and cleaning',
        'Refrigerant pressure check',
        'Fan performance test',
        'Vent cleaning',
        'Control system check',
      ],
      'icon': FontAwesomeIcons.screwdriverWrench,
      'recommendation': 'Every 6 months',
    },
    {
      'title': 'Refrigerant Recharge',
      'price': 249,
      'items': [
        'System leak check',
        'Old refrigerant evacuation',
        'New refrigerant charging',
        'Pressure adjustment',
        'System performance test',
      ],
      'icon': FontAwesomeIcons.gauge,
      'recommendation': 'When cooling is weak',
    },
    {
      'title': 'System Cleaning & Sanitizing',
      'price': 179,
      'items': [
        'Evaporator cleaning',
        'Vent cleaning',
        'Air passage sanitizing',
        'Cabin filter replacement',
        'Air freshener application',
      ],
      'icon': FontAwesomeIcons.sprayCan,
      'recommendation': 'When odors appear',
    },
    {
      'title': 'AC Leak Repair',
      'price': 349,
      'items': [
        'Comprehensive leak detection',
        'Leak repairs',
        'Damaged pipe replacement',
        'Refrigerant recharge',
        'Post-repair testing',
      ],
      'icon': FontAwesomeIcons.toolbox,
      'recommendation': 'When leaking detected',
    },
    {
      'title': 'Compressor Replacement',
      'price': 799,
      'items': [
        'Old compressor removal',
        'New compressor installation',
        'Compressor oil replacement',
        'Refrigerant charging',
        'System calibration',
      ],
      'icon': FontAwesomeIcons.gears,
      'recommendation': 'When compressor fails',
    },
  ];

  final List<Map<String, dynamic>> _tips = [
    {
      'title': 'Clean vents regularly',
      'description': 'Helps prevent dust buildup and bad odors',
      'icon': FontAwesomeIcons.broom,
    },
    {
      'title': 'Run AC once a week in winter',
      'description': 'Maintains system efficiency and prevents seal damage',
      'icon': FontAwesomeIcons.snowflake,
    },
    {
      'title': 'Replace air filter every 15,000 km',
      'description': 'Improves air quality and cooling efficiency',
      'icon': FontAwesomeIcons.filter,
    },
    {
      'title': 'Avoid running AC at maximum immediately',
      'description': 'Start at moderate temperature then lower gradually to extend AC life',
      'icon': FontAwesomeIcons.temperatureHalf,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserCars();
    _loadServiceCenters();
    _getCurrentPosition();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Load user cars from Firestore
  Future<void> _loadUserCars() async {
    setState(() {
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final customerId = userProvider.user?.id;
      
      if (customerId == null) {
        setState(() {
          _myCars = [];
        });
        return;
      }
      
      final carDocs = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: customerId)
          .get();
      
      final loadedCars = carDocs.docs.map((doc) {
        final data = doc.data();
        
        // Parse model year value
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
      
      setState(() {
        _myCars = loadedCars;
        
        // Select first car by default if available
        if (_myCars.isNotEmpty && _selectedCarId == null) {
          _selectedCarId = _myCars.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _myCars = [];
      });
      
      print('Error loading cars: $e');
    }
  }

  // Get current location
  Future<void> _getCurrentPosition() async {
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

  // Load service centers
  Future<void> _loadServiceCenters() async {
    setState(() {
    });
    
    try {
      // Use service centers from ServiceCentersScreen class
      setState(() {
        _serviceCenters = List.from(ServiceCentersScreen.serviceCenters);
      });
      
      // Update distances if location is available
      if (_currentPosition != null) {
        _updateServiceCenterDistances();
      }
    } catch (e) {
      setState(() {
      });
      print('Error loading service centers: $e');
    }
  }

  // Update service center distances based on current location
  void _updateServiceCenterDistances() {
    if (_currentPosition == null) {
      // If no position is available, set default distance
      for (var center in _serviceCenters) {
        if (center['distance'] == null) {
          center['distance'] = 0.0; // Default value when location is not available
        }
      }
      return;
    }
    
    // Update distances in all service centers
    for (var center in _serviceCenters) {
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
    
    // Sort centers by distance
    _serviceCenters.sort((a, b) {
      double distanceA = a['distance'] ?? 999.0;
      double distanceB = b['distance'] ?? 999.0;
      return distanceA.compareTo(distanceB);
    });
    
    // Rebuild UI to reflect new distances
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'AC Maintenance Service',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(FontAwesomeIcons.snowflake),
                text: 'Services',
              ),
              Tab(
                icon: Icon(FontAwesomeIcons.calendarCheck),
                text: 'Booking',
              ),
              Tab(
                icon: Icon(FontAwesomeIcons.lightbulb),
                text: 'Tips',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServicesTab(),
            _buildBookingTab(),
            _buildTipsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'AC Maintenance and Repair Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We offer a complete range of AC maintenance and repair services by specialized technicians',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        ..._services.map((service) => _buildServiceCard(service)),
        const SizedBox(height: 16),
        
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            service['icon'],
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          service['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${service['price']} EGP - ${service['recommendation']}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Service Includes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...service['items'].map<Widget>((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _bookACService(service);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Book This Service'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTab() {
    if (_hasBookedService) {
      return _buildBookingConfirmation();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Book AC Maintenance Appointment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can book an appointment for AC maintenance or repair',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        _buildBookingForm(),
      ],
    );
  }

  Widget _buildBookingForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Service center selection
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
                _serviceCenters.isEmpty || _selectedServiceCenter >= _serviceCenters.length
                    ? 'Select a service center'
                    : _serviceCenters[_selectedServiceCenter]['name'],
                style: TextStyle(
                  color: _serviceCenters.isEmpty || _selectedServiceCenter >= _serviceCenters.length
                      ? Colors.grey
                      : Colors.grey[800],
                  fontSize: 15,
                ),
              ),
              subtitle: _serviceCenters.isEmpty || _selectedServiceCenter >= _serviceCenters.length
                  ? null
                  : Text(
                      '${_serviceCenters[_selectedServiceCenter]['distance'] ?? 'Unknown'} km | Rating: ${_serviceCenters[_selectedServiceCenter]['rating']}',
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
                if (_currentPosition != null) {
                  _updateServiceCenterDistances();
                }
                _showServiceCenterBottomSheet();
              },
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          // My Car Selection
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
                if (_myCars.isEmpty)
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
                      child: DropdownButton<String>(
                        value: _selectedCarId,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
                        items: _myCars.map((car) {
                          // Get car color
                          Color carColor = _getCarColor(car.brand);
                          
                          return DropdownMenuItem<String>(
                            value: car.id,
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
                                        '${car.brand} ${car.model ?? ""}',
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
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCarId = newValue;
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
                            Navigator.pushNamed(context, '/add-car').then((_) {
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
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          const Text(
            'Select Issue Type (Required)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildIssueSelector(),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          const Text(
            'Select Appointment Date',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 24),
          const Text(
            'Select Appointment Time',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimePicker(),
          const SizedBox(height: 24),
          const Text(
            'Additional Notes (Optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any details about the issue...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedDate != null && _selectedIssue != null && _selectedCarId != null)
                      ? _confirmBooking
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDate == null || _selectedIssue == null || _selectedCarId == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Please select car, service center, issue type, date and time to confirm booking',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Add function to show service center bottom sheet
  void _showServiceCenterBottomSheet() {
    // Sort centers by distance before showing the bottom sheet
    List<Map<String, dynamic>> sortedCenters = List.from(_serviceCenters);
    
    // Ensure all centers have a distance value
    for (var center in sortedCenters) {
      if (center['distance'] == null) {
        center['distance'] = 0.0;
      }
    }
    
    if (_currentPosition != null) {
      sortedCenters.sort((a, b) {
        double distanceA = double.tryParse(a['distance'].toString()) ?? 999.0;
        double distanceB = double.tryParse(b['distance'].toString()) ?? 999.0;
        return distanceA.compareTo(distanceB);
      });
    }
    
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
                        _getCurrentPosition();
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
                          color: center['isOpen'] == true
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FontAwesomeIcons.locationDot,
                          color: center['isOpen'] == true ? Colors.green : Colors.red,
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
                          color: center['isOpen'] == true
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          center['isOpen'] == true ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            color: center['isOpen'] == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedServiceCenter = _serviceCenters.indexOf(center);
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

  // Add function to get car color based on brand
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

  Widget _buildIssueSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _commonIssues.length,
      itemBuilder: (context, index) {
        final issue = _commonIssues[index];
        final isSelected = _selectedIssue == issue['title'];

        return InkWell(
          onTap: () {
            setState(() {
              _selectedIssue = issue['title'];
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  issue['icon'],
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  issue['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : Colors.black,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7, // Display 7 days
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isToday = index == 0;
          final isSelected = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                // Reset time selection when date changes
                _selectedTime = TimeOfDay(hour: 12, minute: 0);
              });
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.red.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.red.shade800
                          : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red
                          : (isToday
                              ? Colors.blue.shade50
                              : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? Colors.blue.shade700
                                  : Colors.black),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getMonthName(date.month),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9,
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

  Widget _buildTimePicker() {
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Please select a date first',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Available time slots
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 13, // 13 time slots (8 AM to 8 PM)
        itemBuilder: (context, index) {
          final hour = 8 + index; // Starting from 8 AM
          final time = TimeOfDay(hour: hour, minute: 0);
          final isSelected = time.hour == _selectedTime.hour;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTime = time;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? "PM" : "AM"}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.red.shade800
                        : Colors.grey.shade800,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper function for day name abbreviation
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  // For full date formatting
  String _formatDate(DateTime date) {
    return '${_getWeekdayName(date.weekday)} ${date.day} ${_getMonthName(date.month)} ${date.year}';
  }
  
  // Full weekday names for other parts of the app
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Widget _buildBookingConfirmation() {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 70,
            ),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed Successfully',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildConfirmationDetail(
              'Date',
              _formatDate(_selectedDate!),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildConfirmationDetail(
              'Time',
              '${_selectedTime.hour}:00 ${_selectedTime.period == DayPeriod.am ? "AM" : "PM"}',
              Icons.access_time,
            ),
            if (_selectedIssue != null) ...[
              const SizedBox(height: 12),
              _buildConfirmationDetail(
                'Issue Type',
                _selectedIssue!,
                Icons.build,
              ),
            ],
            if (_notesController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildConfirmationDetail(
                'Notes',
                _notesController.text,
                Icons.note,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'We will send a reminder 24 hours before the appointment',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
 
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyAppointmentsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('View Appointments'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'AC System Care Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Follow these tips to maintain AC efficiency and extend its lifespan',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        ..._tips.map((tip) => _buildTipCard(tip)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circleInfo,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Did You Know?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'AC systems lose about 10% of refrigerant annually, which is why regular maintenance is recommended to maintain cooling efficiency and reduce fuel consumption.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            // Book the default AC service (periodic maintenance)
            _bookACService(_services[0]);
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text('Book AC Maintenance Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tip['icon'],
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip['description'],
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
    );
  }

  void _confirmBooking() async {
    if (_selectedDate == null || _selectedIssue == null || _selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Show loading indicator
    });

    try {
      // Create unique appointment ID
      final appointmentId = 'APT-${DateTime.now().millisecondsSinceEpoch}';
      final referenceCode = 'APT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${(appointmentId.hashCode % 10000).abs()}';

      // Get current user ID
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must login first to book an appointment')),
        );
        setState(() {});
        return;
      }
      
      // Get selected car info
      final selectedCar = _myCars.firstWhere((car) => car.id == _selectedCarId);
      
      // Get selected service center
      final selectedCenter = _serviceCenters[_selectedServiceCenter];
      
      // Format time for display and storage
      String formattedTime = '${_selectedTime.hour}:00 ${_selectedTime.period == DayPeriod.am ? "AM" : "PM"}';
      
      // Prepare appointment data according to unified model
      final appointmentData = {
        // Basic information
        'id': appointmentId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Customer information
        'customerId': userId,
        // Vehicle information (basic only)
        'carId': selectedCar.id,
        // Service information
        'serviceCategory': 'ac-service',

        // Service center information
        'serviceCenter': {
          'id': selectedCenter['id'],
          'name': selectedCenter['name'],
          'address': selectedCenter['address'],
          'phone': selectedCenter['phone'] ?? 'N/A'
        },

        // Appointment information
        'date': Timestamp.fromDate(_selectedDate!),
        'time': formattedTime,
        'appointmentDate': '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
        'appointmentTime': formattedTime,

        // Issue details and requirements
        'issue': {
          'type': _selectedIssue,
          'description': _notesController.text,
          'urgencyLevel': 'normal',
          'needsPickup': false,
        },
        'serviceDetails': {}
      };

      // Send data to Firestore
      await FirebaseFirestore.instance
          .collection('appointment')
          .doc(appointmentId)
          .set(appointmentData);

      // Update UI to show confirmation
      setState(() {
        _hasBookedService = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maintenance appointment booked successfully! Reference number: $referenceCode'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Appointments',
            onPressed: () {
              // Navigate to appointments screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyAppointmentsScreen(),
                ),
              );
            },
            textColor: Colors.white,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _bookACService(Map<String, dynamic> service) {
    // Get service details
    final String title = service['title'];
    final int price = service['price'];
    final double tax = price * 0.15; // 15% VAT
    
    // Get user data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    final String customerName = userProvider.user != null 
        ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
        : "Guest";
    final String? customerPhone = userProvider.user?.mobile;
    final String? customerEmail = userProvider.user?.email;
    
    // Verify user login
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must login to request this service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create unique order ID
    final String orderId = 'AC-${DateTime.now().millisecondsSinceEpoch}';
    
    // Prepare additional service data
    final Map<String, dynamic> additionalData = {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'orderId': orderId,
      'serviceType': 'Car AC Service',
      'packageName': title,
      'serviceItems': service['items'],
      'recommendation': service['recommendation'],
      'orderDate': DateTime.now().toIso8601String(),
      'orderStatus': 'pending',
    };

    // Show a dialog to choose payment or booking
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Booking Method'),
        content: const Text('You can pay now or book an appointment for later'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Navigate to payment screen
              final PaymentSummary paymentSummary = PaymentSummary(
                subtotal: price.toDouble(),
                tax: tax,
                deliveryFee: 0, // No delivery fees for services
                discount: 0,
                total: price.toDouble() + tax,
                currency: 'SAR',
                items: [
                  {
                    'id': 'ac_service_${title.replaceAll(" ", "_").toLowerCase()}',
                    'name': title,
                    'price': price.toDouble(),
                    'quantity': 1,
                    'category': 'Service',
                    'serviceType': 'Car AC Service',
                    'packageName': title,
                    'description': 'Car AC Service - $title',
                  }
                ],
                additionalData: additionalData,
              );
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentDetailsScreen(
                    paymentSummary: paymentSummary,
                    orderId: orderId,
                  ),
                ),
              );
            },
            child: const Text('Pay Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Set selected AC service and show booking section
              setState(() {
                _selectedIssue = title;
                if (_tabController.index != 1) {
                  _tabController.animateTo(1);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
}
