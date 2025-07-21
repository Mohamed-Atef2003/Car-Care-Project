import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math'; // Import math library
import 'service_detail_page.dart';
import '../../models/car.dart';
import '../cars/add_car_screen.dart';
import '../cars/my_cars_screen.dart'; // Import cars display file
import 'service_centers_screen.dart'; // Import service centers file
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../appointments/my_appointments_screen.dart'; // Import for MyAppointmentsScreen

// Circle pattern painter (for decoration)
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.fill;

    // Draw some circles for decoration
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 25, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 18, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 12, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Map background painter
class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE3F2FD)
      ..style = PaintingStyle.fill;

    // Map background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw some areas with different colors to represent regions on the map
    paint.color = const Color(0xFFDCEDC8)
        .withAlpha(128); // 0.5 opacity is 128 in alpha (0-255)
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * 0.3, size.height * 0.4), paint);

    paint.color = const Color(0xFFF0F4C3).withAlpha(128);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.5, size.height * 0.3, size.width * 0.5,
            size.height * 0.4),
        paint);

    // Draw buildings
    paint.color = const Color(0xFFE0E0E0);
    for (int i = 0; i < 20; i++) {
      final left = (i * 53) % size.width.toInt();
      final top = ((i * 31) % size.height.toInt()).toDouble();
      final width = ((i % 5) + 1) * 10.0;
      final height = ((i % 3) + 1) * 10.0;

      canvas.drawRect(
          Rect.fromLTWH(left.toDouble(), top, width, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Roads painter on the map
class RoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
          .withAlpha(179) // 0.7 opacity is approximately 179 in alpha (0-255)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // Draw horizontal roads
    for (int i = 1; i < 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // Draw vertical roads
    for (int i = 1; i < 6; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Draw some diagonal roads
    canvas.drawLine(
        Offset(0, 0), Offset(size.width * 0.4, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width * 0.6, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.2, size.height),
        Offset(size.width * 0.6, size.height * 0.3), roadPaint);

    // Draw road directions
    final dashedPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw dashed lines on main roads
    for (int i = 1; i < 5; i++) {
      final y = size.height * (i / 5);
      drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), dashedPaint);
    }
  }

  // Helper function to draw a dashed line
  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Create and use path directly instead of storing in an unused variable
    canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(end.dx, end.dy),
        paint);

    const dashWidth = 5;
    const dashSpace = 5;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final count = sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace);
    final dxStep = dx / count;
    final dyStep = dy / count;

    var startX = start.dx;
    var startY = start.dy;

    for (int i = 0; i < count; i++) {
      final endX = startX + dxStep;
      final endY = startY + dyStep;

      if (i % 2 == 0) {
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }

      startX = endX;
      startY = endY;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dark map background painter
class DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2639)
      ..style = PaintingStyle.fill;

    // Dark map background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw some main streets with a slightly darker color
    final roadPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    // Horizontal streets
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );

    // Vertical streets
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );

    // Add some minor streets
    final minorRoadPaint = Paint()
      ..color = const Color(0xFF34495E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    // Horizontal minor streets
    for (int i = 1; i < 5; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }

    // Vertical minor streets
    for (int i = 1; i < 6; i++) {
      final x = size.width * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // Draw areas with different colors (neighborhoods)
    final areaPaint = Paint()..style = PaintingStyle.fill;

    // Area 1
    areaPaint.color = const Color(0xFF2C3E50).withOpacity(0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.3, size.height * 0.3),
      areaPaint,
    );

    // Area 2
    areaPaint.color = const Color(0xFF27AE60).withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height * 0.3),
      areaPaint,
    );

    // Area 3
    areaPaint.color = const Color(0xFFE74C3C).withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.7,
        0,
        size.width * 0.3,
        size.height * 0.3,
      ),
      areaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RepairServicePage extends StatefulWidget {
  const RepairServicePage({super.key});

  @override
  State<RepairServicePage> createState() => _RepairServicePageState();
}

