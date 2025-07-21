import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import 'package:provider/provider.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/user_provider.dart';

class KeyProgrammingServicePage extends StatefulWidget {
  const KeyProgrammingServicePage({super.key});

  @override
  State<KeyProgrammingServicePage> createState() => _KeyProgrammingServicePageState();
}

class _KeyProgrammingServicePageState extends State<KeyProgrammingServicePage> with SingleTickerProviderStateMixin {
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
        'title': 'Car Key Programming',
        'description': 'Programming modern car keys using the latest specialized programming devices',
        'icon': Icons.vpn_key,
        'price': 280.0,
      },
      {
        'title': 'Key Copying and Duplication',
        'description': 'Copying and duplicating car keys with high precision and full compatibility',
        'icon': Icons.content_copy,
        'price': 150.0,
      },
      {
        'title': 'Remote Control Repair',
        'description': 'Repair and maintenance of remote controls including battery replacement and damaged parts',
        'icon': Icons.settings_remote,
        'price': 120.0,
      },
      {
        'title': 'Locked Car Opening',
        'description': 'Emergency service to open locked cars professionally without damage',
        'icon': Icons.lock_open,
        'price': 180.0,
      },
      {
        'title': 'Anti-Theft System Programming',
        'description': 'Programming and adjusting car alarm and anti-theft systems',
        'icon': Icons.security,
        'price': 250.0,
      },
      {
        'title': 'Car Lock Repair',
        'description': 'Maintenance and repair of mechanical and electronic car locks',
        'icon': Icons.build,
        'price': 200.0,
      },
      {
        'title': 'Mercedes & BMW Key Programming',
        'description': 'Specialized service for programming luxury and European car keys',
        'icon': Icons.star,
        'price': 350.0,
      },
    ];

    final packages = [
      {
        'name': 'Basic Key Service',
        'price': 149,
        'features': [
          'Non-chip key copying',
          'Remote battery replacement',
          'Remote button cleaning & maintenance',
          'Basic lock system inspection',
          'Emergency car opening',
        ],
        'bestValue': false,
      },
      {
        'name': 'Advanced Key Service',
        'price': 299,
        'features': [
          'Transponder chip key copying',
          'New smart key programming',
          'Remote control repair',
          'Comprehensive car lock system inspection',
          'Key shell replacement',
          'Memory key programming for modern cars',
        ],
        'bestValue': true,
      },
      {
        'name': 'Professional Key Service',
        'price': 499,
        'features': [
          'Luxury car key programming',
          'Main control unit replacement & programming',
          'Keyless Entry system repair',
          'Alarm & anti-theft system reprogramming',
          'Custom key feature programming',
          'Door lock maintenance & repair',
          '24-hour emergency service',
          'One-year warranty on programming & repairs',
        ],
        'bestValue': false,
      },
      {
        'name': 'Luxury Car Package',
        'price': 899,
        'features': [
          'Specialized programming for luxury & sports cars',
          'Full feature smart key replacement',
          'Advanced security system programming',
          'ECU control unit repair',
          'Multiple backup key programming',
          'Immediate on-site home or location service',
          'Custom programming for advanced functions',
          'Car data & security code protection',
          'Two-year comprehensive warranty',
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
            'Key Programming',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.amber),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildKeyBanner(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.amber,
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

  Widget _buildKeyBanner(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
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
                'assets/images/key_programming.png',
                fit: BoxFit.cover,
                width: 180,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.vpn_key,
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
                  Icons.vpn_key,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Key Programming and Manufacturing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Advanced Programming and Emergency Services',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
               

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
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${price.toInt()} EGP',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        border: isBestValue ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Column(
        children: [
          if (isBestValue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.amber,
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
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$price EGP',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                        color: Colors.amber,
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
                      backgroundColor: Colors.amber,
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
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.amber, size: 28),
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
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${price.toInt()} EGP',
                              style: const TextStyle(
                                color: Colors.amber,
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
                  'This service is performed using the latest programming and diagnostic equipment. Our team of technicians is certified by global companies for key programming. We guarantee quality and security with a warranty on all services.',
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
                      
                      // Get user information from provider
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final String? customerId = userProvider.user?.id;
                      final String customerName = userProvider.user != null 
                          ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
                          : "Guest";
                      final String? customerPhone = userProvider.user?.mobile;
                      final String? customerEmail = userProvider.user?.email;
                      
                      // Create a unique ID for the order
                      final String orderId = 'KEY-${DateTime.now().millisecondsSinceEpoch}';
                      
                      // Prepare additional data for the service
                      final Map<String, dynamic> additionalData = {
                        'customerId': customerId,
                        'customerName': customerName,
                        'customerPhone': customerPhone,
                        'customerEmail': customerEmail,
                        'orderId': orderId,
                        'serviceType': 'Key Programming',
                        'serviceName': title,
                        'packageName': title,
                        'orderDate': DateTime.now().toIso8601String(),
                        'orderStatus': 'pending',
                      };
                      
                      // Create a PaymentSummary for this specific service
                      final PaymentSummary paymentSummary = PaymentSummary(
                        subtotal: price,
                        tax: price * 0.10,        // 10% tax
                        discount: 0.0,
                        total: price + (price * 0.10),     // subtotal + tax
                        currency: 'EGP',
                        items: [
                          {
                            'id': 'key_programming_${title.replaceAll(" ", "_").toLowerCase()}',
                            'category': 'Service',
                            'serviceType': 'Key Programming',
                            'packageName': title,
                            'name': title, // Use the selected service title
                            'price': price,
                            'quantity': 1,
                            'description': description, // Include the description
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
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
        title: const Text('Key Programming Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key programming services include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Programming modern car keys'),
            Text('• Copying keys and remote controls'),
            Text('• Remote control repair and maintenance'),
            Text('• Opening locked cars'),
            Text('• 24-hour emergency services'),
            SizedBox(height: 16),
            Text('We provide specialized services for all types of cars including luxury vehicles.'),
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
    // Create a PaymentSummary for the selected package
    final double subtotal = price.toDouble();
    final double tax = subtotal * 0.10; // 10% tax
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    final String customerName = userProvider.user != null 
        ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
        : "Guest";
    final String? customerPhone = userProvider.user?.mobile;
    final String? customerEmail = userProvider.user?.email;
    
    // Create a unique ID for the order
    final String orderId = 'KEY-${DateTime.now().millisecondsSinceEpoch}';
    
    // Prepare additional data for the service
    final Map<String, dynamic> additionalData = {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'orderId': orderId,
      'serviceType': 'Key Programming',
      'packageName': packageName,
      'orderDate': DateTime.now().toIso8601String(),
      'orderStatus': 'pending',
    };
    
    final PaymentSummary paymentSummary = PaymentSummary(
      subtotal: subtotal,
      tax: tax,
      deliveryFee: 0.0, // No delivery fee for services
      discount: 0.0,
      total: subtotal + tax,
      currency: 'EGP',
      items: [
        {
          'id': 'key_programming_${packageName.replaceAll(" ", "_").toLowerCase()}',
          'name': packageName,
          'price': subtotal,
          'quantity': 1,
          'category': 'Service',
          'serviceType': 'Key Programming',
          'packageName': packageName,
          'description': 'Key Programming Service - Package $packageName'
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