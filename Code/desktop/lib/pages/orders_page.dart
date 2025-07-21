import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/customer_order.dart';
import '../dialogs/order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<CustomerOrder> _filteredOrders = [];
  List<CustomerOrder> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, bool> _hoveredIndices = {};
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // New state variables for UI improvements
  bool _isGridView = false;
  String _statusFilter = 'All';
  String _sortBy = 'Date (Newest)';
  
  final List<String> _statusOptions = ['All', 'Rejected', 'Pending', 'Processing', 'Accepted', 'Completed'];
  final List<String> _sortOptions = ['Date (Newest)', 'Date (Oldest)', 'Amount (High to Low)', 'Amount (Low to High)'];

  @override
  void initState() {
    super.initState();
    _filteredOrders = [];
    _searchController.addListener(_filterOrders);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('orders').get();
      
      print('Retrieved ${querySnapshot.docs.length} orders from Firestore');
      
      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Store document ID in custom field
        data['id'] = doc.id;
        print('Document ID: ${doc.id}, orderId: ${data['orderId']}');
        return CustomerOrder.fromFirestore(data);
      }).toList();
      
      setState(() {
        _orders = orders;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch orders: ${e.toString()}';
      });
      print('Error fetching orders: $e');
    }
  }

  void _filterOrders() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    final query = _searchController.text.toLowerCase();
    
    // First apply text search filter
    var filtered = _orders.where((order) {
        return order.userName.toLowerCase().contains(query) ||
            order.emailAddress.toLowerCase().contains(query) ||
            order.phoneNumber.contains(query) ||
            order.orderType.toLowerCase().contains(query) ||
            order.serviceType.toLowerCase().contains(query) ||
            order.status.toLowerCase().contains(query);
      }).toList();
    
    // Then apply status filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((order) => 
        order.status.toLowerCase() == _statusFilter.toLowerCase()
      ).toList();
    }
    
    // Finally apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Amount (High to Low)':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount (Low to High)':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    
    setState(() {
      _filteredOrders = filtered;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(CustomerOrder order) async {
    // Print debug information
    print('Showing order details:');
    print('Document ID: ${order.documentId}');
    print('Order ID: ${order.orderId}');
    
    final result = await showDialog(
      context: context,
      builder: (context) => OrderDetailsPage(
        orderDetails: {
          'orderId': order.orderId,
          'customerName': order.userName,
          'email': order.emailAddress,
          'phoneNumber': order.phoneNumber,
          'address': order.address,
          'orderCost': order.amount.toString(),
          'currency': order.currency,
          'service': order.serviceType,
          'packageName': order.packageName,
          'orderType': order.orderType,
          'paymentMethod': order.paymentMethod,
          'paymentStatus': order.paymentStatus,
          'status': order.status,
          'createdAt': order.createdAt.toString(),
          'documentId': order.documentId,
          'serviceFeatures': order.serviceFeatures,
          'packageFeatures': order.packageFeatures,
          'description': order.description,
          'notes': order.notes,
          'deliveryNotes': order.deliveryNotes,
          'items': order.items,
        },
      ),
    );

    if (result != null) {
      try {
        // Extract data from result (now a Map object)
        final String newStatus = result['status'];
        String docId = result['documentId'] ?? '';
        
        // Check if we have a valid document ID
        if (docId.isEmpty) {
          docId = order.documentId; // Use original document ID if not available
        }
        
        // Verify document ID exists before attempting update
        if (docId.isEmpty) {
          throw Exception('Document ID is empty, cannot update order');
        }
        
        print('Updating document with ID: $docId');
        print('Updating status to: $newStatus');
        
        // Execute update on Firestore
        final docRef = FirebaseFirestore.instance.collection('orders').doc(docId);
        
        // Check if document exists first
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          throw Exception('Document does not exist in Firestore with ID: $docId');
        }
        
        // Update status and timestamp
        await docRef.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status successfully updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh order list
        _fetchOrders();
      } catch (e) {
        print('Error updating order: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Try to add document if it doesn't exist
        if (e.toString().contains('not-found') || e.toString().contains('does not exist')) {
          // Extract new status from result
          final String newStatus = result['status'];
          _tryCreateDocument(order, newStatus);
        }
      }
    }
  }
  
  // New function to try creating the document if it doesn't exist
  Future<void> _tryCreateDocument(CustomerOrder order, String newStatus) async {
    try {
      // Use orderId as document ID if documentId is empty
      final docId = order.documentId.isNotEmpty ? order.documentId : order.orderId;
      print('Attempting to create new document with ID: $docId');
      
      // Create document data
      final Map<String, dynamic> data = {
        'orderId': order.orderId,
        'customerName': order.userName,
        'customerEmail': order.emailAddress,
        'customerPhone': order.phoneNumber,
        'deliveryAddress': order.address,
        'amount': order.amount,
        'currency': order.currency,
        'serviceType': order.serviceType,
        'packageName': order.packageName,
        'orderType': order.orderType,
        'paymentMethod': order.paymentMethod,
        'paymentStatus': order.paymentStatus,
        'status': newStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if available
      if (order.serviceFeatures != null) {
        data['serviceFeatures'] = order.serviceFeatures as List<dynamic>;
      }
      
      if (order.packageFeatures != null) {
        data['packageFeatures'] = order.packageFeatures as List<dynamic>;
      }
      
      if (order.description != null) {
        data['description'] = order.description as String;
      }
      
      if (order.notes != null) {
        data['notes'] = order.notes as String;
      }
      
      if (order.deliveryNotes != null) {
        data['deliveryNotes'] = order.deliveryNotes as String;
      }
      
      if (order.deliveryLocation != null) {
        data['deliveryLocation'] = order.deliveryLocation as Map<String, dynamic>;
      }
      
      if (order.items != null) {
        data['items'] = order.items as List<dynamic>;
      }
      
      // Create document in Firestore
      await FirebaseFirestore.instance.collection('orders').doc(docId).set(data);
      
      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New order created and status set successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh orders list
      _fetchOrders();
    } catch (e) {
      print('Failed to create new order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create new order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderRow(CustomerOrder order, int index) {
    final isHovered = _hoveredIndices[index] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndices[index] = true),
      onExit: (_) => setState(() => _hoveredIndices[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isHovered ? Colors.grey[50] : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showOrderDetails(order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                      order.userName,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: isHovered ? FontWeight.w500 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${order.amount} ${order.currency}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      order.orderType == 'product' ? 'Product' : order.serviceType,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      order.orderType == 'product' ? 
                         (order.items != null && order.items!.isNotEmpty ? 
                           order.items![0]['name'] ?? order.packageName : order.packageName) : 
                         order.packageName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        order.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Actions
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.blue,
                      tooltip: 'Edit Order',
                      onPressed: () => _showOrderDetails(order),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get product name for display
            String displayServiceType = order.orderType == 'product' ? 'Product' : order.serviceType;
            String displayPackageName = order.packageName;
            if (order.orderType == 'product' && order.items != null && order.items!.isNotEmpty) {
              displayPackageName = order.items![0]['name'] ?? order.packageName;
            }
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM dd, yyyy').format(order.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      order.emailAddress,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.attach_money,
                            'Amount',
                            '${order.amount} ${order.currency}',
                          ),
                        ),
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.home_repair_service_outlined,
                            'Service',
                            displayServiceType,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.inventory_2_outlined,
                            'Package',
                            displayPackageName,
                          ),
                        ),
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.payment_outlined,
                            'Method',
                            order.paymentMethod,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showOrderDetails(order),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildCompactInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // View toggle
          ToggleButtons(
            isSelected: [!_isGridView, _isGridView],
            onPressed: (index) {
              setState(() {
                _isGridView = index == 1;
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: Colors.black,
            color: Colors.grey[700],
            constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
            children: const [
              Icon(Icons.table_rows),
              Icon(Icons.grid_view),
            ],
          ),
          const SizedBox(width: 16),
          
          // Status filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _statusFilter,
              icon: const Icon(Icons.expand_more),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _statusFilter = newValue;
                    _applyFiltersAndSort();
                  });
                }
              },
              items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: value == 'All'
                                ? Colors.blue
                                : _getStatusColor(value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 16),
          
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.expand_more),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _sortBy = newValue;
                    _applyFiltersAndSort();
                  });
                }
              },
              items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          value.contains('Date') 
                              ? Icons.calendar_today_outlined 
                              : Icons.attach_money,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Spacer(),
          
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_filteredOrders.length} Orders',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing filters or check back later',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Manage Customer Orders',
                        style: TextStyle(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 300,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search orders...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildIconButton(Icons.refresh, () => _fetchOrders(), 'Refresh'),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterBar(),
              const SizedBox(height: 20),
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
                                  'Error loading orders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _fetchOrders,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filteredOrders.isEmpty
                            ? _buildEmptyState()
                            : _isGridView
                                ? GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 1.3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: _filteredOrders.length,
                                    padding: const EdgeInsets.all(8),
                                    itemBuilder: (context, index) {
                                      return _buildOrderCard(_filteredOrders[index]);
                                    },
                                  )
                                : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 30),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Customer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Service',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Package',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 40), // For the action button
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderRow(_filteredOrders[index], index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
          onTap: onTap,
        child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(icon, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }
}