class _RepairServicePageState extends State<RepairServicePage>
    with SingleTickerProviderStateMixin {
  // Variables to track selected options
  String _selectedVehicleType = 'Car';
  String _selectedIssueType = 'Engine Problem';
  final double _urgencyLevel = 3;
  bool _needsPickupService = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _activeStep = 0;
  int _selectedServiceCenter = 0;
  String _problemDescription = '';
  late TabController _tabController;

  // Variables for cars
  List<Car> _myCars = [];
  int _selectedCarIndex = 0;
  bool _isLoading = true;

  // Function to update car list
  void _refreshCars() {
    _loadUserCars();
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
            const SnackBar(content: Text('You must login first')),
          );
        }
        setState(() {
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
            _myCars = [];
            _selectedCarIndex = 0;
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
          _myCars = cars;
          if (_selectedCarIndex >= _myCars.length) {
            _selectedCarIndex = 0;
          }
          if (_myCars.isNotEmpty) {
            _selectedVehicleType = _getVehicleTypeInEnglish(_myCars[_selectedCarIndex].model ?? "Unknown");
          }
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
          _myCars = [];
          _selectedCarIndex = 0;
          _isLoading = false;
        });
      }
    }
  }

  // Access to service centers from ServiceCentersScreen
  late List<Map<String, dynamic>> _serviceCenters;

  // Selected service center (integer representing index)
  // int _selectedServiceCenter = 0;

  // List of issue types
  final List<String> _issueTypes = [
    'Engine Problem',
    'Brake Problem',
    'Suspension Problem',
    'Steering Problem',
    'Electrical Problem',
    'Cooling System Problem',
    'Transmission Problem',
    'Unknown Problem',
  ];

  // ميزات خدمة الإصلاح
  final List<Map<String, String>> _repairFeatures = [
    {
      'title': 'Advanced Diagnostic',
      'description': 'Comprehensive analysis of car problems using the latest technology',
    },
    {
      'title': 'Complete Engine Repair',
      'description': 'Handle all engine problems from minor to major issues',
    },
    {
      'title': 'Transmission System Repair',
      'description': 'Repair and maintenance of gearbox, clutch and drive system',
    },
    {
      'title': 'Electronic Systems Repair',
      'description': 'Diagnosis and repair of electrical and electronic problems',
    },
    {
      'title': 'Quick Repair Service',
      'description': 'Urgent and fast repairs for emergency issues',
    },
    {
      'title': 'On-site Repair Service',
      'description': 'Mobile team reaches you wherever you are to repair your car',
    },
  ];

  // باقات خدمة الإصلاح
  final List<Map<String, dynamic>> _repairPackages = [
    {
      'name': 'Basic Repair',
      'price': 399,
      'features': [
        'Problem diagnosis',
        'Simple repairs',
        'Post-repair inspection',
        'One month warranty',
        'Vehicle status report',
      ],
    },
    {
      'name': 'Advanced Repair',
      'price': 799,
      'features': [
        'Advanced problem diagnosis',
        'Repair of most complex issues',
        'Replacement of damaged parts',
        '3 months warranty',
        'Transportation to and from the center',
      ],
    },
    {
      'name': 'Comprehensive Repair',
      'price': 1499,
      'features': [
        'Complete vehicle diagnosis',
        'Repair of all problems',
        'Original spare parts',
        '6 months warranty',
        'Transportation service',
        'Replacement vehicle',
        'Detailed report',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_calculateEstimatedCost);

    // الحصول على سيارات المستخدم من Firestore
    _loadUserCars();

    // الحصول على مراكز الخدمة
    _serviceCenters = _getServiceCentersData();

    // حساب التكلفة التقديرية المبدئية
    _calculateEstimatedCost();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Calculate estimated cost
  void _calculateEstimatedCost() {

    // Base cost by vehicle type
    switch (_selectedVehicleType) {
      case 'Car':
        break;
      case 'Motorcycle':
        break;
      case 'Small Truck':
        break;
      case 'Large Truck':
        break;
      case 'Bus':
        break;
    }

    // Add cost based on problem type
    switch (_selectedIssueType) {
      case 'Engine Problem':
        break;
      case 'Brake Problem':
        break;
      case 'Suspension Problem':
        break;
      case 'Steering Problem':
        break;
      case 'Electrical Problem':
        break;
      case 'Cooling System Problem':
        break;
      case 'Transmission Problem':
        break;
      case 'Unknown Problem':
        break;
    }

    // Add pickup service cost if required
    if (_needsPickupService) {
    }

    // Add cost based on urgency level
    if (_urgencyLevel >= 4) {
// 25% increase for urgent service
    }

    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D3E50),
        foregroundColor: Colors.white,
        title: const Text('Repair Service',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2D3E50),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2D3E50),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                onTap: (index) {
                  setState(() {
                    _activeStep = index;
                  });
                },
                tabs: const [
                  Tab(
                    icon: Icon(Icons.car_repair_outlined, size: 22),
                    text: 'Vehicle & Problem',
                  ),
                  Tab(
                    icon: Icon(Icons.schedule, size: 22),
                    text: 'Schedule & Payment',
                  ),
                  Tab(
                    icon: Icon(Icons.home_repair_service, size: 22),
                    text: 'Repair Packages',
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent horizontal scrolling
                children: [
                  _buildVehicleAndProblemTab(), // Vehicle and problem tab
                  _buildScheduleAndPaymentTab(), // Schedule and payment tab
                  _buildRepairPackagesTab(), // Repair packages tab
                ],
              ),
            ),

            // Navigation buttons between steps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_activeStep > 0)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _activeStep--;
                          _tabController.animateTo(_activeStep);
                        });
                      },
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D3E50),
                        side: const BorderSide(color: Color(0xFF2D3E50)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 130),

                  if (_activeStep < 2)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _activeStep++;
                          _tabController.animateTo(_activeStep);
                        });
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D3E50),
                        side: const BorderSide(color: Color(0xFF2D3E50)),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 130),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get urgency level label

  // Get urgency color

  // Schedule and payment tab
  Widget _buildScheduleAndPaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top info bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule & Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose a convenient time and preferred payment method',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 24),

          // Service center selection section
          _buildServiceCenterSelectionSection(),

          const SizedBox(height: 24),

          // Selected service center details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.store, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _serviceCenters[_selectedServiceCenter]['name']
                                as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _serviceCenters[_selectedServiceCenter]['address']
                                as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_serviceCenters[_selectedServiceCenter]['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Wrap the Row in a SingleChildScrollView to prevent overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildServiceCenterInfoChip(
                        '${_serviceCenters[_selectedServiceCenter]['distance']} km',
                        Icons.directions_car,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildServiceCenterInfoChip(
                        '${_serviceCenters[_selectedServiceCenter]['openHours']}',
                        Icons.access_time,
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildServiceCenterInfoChip(
                        '${(_serviceCenters[_selectedServiceCenter]['services'] as List).length} services',
                        Icons.home_repair_service,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // Date and time selection
          const Text(
            'Select Date and Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Dates list
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7, // Display 7 days
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isToday = index == 0;
                final isSelected = _isSameDay(date, _selectedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.green.withAlpha(40),
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
                                ? Colors.green.shade800
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
                                ? Colors.green
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
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 16),

          // Available time slots
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 13, // 8 time slots
              itemBuilder: (context, index) {
                final hour = 8 + index; // Starting from 9 AM
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
                      color: isSelected ? Colors.green.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? "PM" : "AM"}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.green.shade800
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
          ).animate().fadeIn(duration: 700.ms),

          const SizedBox(height: 24),

          // Book appointment button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 24, bottom: 20),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // Show loading indicator
                  setState(() {
                    _isLoading = true; // Start loading indicator
                  });

                  // Create unique ID for appointment
                  final appointmentId = 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}';

                  // Get current user ID
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final userId = userProvider.user?.id;

                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must login first to book an appointment')),
                    );
                    return;
                  }

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
                    'carId': _myCars.isNotEmpty ? _myCars[_selectedCarIndex].id : 'custom',               
                    // Service information
                    'serviceCategory': 'repair-service',
                    
                    // Service center information
                    'serviceCenter': {
                      'id': _serviceCenters[_selectedServiceCenter]['id'],
                      'name': _serviceCenters[_selectedServiceCenter]['name'],
                      'address': _serviceCenters[_selectedServiceCenter]['address'] ?? '',
                      'phone': _serviceCenters[_selectedServiceCenter]['phone'] ?? ''
                    },
                    
                    // Appointment information
                    'date': Timestamp.fromDate(_selectedDate),
                    'time': _selectedTime.format(context),
                    'appointmentDate': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    'appointmentTime': _selectedTime.format(context),
                    
                    // Issue details and requirements
                    'issue': {
                      'type': _selectedIssueType,
                      'description': _problemDescription,
                      'urgencyLevel': _urgencyLevel,
                      'needsPickup': _needsPickupService
                    },
                    
                  
                    // Service specific data
                    'serviceDetails': {}
                  };

                  // Send data to Firestore
                  await FirebaseFirestore.instance
                      .collection('appointment')
                      .doc(appointmentId)
                      .set(appointmentData);

                  // Show confirmation dialog instead of snackbar
                  setState(() {
                    _isLoading = false; // Stop loading indicator
                  });
                  
                  // Create reference code for the appointment
                  final referenceCode = 'APT-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${(appointmentId.hashCode % 10000).abs()}';
                  
                  // Show dialog with appointment details
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Appointment Confirmed', textAlign: TextAlign.center),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 60,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Repair service appointment has been successfully booked\nReference Number: $referenceCode\nDate: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}\nTime: ${_selectedTime.format(context)}\nService Center: ${_serviceCenters[_selectedServiceCenter]['name']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _urgencyLevel == 'High' ? Colors.red[100] : Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _urgencyLevel == 'High' ? Icons.priority_high : Icons.info_outline,
                                    color: _urgencyLevel == 'High' ? Colors.red[700] : Colors.blue[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _urgencyLevel == 'High' ? 'Emergency Repair' : 'Standard Repair',
                                    style: TextStyle(
                                      color: _urgencyLevel == 'High' ? Colors.red[700] : Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Thank you for choosing our service.',
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
                            Navigator.pop(context); // Return to previous screen
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
                            backgroundColor: const Color(0xFF2D3E50),
                          ),
                          child: const Text('View Appointments'),
                        ),
                      ],
                    ),
                  );
                  
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error booking appointment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  print('Error booking appointment: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3E50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 8),
                  Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 900.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get day name
  String _getDayName(int weekday) {
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

  // Get month name
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  // Build service center selection section
  Widget _buildServiceCenterSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 16, bottom: 12),
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
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedServiceCenter = index;
                      _calculateEstimatedCost();
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
                              '${center['distance']} km',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
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
          padding: const EdgeInsets.only(top: 12, right: 16),
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
                          labelStyle: TextStyle(fontSize: 12),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        TextButton.icon(
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
      ],
    );
  }

  // Create service center info chip
  Widget _buildServiceCenterInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Create a row in order summary

  // Repair packages tab
  Widget _buildRepairPackagesTab() {
    return ServiceDetailPage(
      icon: FontAwesomeIcons.wrench,
      title: 'Repair Packages',
      color: const Color(0xFF9C27B0),
      features: _repairFeatures,
      packages: _repairPackages,
    );
  }

  // Vehicle and problem tab
  Widget _buildVehicleAndProblemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top info bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Icon(
                    Icons.car_crash_outlined,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle & Problem',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select your vehicle and tell us about the problem',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 24),

          // My Cars section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Cars',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _refreshCars,
                        icon: const Icon(Icons.refresh,
                            size: 18, color: Colors.blue),
                        tooltip: 'Refresh cars list',
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyCarsScreen(),
                            ),
                          ).then((_) {
                            _refreshCars();
                          });
                        },
                        icon: const Icon(Icons.directions_car, size: 18),
                        label: const Text('View all cars'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cars display
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.blue,
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
                )
              else if (_myCars.isEmpty)
                _buildNoCarAvailableMessage()
              else
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _myCars.length + 1, // +1 for add new car card
                    itemBuilder: (context, index) {
                      if (index < _myCars.length) {
                        // User cars
                        final car = _myCars[index];
                        return _buildCarCard(
                          brand: car.brand,
                          model: car.model ?? '',
                          type: _getVehicleTypeInEnglish(car.model ?? "Unknown"),
                          color: car.color ?? 'White',
                          plateNumber: car.carNumber,
                          isSelected: index == _selectedCarIndex,
                          onTap: () {
                            setState(() {
                              _selectedCarIndex = index;
                              _selectedVehicleType = _getVehicleTypeInEnglish(car.model ?? "Unknown");
                              _calculateEstimatedCost();
                            });
                          },
                          imageUrl: car.imageUrl,
                        );
                      } else {
                        // Add new car card
                        return Container(
                          width: 240,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
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
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue.withAlpha(30),
                                  child: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.blue,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Add New Car',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
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
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Problem type selection
          const Text(
            'Problem Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Problem type grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _issueTypes.length,
            itemBuilder: (context, index) {
              final type = _issueTypes[index];
              final isSelected = type == _selectedIssueType;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIssueType = type;
                    _calculateEstimatedCost();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withAlpha(30),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        type,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade800,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // Problem description
          const Text(
            'Problem Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the problem in detail to help us diagnose it better',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
              onChanged: (value) {
                setState(() {
                  _problemDescription = value;
                });
              },
            ),
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 24),

          // مستوى الأولوية
         

          const SizedBox(height: 24),

          // خدمة سحب المركبة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.amber.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Pickup Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'We will tow your vehicle from your location to the service center',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _needsPickupService,
                  activeColor: Colors.amber,
                  onChanged: (bool value) {
                    setState(() {
                      _needsPickupService = value;
                      _calculateEstimatedCost();
                    });
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms),
        ],
      ),
    );
  }

  // Car card widget
  Widget _buildCarCard({
    required String brand,
    required String model,
    required String type,
    required String color,
    required String plateNumber,
    required bool isSelected,
    required Function() onTap,
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withAlpha(60)
                  : Colors.grey.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // محتوى البطاقة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.white.withAlpha(50)
                            : Colors.blue.withAlpha(20),
                        radius: 20,
                        child: imageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.directions_car,
                                      color: isSelected ? Colors.white : Colors.blue,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.directions_car,
                                color: isSelected ? Colors.white : Colors.blue,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$brand $model',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              type,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white.withAlpha(200)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 16,
                        color: isSelected
                            ? Colors.white.withAlpha(200)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Color: $color',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withAlpha(200)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(30)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Plate Number: $plateNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // علامة التحديد
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // No cars available message
  Widget _buildNoCarAvailableMessage() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.car,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No saved cars',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCarScreen()),
                ).then((_) {
                  _refreshCars(); 
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Car'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Convert car model to vehicle type text
  String _getVehicleTypeInEnglish(String modelName) {
    // Since we don't have car types anymore, we'll return a generic term based on the model name
    // We could implement some logic to determine the vehicle type based on the model if needed
    return 'Car';
  }

  // Get service centers data
  List<Map<String, dynamic>> _getServiceCentersData() {
    // Use service centers list directly from ServiceCentersScreen
    return ServiceCentersScreen.serviceCenters;
  }

}

