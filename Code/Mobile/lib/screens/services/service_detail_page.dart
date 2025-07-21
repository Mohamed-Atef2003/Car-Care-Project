import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import '../../models/payment_model.dart';
import 'package:provider/provider.dart';
import '../../payment/payment_details_screen.dart';
import '../../providers/user_provider.dart';

class ServiceDetailPage extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Map<String, String>> features;
  final List<Map<String, dynamic>> packages;

  const ServiceDetailPage({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.features,
    required this.packages,
  });

  @override
  _ServiceDetailPageState createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  int _selectedPackageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  // Request service and navigate to payment page
  void _proceedToCheckout() async {
    if (_selectedPackageIndex < 0 || _selectedPackageIndex >= widget.packages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a package first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Build selected maintenance service information
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? customerId = userProvider.user?.id;
    final String customerName = userProvider.user != null 
        ? "${userProvider.user!.firstName} ${userProvider.user!.lastName}" 
        : "Guest";
    final String? customerPhone = userProvider.user?.mobile;
    final String? customerEmail = userProvider.user?.email;
    
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must login to request the service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Create a unique order ID
      final String orderId = 'SERVICE-${DateTime.now().millisecondsSinceEpoch}';
      
      // Build selected package data
      final selectedPackage = widget.packages[_selectedPackageIndex];
      final packageName = selectedPackage['name'] as String;
      final double packagePrice = (selectedPackage['price'] as int).toDouble();
      
      // Calculate tax (15% of package price)
      final double tax = packagePrice * 0.15;
      final double totalAmount = packagePrice + tax;
      
      // Prepare payment summary items
      final List<Map<String, dynamic>> items = [
        {
          'id': '${widget.title.replaceAll(" ", "_").toLowerCase()}_${packageName.replaceAll(" ", "_").toLowerCase()}',
          'name': packageName,
          'price': packagePrice,
          'quantity': 1,
          'category': 'Service',
          'serviceType': widget.title,
          'packageName': packageName,
          'description': '${widget.title} Service - $packageName Package',
        }
      ];
      
      // Prepare additional service data
      final Map<String, dynamic> additionalData = {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'orderId': orderId,
        'serviceType': widget.title,
        'packageName': packageName,
        'orderDate': DateTime.now().toIso8601String(),
        'orderStatus': 'pending',
      };
      
      // Create payment summary object
      final paymentSummary = PaymentSummary(
        subtotal: packagePrice,
        tax: tax,
        deliveryFee: 0.0,
        discount: 0.0,
        total: totalAmount,
        currency: 'EGP',
        items: items,
        additionalData: additionalData,
      );
      
      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service added. Navigating to payment page...'),
          duration: Duration(seconds: 1),
        ),
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
    } catch (e) {
      print('Error while navigating to payment page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: widget.color,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceHeader(),
              const SizedBox(height: 20),
              _buildFeatures(),
              const SizedBox(height: 20),
              _buildPackages(),
              const SizedBox(height: 30),
              _buildRequestButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'We provide high-quality service for your car with quality guarantee',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...widget.features.map((feature) => _buildFeatureItem(
          title: feature['title']!,
          description: feature['description']!,
        )),
      ],
    );
  }

  Widget _buildFeatureItem({required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: widget.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
        ],
      ),
    );
  }

  Widget _buildPackages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.packages.length,
            itemBuilder: (context, index) {
              return _buildPackageCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(int index) {
    final package = widget.packages[index];
    final isSelected = _selectedPackageIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackageIndex = index;
        });
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? widget.color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? widget.color : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${package['price']} EGP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : widget.color,
              ),
            ),
            const SizedBox(height: 15),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (package['features'] as List).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: isSelected ? Colors.white : widget.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white.withOpacity(0.9) : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _proceedToCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Request Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 