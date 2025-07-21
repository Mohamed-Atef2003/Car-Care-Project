import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/car.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final Map<int, bool> _hoveredIndices = {};
  bool _isLoading = true;
  String? _errorMessage;
  List<Customer> _customers = [];
  final Map<String, List<Car>> _customerCars = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('customer_account').get();

      final List<Customer> customers = [];
      for (var doc in querySnapshot.docs) {
        final customer = Customer.fromFirestore(doc.data(), doc.id);
        customers.add(customer);

        // Fetch cars for this customer
        await _fetchCustomerCars(customer.id);
      }

      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error occurred while fetching data: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _fetchCustomerCars(String customerId) async {
    try {
      final carsSnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('customerId', isEqualTo: customerId)
          .get();

      final cars = carsSnapshot.docs.map((doc) {
        return Car.fromFirestore(doc.data(), doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _customerCars[customerId] = cars;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) {
      return _customers;
    }

    final query = _searchQuery.toLowerCase();
    return _customers.where((customer) {
      return customer.firstName.toLowerCase().contains(query) ||
          customer.lastName.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.mobile.toLowerCase().contains(query);
    }).toList();
  }

  void _showCustomerDetails(Customer customer) {
    final customerId = customer.id;
    final customerCars = _customerCars[customerId] ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 24, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Customer Details: ${customer.fullName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('First Name', customer.firstName),
                                const SizedBox(height: 8),
                                _buildInfoRow('Last Name', customer.lastName),
                                const SizedBox(height: 8),
                                _buildInfoRow('Email', customer.email),
                                const SizedBox(height: 8),
                                _buildInfoRow('Phone Number', customer.mobile),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Customer Vehicles',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      customerCars.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No vehicles registered for this customer',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: customerCars.length,
                              itemBuilder: (context, index) {
                                final car = customerCars[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${car.brand} ${car.model} ${car.modelYear}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.blue.withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                car.carNumber,
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow(
                                                      'License Number',
                                                      car.carLicense),
                                                  const SizedBox(height: 4),
                                                  _buildInfoRow(
                                                      'Color', car.color),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow(
                                                      'Engine', car.engine),
                                                  const SizedBox(height: 4),
                                                  _buildInfoRow(
                                                      'Trim', car.trim),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Registration Date: ${DateFormat('yyyy-MM-dd').format(car.createdAt)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Customer customer, int index) {
    final isHovered = _hoveredIndices[index] ?? false;
    final customerId = customer.id;
    final customerCars = _customerCars[customerId] ?? [];

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndices[index] = true),
      onExit: (_) => setState(() => _hoveredIndices[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? Colors.blue.withAlpha(40)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                isHovered ? Colors.blue.withAlpha(100) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showCustomerDetails(customer),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.withAlpha(30),
                      child: Text(
                        customer.firstName.isNotEmpty
                            ? customer.firstName[0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            customer.email,
                            style: TextStyle(
                              color: Colors.grey[600],
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
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${customerCars.length} cars',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      customer.mobile,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (customerCars.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Vehicles:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customerCars.take(3).map((car) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          car.displayName,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Customer Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search for customer...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading data',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _fetchCustomers,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filteredCustomers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_alt_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No customers found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  return _buildCustomerCard(
                                      _filteredCustomers[index], index);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchCustomers,
        tooltip: 'Refresh Customers',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
