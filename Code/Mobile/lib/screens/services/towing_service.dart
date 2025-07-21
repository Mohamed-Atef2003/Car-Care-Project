import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import 'package:provider/provider.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/user_provider.dart';
import 'emergency_screen.dart';

class TowingServicePage extends StatefulWidget {
  const TowingServicePage({super.key});

  @override
  State<TowingServicePage> createState() => _TowingServicePageState();
}

class _TowingServicePageState extends State<TowingServicePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Car Towing Service',
        'description': 'Towing service for disabled or damaged vehicles to the workshop or desired destination',
        'icon': Icons.car_rental,
        'price': 350.0,
      },
      {
        'title': 'Disabled Car Transport',
        'description': 'Safe transport of disabled vehicles using specially equipped trucks',
        'icon': Icons.local_shipping,
        'price': 400.0,
      },
      {
        'title': 'Highway Assistance',
        'description': 'Fast emergency service on highways and external roads with standard response time',
        'icon': Icons.speed,
        'price': 300.0,
      },
      {
        'title': 'Off-road Vehicle Recovery',
        'description': 'Specialized service for towing vehicles stuck in sand, mud, or rough terrain',
        'icon': Icons.terrain,
        'price': 450.0,
      },
      {
        'title': 'Luxury Car Transport',
        'description': 'Special transportation service for luxury and sports cars using specialized equipment',
        'icon': Icons.directions_car,
        'price': 550.0,
      },
      {
        'title': 'Long Distance Transport Service',
        'description': 'Transport of vehicles over long distances between cities with guaranteed protection and safety',
        'icon': Icons.route,
        'price': 650.0,
      },
      {
        'title': '24/7 Emergency Service',
        'description': 'Emergency towing service available 24/7 for urgent cases',
        'icon': Icons.access_time_filled,
        'price': 500.0,
      },
    ];

    final packages = [
      {
        'name': 'Basic Towing Service',
        'price': 199,
        'features': [
          'Vehicle towing up to 20 km',
          'Basic roadside assistance',
          'Battery jump-start assistance',
          'Tire change assistance',
          'Limited emergency fuel supply',
        ],
        'bestValue': false,
      },
      {
        'name': 'Advanced Towing Service',
        'price': 349,
        'features': [
          'All basic package services',
          'Vehicle towing up to 50 km',
          'Quick response within 30 minutes in the city',
          'Off-road vehicle recovery service',
          'Initial technical problem check',
          'Assistance with locked keys inside the vehicle',
        ],
        'bestValue': true,
      },
      {
        'name': 'Comprehensive Towing Service',
        'price': 599,
        'features': [
          'All advanced package services',
          'Vehicle towing up to 100 km',
          'Guaranteed response within 20 minutes',
          'Enclosed transport for luxury vehicles',
          'Advanced fault diagnosis',
          'Minor roadside repair service',
          'Replacement vehicle for 24 hours',
          'Towing service between nearby cities',
        ],
        'bestValue': false,
      },
      {
        'name': 'VIP Transport and Emergency Package',
        'price': 1299,
        'features': [
          'Unlimited distance luxury towing service',
          'Professional enclosed transport for luxury vehicles',
          'Top priority response time (15 minutes)',
          'Intercity transport service regardless of distance',
          'Luxury replacement vehicle for 48 hours',
          '24-hour service with personal account manager',
          'Detailed report on vehicle condition and cause of breakdown',
          'Comprehensive transport insurance during towing',
          'GPS tracking of vehicle location during transport',
          'Annual subscription with 20% discount on all additional towing services',
        ],
        'bestValue': false,
      },
    ];

    // Advanced custom implementation
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Towing and Recovery Services',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.blue),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildTowingBanner(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: const [
                      Tab(text: 'Services'),
                      Tab(text: 'Packages'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Features tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _buildAdvancedFeatureItem(
                    title: feature['title'] as String,
                    description: feature['description'] as String,
                    icon: feature['icon'] as IconData,
                    index: index,
                    price: feature['price'] as double,
                  );
                },
              ),
              
              // Packages tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  final List<String> featuresList = List<String>.from(package['features'] as List);
                  final bool isBestValue = package['bestValue'] as bool;
                  
                  return _buildAdvancedPackageItem(
                    name: package['name'].toString(),
                    price: package['price'] as int,
                    features: featuresList,
                    isBestValue: isBestValue,
                    index: index,
                  );
                },
              ),
            ],
          ),
        ),

      ),
    );
  }

  Widget _buildTowingBanner(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.asset(
                'assets/images/towing_service.png',
                fit: BoxFit.cover,
                width: 180,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_shipping,
                      size: 80,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Towing and Assistance Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '24-hour service - Fast arrival',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () => _bookNow(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      ),
                      child: const Text('Book Now'),
                    ),
                    OutlinedButton(
                      onPressed: () {Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyScreen(),
                ),
              );},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      ),
                      child: const Text('Emergency'),
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

  Widget _buildAdvancedFeatureItem({
    required String title,
    required String description,
    required IconData icon,
    required int index,
    required double price,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showFeatureDetail(title, description, icon, price),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${price.toInt()} EGP',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedPackageItem({
    required String name,
    required int price,
    required List<String> features,
    required bool isBestValue,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isBestValue ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Column(
        children: [
          if (isBestValue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: const Text(
                'Most Popular',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$price EGP',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectPackage(name, price),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Select Package',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showFeatureDetail(String title, String description, IconData icon, double price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.blue, size: 28),
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
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${price.toInt()} EGP',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Additional Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We provide fast and professional service, with a fleet of modern vehicles and equipment for towing and hauling all types of vehicles safely. Our team is trained to the highest levels to ensure your vehicle is transported without any additional damage.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _bookSpecificService(context, title, description, price);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book This Service Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Towing Service Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Towing services include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Towing and hauling of disabled vehicles'),
            Text('• Highway assistance'),
            Text('• Towing from hard-to-reach locations'),
            Text('• Intercity transportation'),
            Text('• 24/7 emergency service'),
            SizedBox(height: 16),
            Text('Our fleet is equipped with the latest equipment for safely transporting your vehicle.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


  void _selectPackage(String packageName, int price) {
    // Calculate tax and total
    final double subtotal = price.toDouble();
    final double tax = subtotal * 0.10; // 10% tax
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    final String customerName = userProvider.user != null 
        ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
        : "Guest";
    final String? customerPhone = userProvider.user?.mobile;
    final String? customerEmail = userProvider.user?.email;
    
    // إنشاء معرف فريد للطلب
    final String orderId = 'TOW-${DateTime.now().millisecondsSinceEpoch}';
    
    // إعداد البيانات الإضافية للخدمة
    final Map<String, dynamic> additionalData = {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'orderId': orderId,
      'serviceType': 'سحب وقطر السيارات',
      'packageName': packageName,
      'orderDate': DateTime.now().toIso8601String(),
      'orderStatus': 'pending',
    };
    
    // Create PaymentSummary
    final PaymentSummary paymentSummary = PaymentSummary(
      subtotal: subtotal,
      tax: tax,
      deliveryFee: 0.0, // لا توجد رسوم توصيل للخدمات
      discount: 0.0,
      total: subtotal + tax,
      currency: 'EGP',
      items: [
        {
          'id': 'towing_${packageName.replaceAll(" ", "_").toLowerCase()}',
          'name': packageName,
          'price': subtotal,
          'quantity': 1,
          'category': 'خدمة',
          'serviceType': 'سحب وقطر السيارات',
          'packageName': packageName,
          'description': 'خدمة سحب وقطر السيارات - باقة $packageName'
        }
      ],
      additionalData: additionalData,
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

  void _bookNow(BuildContext context) {
    _tabController.animateTo(1);
  }

  void _bookSpecificService(BuildContext context, String serviceName, String description, double price) {
    // Get user information from provider
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final String? customerId = userProvider.user?.id;
                      final String customerName = userProvider.user != null 
                          ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
                          : "Guest";
                      final String? customerPhone = userProvider.user?.mobile;
                      final String? customerEmail = userProvider.user?.email;
                      
                      // Create a unique ID for the order
                      final String orderId = 'TWS-${DateTime.now().millisecondsSinceEpoch}';
                      
                      // Prepare additional data for the service
                      final Map<String, dynamic> additionalData = {
                        'customerId': customerId,
                        'customerName': customerName,
                        'customerPhone': customerPhone,
                        'customerEmail': customerEmail,
                        'orderId': orderId,
                        'serviceType': 'Towing Service',
                        'serviceName': serviceName,
                        'packageName': serviceName,
                        'orderDate': DateTime.now().toIso8601String(),
                        'orderStatus': 'pending',
                      };
    // Create a PaymentSummary for the specific service
    final double servicePrice = price;
    final double tax = servicePrice * 0.10; // 10% tax
    
    // Create PaymentSummary
    final PaymentSummary paymentSummary = PaymentSummary(
      subtotal: servicePrice,
      tax: tax,
      discount: 0.0,
      total: servicePrice + tax,
      currency: 'EGP',
      items: [
        {
          'id': 'towing_${serviceName.replaceAll(" ", "_").toLowerCase()}',
          'serviceType': 'Towing Service',
          'name': serviceName,
          'price': servicePrice,
          'quantity': 1,
          'description': description,
          'packageName': serviceName,
          'category': 'Service',
        }
      ],
      additionalData: additionalData,
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
} 