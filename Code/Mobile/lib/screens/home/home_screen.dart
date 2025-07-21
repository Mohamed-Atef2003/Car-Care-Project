import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:flutter_application_1/screens/services/booking_screen.dart';
import 'package:flutter_application_1/Chat/chat%20bot/chatbot_screen.dart';
import 'package:flutter_application_1/screens/services/electricity_service.dart';
import 'package:flutter_application_1/screens/services/emergency_screen.dart';
import 'package:flutter_application_1/screens/services/gasoline_service.dart';
import 'package:flutter_application_1/screens/services/service_centers_screen.dart';
import 'package:flutter_application_1/screens/services/support_services_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../auth/account_information_screen.dart';
import '../../auth/edit_profile_screen.dart';
import '../cars/my_cars_screen.dart';
import '../../screens/services/services.dart';
import '../../Chat/customer chat/customer_service_chat_screen.dart';
import '../orders/order_history_screen.dart';
import '../appointments/my_appointments_screen.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/services/preferences_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../settings/help_support_screen.dart';
import '../settings/about_app_screen.dart';

import '../store/glass_screen.dart';
import '../store/spare_parts_screen.dart';
import '../store/tires_screen.dart';
import '../store/tools_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // final _selectedColor = Colors.indigo;
  final _selectedColor = AppColors.primary;
  final _unselectedColor = Colors.grey;

  // Current user position for distance calculation
  Position? _currentPosition;

  // Carousel controllers
  late PageController _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize carousel
    _carouselController = PageController(viewportFraction: 0.9, initialPage: 0);
    _startCarouselTimer();

    // Get current location for service center distances
    _getCurrentLocation();
  }

  // Start auto-scrolling carousel
  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselController.hasClients) {
        if (_currentCarouselPage < 9) {
          _currentCarouselPage++;
        } else {
          _currentCarouselPage = 0;
        }

        _carouselController.animateToPage(
          _currentCarouselPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Handle page change
  void _handleCarouselPageChange(int page) {
    setState(() {
      _currentCarouselPage = page;
    });
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
          center['distance'] =
              0.0; // Default value when location is not available
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
          center['longitude']);

      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = (distanceInMeters / 1000);
      center['distance'] = double.parse(distanceInKm.toStringAsFixed(1));
    }

    // Rebuild UI to reflect new distances
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildHomeTab(),
                  _buildServicesTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
            _buildBottomTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello,',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (user != null)
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: TextStyle(
                        color: _selectedColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: () async {
          // Update data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCarousel(),
            const SizedBox(height: 24),
            _buildSectionHeader('Main Services', 'View All'),
            const SizedBox(height: 16),
            _buildServicesGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildPromotionCard(),
            const SizedBox(height: 16),
            _buildNearbyServiceCenters(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildAllServicesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<UserProvider>(builder: (context, userProvider, child) {
        final user = userProvider.user;

        // If user data is not available, show loading indicator or load the data
        if (user == null) {
          // Attempt to load user data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            userProvider.loadUser();
          });

          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile information
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    backgroundImage: AssetImage('assets/image/7309681.jpg'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account options
            _buildProfileSection('Account Options', [
              _buildProfileOption(
                Icons.person_outline,
                'Account Information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountInformationScreen(),
                    ),
                  );
                },
              ),
              _buildProfileOption(Icons.car_crash_outlined, 'My Cars'),
              _buildProfileOption(
                Icons.history,
                'Order History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen(),
                    ),
                  );
                },
              ),
              _buildProfileOption(
                Icons.calendar_month,
                'My Appointments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyAppointmentsScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            // Other options
            _buildProfileSection('Other Options', [
              _buildProfileOption(Icons.help_outline, 'Help & Support'),
              _buildProfileOption(Icons.info_outline, 'About App'),
              _buildProfileOption(Icons.logout, 'Sign Out', isLogout: true),
            ]),
            const SizedBox(height: 32),

            Text(
              'Version 1.1.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }

  Widget _buildBottomTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _selectedColor,
        unselectedLabelColor: _unselectedColor,
        indicatorColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(
            icon: Icon(Icons.home),
            text: 'Home',
          ),
          Tab(
            icon: Icon(Icons.miscellaneous_services),
            text: 'Services',
          ),
          Tab(
            icon: Icon(Icons.person),
            text: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final items = [
      {
        'image': 'assets/image/home1.png',
        'title': 'Full Maintenance',
        'subtitle': 'Get 30% discount on full maintenance',
        'color': Colors.blue.shade800,
      },
      {
        'image': 'assets/image/home2.png',
        'title': 'Car Wash',
        'subtitle': 'Premium washing service at best prices',
        'color': Colors.teal.shade700,
      },
      {
        'image': 'assets/image/home3.png',
        'title': 'Genuine Spare Parts',
        'subtitle': 'One year warranty on all spare parts',
        'color': Colors.orange.shade800,
      },
      {
        'image': 'assets/image/car_painting.jpg',
        'title': 'Car Painting',
        'subtitle': 'Get 30% discount on car painting',
        'color': Colors.green.shade800,
      },
      {
        'image': 'assets/image/car_shop.png',
        'title': 'Car Shop Service',
        'subtitle': 'Comprehensive car shop solutions for your needs',
        'color': Colors.blue.shade800,
      },
      {
        'image': 'assets/image/car_wheel.jpg',
        'title': 'Spare Parts',
        'subtitle': 'Genuine spare parts with warranty',
        'color': Colors.teal.shade700,
      },
      {
        'image': 'assets/image/car_wash.jpg',
        'title': 'Car Wash',
        'subtitle': 'Experience premium car washing services',
        'color': Colors.green.shade800,
      },
      {
        'image': 'assets/image/car_repair.jpg',
        'title': 'Car Repair',
        'subtitle': 'Expert repairs and maintenance services',
        'color': Colors.orange.shade800,
      },
      {
        'image': 'assets/image/car_oil.jpg',
        'title': 'Oil Change',
        'subtitle': 'Quick oil change and filter replacement',
        'color': Colors.red.shade800,
      },
      {
        'image': 'assets/image/car_towing.png',
        'title': 'Towing Service',
        'subtitle': '24/7 emergency towing support',
        'color': Colors.purple.shade800,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: items.length,
            controller: _carouselController,
            onPageChanged: _handleCarouselPageChange,
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuint,
                margin: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: _currentCarouselPage == index ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: DecorationImage(
                    image: AssetImage(item['image'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.transparent,
                        (item['color'] as Color).withOpacity(0.8),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['subtitle'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: const Text(
                          'Learn More',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Carousel indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCarouselPage == index ? 16 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _currentCarouselPage == index
                    ? _selectedColor
                    : _selectedColor.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    // Here we'll select only 4 main services from the full list to display on the home page
    final services = [
      {
        'icon': FontAwesomeIcons.gasPump,
        'title': 'Gasoline Service',
        'color': Colors.teal
      },
      {
        'icon': FontAwesomeIcons.carBattery,
        'title': 'Electricity',
        'color': Colors.green
      },
      {
        'icon': FontAwesomeIcons.carSide,
        'title': 'Car Wash',
        'color': Colors.lightBlue
      },
      {
        'icon': FontAwesomeIcons.truck,
        'title': 'Towing Service',
        'color': Colors.grey
      },
    ];

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: services.map((service) {
          return _buildServiceItemWithTap(
            icon: service['icon'] as IconData,
            title: service['title'] as String,
            color: service['color'] as Color,
            onTap: () {
              // When clicking on a specific service
              print('Clicked on service: ${service['title']}');
              if (service['title'] == 'Towing Service') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TowingServicePage(),
                  ),
                );
              } else if (service['title'] == 'Electricity') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ElectricityServicePage(),
                  ),
                );
              } else if (service['title'] == 'Car Wash') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WashingServicePage(),
                  ),
                );
              } else if (service['title'] == 'Gasoline Service') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GasolineServicePage(),
                  ),
                );
              }
              // You can add navigation to service details page here
              // Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: service)));
            },
          );
        }).toList(),
      ),
    );
  }

  // Improved function to display individual service item with click capability
  Widget _buildServiceItemWithTap({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Shorten service title if it's too long
    final displayTitle =
        title.length > 12 ? '${title.substring(0, 10)}...' : title;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Update the all services display function as well
  Widget _buildAllServicesGrid() {
    final services = [
      {
        'icon': FontAwesomeIcons.car,
        'title': 'Maintenance',
        'color': Colors.orange
      },
      {
        'icon': FontAwesomeIcons.wrench,
        'title': 'Spare Parts',
        'color': Colors.purple
      },
      {
        'icon': FontAwesomeIcons.oilCan,
        'title': 'Oil Change',
        'color': Colors.green
      },
      {
        'icon': FontAwesomeIcons.carBattery,
        'title': 'Electricity',
        'color': Colors.blue
      },
      {
        'icon': FontAwesomeIcons.sprayCan,
        'title': 'Paint',
        'color': Colors.red
      },
      {
        'icon': FontAwesomeIcons.gasPump,
        'title': 'Gasoline Service',
        'color': Colors.teal
      },
      {
        'icon': FontAwesomeIcons.screwdriverWrench,
        'title': 'Repair',
        'color': Colors.indigo
      },
      {
        'icon': FontAwesomeIcons.soap,
        'title': 'Car Wash',
        'color': Colors.lightBlue
      },
      {'icon': FontAwesomeIcons.road, 'title': 'Tires', 'color': Colors.brown},
      {
        'icon': FontAwesomeIcons.windowRestore,
        'title': 'Glass',
        'color': Colors.cyan
      },
      {
        'icon': FontAwesomeIcons.toolbox,
        'title': 'Tools',
        'color': Colors.deepOrange
      },
      {
        'icon': FontAwesomeIcons.clock,
        'title': 'Booking',
        'color': Colors.pink
      },
      {
        'icon': FontAwesomeIcons.headset,
        'title': 'Customer Service',
        'color': Colors.deepPurple
      },
      {
        'icon': FontAwesomeIcons.robot,
        'title': 'Chat Bot',
        'color': Colors.blue
      },
      {
        'icon': FontAwesomeIcons.kitMedical,
        'title': 'Emergency',
        'color': Colors.red
      },
      {
        'icon': FontAwesomeIcons.dharmachakra,
        'title': 'Wheel',
        'color': Colors.brown
      },
      {
        'icon': FontAwesomeIcons.snowflake,
        'title': 'AC Service',
        'color': Colors.cyan
      },
      {
        'icon': FontAwesomeIcons.key,
        'title': 'Key Programming',
        'color': Colors.indigo
      },
      {
        'icon': FontAwesomeIcons.gauge,
        'title': 'Diagnostics',
        'color': Colors.deepOrange
      },
      {
        'icon': FontAwesomeIcons.truck,
        'title': 'Towing Service',
        'color': Colors.grey
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceItemWithTap(
          icon: service['icon'] as IconData,
          title: service['title'] as String,
          color: service['color'] as Color,
          onTap: () {
            // When clicking on a specific service
            print('Clicked on service: ${service['title']}');

            // Navigate to the appropriate service details page
            if (service['title'] == 'Maintenance') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaintenanceServicePage(),
                ),
              );
            } else if (service['title'] == 'Paint') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaintingServicePage(),
                ),
              );
            } else if (service['title'] == 'Car Wash') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WashingServicePage(),
                ),
              );
            } else if (service['title'] == 'Diagnostics') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiagnosticsServicePage(),
                ),
              );
            } else if (service['title'] == 'AC Service') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ACServicePage(),
                ),
              );
            } else if (service['title'] == 'Oil Change') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OilChangeServicePage(),
                ),
              );
            } else if (service['title'] == 'Repair') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RepairServicePage(),
                ),
              );
            } else if (service['title'] == 'Tools') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ToolsScreen(),
                ),
              );
            } else if (service['title'] == 'Glass') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GlassScreen(),
                ),
              );
            } else if (service['title'] == 'Spare Parts') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SparePartsScreen(),
                ),
              );
            } else if (service['title'] == 'Wheel') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WheelServicePage(),
                ),
              );
            } else if (service['title'] == 'Key Programming') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KeyProgrammingServicePage(),
                ),
              );
            } else if (service['title'] == 'Towing Service') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TowingServicePage(),
                ),
              );
            } else if (service['title'] == 'Gasoline Service') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GasolineServicePage(),
                ),
              );
            } else if (service['title'] == 'Electricity') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ElectricityServicePage(),
                ),
              );
            } else if (service['title'] == 'Tires') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TiresScreen(),
                ),
              );
            } else if (service['title'] == 'Emergency') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyScreen(),
                ),
              );
            } else if (service['title'] == 'Booking') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(),
                ),
              );
            } else if (service['title'] == 'Customer Service') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerServiceChatScreen(),
                ),
              );
            } else if (service['title'] == 'Chat Bot') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatbotScreen(),
                ),
              );
            }
            // More services can be added later
          },
        );
      },
    );
  }

  Widget _buildPromotionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withBlue(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Special Offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '50% Discount on Full Maintenance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Offer valid until the end of month',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: _selectedColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image/car-maintenance.png'),
                fit: BoxFit.cover,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            // Add different actions based on section type and action button
            if (title == 'Main Services' && action == 'View All') {
              _tabController
                  .animateTo(1); // Navigate to Services page (index 1)
            } else if (title == 'Maintenance Status' && action == 'Details') {
              // Can add function to show maintenance details
              print('Show maintenance details');
              // Can open a new page here
              // Navigator.push(context, MaterialPageRoute(builder: (context) => MaintenanceDetailsScreen()));
            } else if (title == 'Recent Activities' && action == 'More') {
              // Can add function to show more activities
              print('Show more recent activities');
              // Can open a new page here
              // Navigator.push(context, MaterialPageRoute(builder: (context) => ActivitiesScreen()));
            }
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: [
              Text(
                action,
                style: TextStyle(
                  color: _selectedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_back_ios,
                size: 14,
                color: _selectedColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyServiceCenters() {
    // Sort centers by distance if available
    List<Map<String, dynamic>> nearestCenters = [];

    if (ServiceCentersScreen.serviceCenters.isNotEmpty) {
      // Create a copy to avoid modifying the original list when sorting
      nearestCenters = List.from(ServiceCentersScreen.serviceCenters);

      // Ensure all centers have a distance value
      for (var center in nearestCenters) {
        if (center['distance'] == null) {
          center['distance'] = 0.0;
        }
      }

      // Sort by distance
      nearestCenters.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Limit to 2 nearest centers for display
      if (nearestCenters.length > 2) {
        nearestCenters = nearestCenters.sublist(0, 2);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: const Text(
                  'Nearby Service Centers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4), // Small space between title and buttons
              Row(
                mainAxisSize:
                    MainAxisSize.min, // Make this Row take minimum space
                children: [
                  // Add refresh button
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: _selectedColor,
                      size: 20,
                    ),
                    onPressed: () {
                      // Get current location and update distances
                      _getCurrentLocation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Updating distances...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Refresh distances',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                  const SizedBox(width: 4), // Reduced from 8
                  TextButton(
                    onPressed: () {
                      // Navigate to the advanced service centers screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceCentersScreen(),
                        ),
                      ).then((_) {
                        // Refresh the UI when returning from service centers screen
                        setState(() {});
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(30, 30), // Reduced size
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Make child Row take minimum space
                      children: [
                        Text(
                          'Map',
                          style: TextStyle(
                            color: _selectedColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13, // Smaller font size
                          ),
                        ),
                        const SizedBox(width: 2), // Reduced from 4
                        Icon(
                          Icons.arrow_back_ios,
                          size: 12, // Smaller icon
                          color: _selectedColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Real Google Maps implementation
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _currentPosition == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          color: Colors.grey[700],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text('Waiting for location...'),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: _getCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Get Location',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 12,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    markers: ServiceCentersScreen.serviceCenters
                        .map((center) => Marker(
                              markerId: MarkerId(center['id']),
                              position: LatLng(
                                center['latitude'],
                                center['longitude'],
                              ),
                              infoWindow: InfoWindow(
                                title: center['name'],
                                snippet: '${center['distance']} km',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                center['isOpen']
                                    ? BitmapDescriptor.hueGreen
                                    : BitmapDescriptor.hueRed,
                              ),
                            ))
                        .toSet(),
                    onTap: (_) {
                      // Navigate to the full map view
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceCentersScreen(),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Display actual service centers based on distance
          if (nearestCenters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No service centers available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...nearestCenters.map((center) {
              return Column(
                children: [
                  _buildServiceCenter(
                    name: center['name'],
                    address: center['address'],
                    distance: '${center['distance']} km',
                    isOpen: center['isOpen'] ?? false,
                    centerId: center['id'],
                  ),
                  if (center != nearestCenters.last) const Divider(height: 24),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildServiceCenter({
    required String name,
    required String address,
    required String distance,
    required bool isOpen,
    String? centerId,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to the service centers screen when tapping on a service center
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ServiceCentersScreen(),
          ),
        ).then((_) {
          // Refresh the UI when returning from service centers screen
          setState(() {});
        });
      },
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green.withOpacity(0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: isOpen ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      distance,
                      style: TextStyle(
                        color: _selectedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: isOpen ? Colors.green : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.directions,
              color: _selectedColor,
              size: 20,
            ),
            onPressed: () {
              // Navigate to the service centers screen with directions mode
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceCentersScreen(),
                ),
              ).then((_) {
                setState(() {});
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Directions',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> options) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...options,
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ??
          () async {
            if (isLogout) {
              // Execute logout
              // Delete user data from Provider
              Provider.of<UserProvider>(context, listen: false).logout();

              // Save logout state in preferences
              await PreferencesService.logout();

              if (context.mounted) {
                // Navigate to login screen
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            } else if (title == 'My Cars') {
              // Navigate to My Cars page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyCarsScreen()),
              );
            } else if (title == 'Help & Support') {
              // Navigate to Help & Support page
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen()),
              );
            } else if (title == 'About App') {
              // Navigate to About App page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
            } else {
              // Print selected option for testing purposes
              print('Clicked on: $title');
            }
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isLogout ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : Colors.grey[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isLogout ? Colors.red : Colors.black,
                fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (!isLogout)
              Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.grey[700],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickActionItem(
                icon: FontAwesomeIcons.clock,
                title: 'Booking',
                color: Colors.pink,
                onTap: () {
                  // Navigate to appointment booking
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionItem(
                icon: Icons.map,
                title: 'Find Centers',
                color: Colors.green,
                onTap: () {
                  // Navigate to service centers map
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceCentersScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionItem(
                icon: Icons.support_agent,
                title: 'Live Support',
                color: Colors.orange,
                onTap: () {
                  // Open live support chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportServicesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.grey[100],
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: IconButton(
  //       icon: Icon(icon, color: Colors.grey[700]),
  //       onPressed: onPressed,
  //     ),
  //   );
  // }
}

// Simple chart painter for demonstration
class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final dotPaint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // Sample fuel consumption data points
    const int points = 7;
    final data = [6.8, 7.5, 9.2, 8.3, 7.1, 7.8, 8.2];
    final maxData = data.reduce((a, b) => a > b ? a : b);

    final path = Path();
    final startX = 0.0;
    final endX = size.width;

    for (int i = 0; i < points; i++) {
      final x = startX + (endX - startX) * i / (points - 1);
      final normalizedValue = data[i] / maxData;
      final y = size.height - normalizedValue * size.height * 0.8;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
