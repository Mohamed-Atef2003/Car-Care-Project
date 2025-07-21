import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserOrders();
  }

  Future<void> _fetchUserOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null || user.id == null || user.id!.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view previous orders';
        });
        print('User not logged in: ${user?.id}');
        return;
      }

      print('Searching for orders for user: ${user.id}');
      
      // Search in both orders and emergency collections
      final List<String> collectionsToSearch = ['orders', 'emergency'];
      
      List<Map<String, dynamic>> allOrders = [];
      
      // Check both collections
      for (final String collectionName in collectionsToSearch) {
        try {
          print('Checking collection: $collectionName');
          
          // Attempt to get documents with as many possible user identifier fields as possible
          final List<QuerySnapshot> queryResults = await Future.wait([
            // 1. Search using customerId
            FirebaseFirestore.instance
                .collection(collectionName)
                .where('customerId', isEqualTo: user.id)
                .get(),
                
            // 2. Search using userId
            FirebaseFirestore.instance
                .collection(collectionName)
                .where('userId', isEqualTo: user.id)
                .get(),
                
            // 3. Search using customer.id
            FirebaseFirestore.instance
                .collection(collectionName)
                .where('customer.id', isEqualTo: user.id)
                .get(),
                
            // 4. Search using user.id
            FirebaseFirestore.instance
                .collection(collectionName)
                .where('user.id', isEqualTo: user.id)
                .get(),
                
            // 5. Search using id
            FirebaseFirestore.instance
                .collection(collectionName)
                .where('id', isEqualTo: user.id)
                .get(),
                
            // 6. Search using uid
            FirebaseFirestore.instance
                .collection(collectionName)
                .where('uid', isEqualTo: user.id)
                .get(),
          ]);
          
          // Collect all unique documents from all query results
          Set<String> processedIds = {};
          for (final querySnapshot in queryResults) {
            if (querySnapshot.docs.isNotEmpty) {
              print('Found ${querySnapshot.docs.length} documents in $collectionName');
              
              for (final doc in querySnapshot.docs) {
                // Avoid processing the same document twice
                if (!processedIds.contains(doc.id)) {
                  processedIds.add(doc.id);
                  
                  final data = doc.data() as Map<String, dynamic>;
                  _processOrderData(allOrders, doc.id, data, collectionName);
                }
              }
            }
          }
        } catch (e) {
          print('Error checking collection $collectionName: $e');
        }
      }
      
      // Sort orders by date (newest first)
      allOrders.sort((a, b) {
        // Here we assume the date is available as a comparable text
        // But any other field can be used for sorting (like amountValue or createdAtTimestamp)
        final dateA = a['createdAtTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        final dateB = b['createdAtTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        return (dateB as num).compareTo(dateA as num);
      });

      if (!mounted) return;
      setState(() {
        _orders = allOrders;
        _isLoading = false;
      });
      
      if (allOrders.isEmpty) {
        print('No orders found for user ${user.id}');
        _errorMessage = 'No orders found. Please create a new order.';
      } else {
        print('Found ${allOrders.length} orders for user');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching orders: $e';
      });
    }
  }

  // Process order data - improved version that accepts any data type
  void _processOrderData(List<Map<String, dynamic>> ordersList, String docId, Map<String, dynamic> data, String sourceCollection) {
    try {
      // Format date
      String formattedDate = 'Not available';
      DateTime? orderDate;
      int createdAtTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Try to find the date field (check all possible fields)
      final List<String> dateFields = [
        'createdAt', 'orderDate', 'date', 'timestamp', 'created_at', 
        'updatedAt', 'updated_at', 'placedAt', 'processedAt', 'requestDate',
        'appointmentDate', 'transactionDate', 'requestTime'
      ];
      
      for (var field in dateFields) {
        if (data[field] != null) {
          if (data[field] is Timestamp) {
            orderDate = (data[field] as Timestamp).toDate();
            createdAtTimestamp = orderDate.millisecondsSinceEpoch;
            break;
          } else if (data[field] is DateTime) {
            orderDate = data[field] as DateTime;
            createdAtTimestamp = orderDate.millisecondsSinceEpoch;
            break;
          } else if (data[field] is String) {
            try {
              orderDate = DateTime.parse(data[field]);
              createdAtTimestamp = orderDate.millisecondsSinceEpoch;
              break;
            } catch (_) {}
          } else if (data[field] is int) {
            try {
              orderDate = DateTime.fromMillisecondsSinceEpoch(data[field]);
              createdAtTimestamp = data[field];
              break;
            } catch (_) {}
          } else if (data[field] is Map) {
            try {
              final secondsValue = (data[field] as Map)['seconds'];
              if (secondsValue != null && secondsValue is int) {
                orderDate = DateTime.fromMillisecondsSinceEpoch(secondsValue * 1000);
                createdAtTimestamp = secondsValue * 1000;
                break;
              }
            } catch (_) {}
          }
        }
      }
      
      // If we didn't find a date, use the current time
      orderDate ??= DateTime.now();
      
      try {
        formattedDate = DateFormat('dd MMMM yyyy', 'en_US').format(orderDate);
      } catch (e) {
        try {
          formattedDate = DateFormat('dd/MM/yyyy').format(orderDate);
        } catch (e2) {
          formattedDate = orderDate.toString().split(' ')[0];
        }
      }

      // Handle order type (service, product, or other type)
      String orderType = '';
      bool isServiceOrder = false;
      String serviceName = 'Order';
      String price = 'Not available';
      Map<String, dynamic> orderData = {};
      
      // For emergency orders, handle the service data differently
      if (sourceCollection == 'emergency') {
        orderType = 'Emergency Service';
        isServiceOrder = true;
        
        // Extract service details from the service map
        if (data['service'] != null && data['service'] is Map) {
          final serviceData = data['service'] as Map;
          serviceName = serviceData['title'] ?? 'Emergency Service';
          
          // Handle cost range
          if (serviceData['cost'] != null) {
            price = serviceData['cost'].toString();
          }
          
          // Add ETA if available
          if (serviceData['eta'] != null) {
            orderData['eta'] = serviceData['eta'];
          }
          
          // Add urgent flag
          if (serviceData['urgent'] != null) {
            orderData['isUrgent'] = serviceData['urgent'];
          }
        }
      } else {
        // Existing code for non-emergency orders
        if (data['orderType'] != null) {
          orderType = data['orderType'].toString();
          isServiceOrder = orderType.toLowerCase() == 'service';
        } else if (sourceCollection.toLowerCase().contains('appointment')) {
          orderType = 'service';
          isServiceOrder = true;
        } else if (data['type'] != null) {
          orderType = data['type'].toString();
          isServiceOrder = orderType.toLowerCase() == 'service';
        } else if (data['serviceType'] != null || data['service'] != null) {
          orderType = 'service';
          isServiceOrder = true;
        } else if (data['items'] != null || data['products'] != null) {
          orderType = 'product';
          isServiceOrder = false;
        }
      }

      // Extract service name or use a default
      if (isServiceOrder) {
        // If service order, use service name or package
        for (final field in ['serviceType', 'service', 'serviceName', 'appointmentType', 'packageName']) {
          if (data[field] != null && data[field].toString() != 'null') {
            if (data[field] is Map) {
              final serviceMap = data[field] as Map;
              serviceName = serviceMap['title'] ?? serviceMap['name'] ?? 'Service';
            } else {
              serviceName = data[field].toString();
            }
            break;
          }
        }
      } else {
        // Existing code for product orders
        List? items;
        
        for (final field in ['items', 'products', 'orderItems', 'cart', 'cartItems']) {
          if (data[field] != null && data[field] is List && (data[field] as List).isNotEmpty) {
            items = data[field] as List;
            break;
          }
        }
        
        if (items != null && items.isNotEmpty) {
          if (items.length == 1) {
            final item = items[0];
            if (item is Map) {
              for (final field in ['name', 'title', 'productName', 'label', 'description']) {
                if (item[field] != null) {
                  serviceName = item[field].toString();
                  break;
                }
              }
            } else if (item is String) {
              serviceName = item;
            }
          } else {
            serviceName = 'Multiple Products (${items.length})';
          }
        }
      }

      // Format order status - improved version supporting more statuses
      String status = 'Processing';
      String? rawStatus;
      
      // Search for status field in many possible fields
      for (final field in ['status', 'orderStatus', 'state', 'appointmentStatus', 'transactionStatus']) {
        if (data[field] != null) {
          rawStatus = data[field].toString().toLowerCase();
          break;
        }
      }
      
      if (rawStatus != null) {
        if (sourceCollection == 'emergency') {
          // Handle emergency order statuses
          final Map<String, String> emergencyStatusMap = {
            'pending': 'Pending',
            'Pending': 'Pending',
            'in progress': 'In Progress',
            'in_progress': 'In Progress',
            'resolved': 'Resolved',
            'Resolved': 'Resolved',
            'cancelled': 'Cancelled',
            'Cancelled': 'Cancelled',
          };
          
          if (emergencyStatusMap.containsKey(rawStatus)) {
            status = emergencyStatusMap[rawStatus]!;
          } else {
            status = 'Pending';
          }
        } else {
          // Handle regular order statuses
          final Map<String, String> statusMap = {
            'pending': 'Pending',
            'accepted': 'Accepted',
            'rejected': 'Rejected',
            'processing': 'Processing',
            'completed': 'Completed',
          };
          
          if (statusMap.containsKey(rawStatus)) {
            status = statusMap[rawStatus]!;
          } else {
            status = 'Pending';
          }
        }
      }
      
      // Handle amount and currency
      double amount = 0;
      
      // For emergency orders, handle cost differently
      if (sourceCollection == 'emergency' && data['service'] != null && data['service'] is Map) {
        final serviceData = data['service'] as Map;
        if (serviceData['cost'] != null) {
          price = serviceData['cost'].toString();
          // Try to extract numeric value from cost range
          String costText = serviceData['cost'].toString();
          if (costText.contains('-')) {
            costText = costText.split('-')[0].trim();
          }
          amount = _extractNumericValue(costText);
        }
      } else {
        // Existing code for non-emergency orders
        final List<String> amountFields = [
          'amount', 'cost', 'total', 'price', 'totalAmount', 'totalPrice',
          'fee', 'fees', 'charge', 'payment', 'paid', 'amountPaid', 'grandTotal'
        ];
        
        for (final field in amountFields) {
          if (data[field] != null) {
            amount = _extractNumericValue(data[field]);
            if (amount > 0) break;
          }
        }
      }
      
      // Find currency in all possible fields
      String currency = 'EGP';
      
      for (final field in ['currency', 'currencyCode', 'currencySymbol']) {
        if (data[field] != null && data[field].toString().trim().isNotEmpty) {
          currency = data[field].toString().trim();
          break;
        }
      }
      
      if (amount > 0) {
        price = '${amount.toStringAsFixed(2)} $currency';
      }
      
      // Payment method
      String paymentMethod = 'Not specified';
      
      // For emergency orders, payment method might be different
      if (sourceCollection == 'emergency') {
        paymentMethod = 'Cash on Delivery'; // Default for emergency services
      } else {
        // Existing code for non-emergency orders
        for (final field in ['paymentMethod', 'payment_method', 'method', 'paymentType', 'payment']) {
          if (data[field] != null) {
            String method = data[field].toString();
            
            final Map<String, String> paymentMethods = {
              'cash on delivery': 'Cash on Delivery',
              'cash_on_delivery': 'Cash on Delivery',
              'cod': 'Cash on Delivery',
              'credit card': 'Credit Card',
              'creditcard': 'Credit Card',
              'credit_card': 'Credit Card',
              'visa': 'Visa',
              'mastercard': 'Mastercard',
              'debit card': 'Debit Card',
              'paypal': 'PayPal',
              'bank transfer': 'Bank Transfer',
              'wire transfer': 'Wire Transfer',
              'ewallet': 'E-Wallet',
              'e-wallet': 'E-Wallet',
              'wallet': 'E-Wallet',
            };
            
            for (final entry in paymentMethods.entries) {
              if (method.toLowerCase().contains(entry.key)) {
                paymentMethod = entry.value;
                break;
              }
            }
            
            if (paymentMethod == 'Not specified') {
              paymentMethod = method;
            }
            
            break;
          }
        }
      }
      
      // Payment status
      String paymentStatus = 'Unknown';
      
      // For emergency orders, payment status might be different
      if (sourceCollection == 'emergency') {
        paymentStatus = 'Pending'; // Default for emergency services
      } else {
        // Existing code for non-emergency orders
        for (final field in ['paymentStatus', 'payment_status', 'isPaid', 'paid']) {
          if (data[field] != null) {
            final value = data[field].toString().toLowerCase();
            
            if (value == 'pending' || value == 'false' || value == '0' || value == 'no') {
              paymentStatus = 'Awaiting Payment';
              break;
            } else if (value == 'paid' || value == 'true' || value == '1' || value == 'yes' || value == 'completed') {
              paymentStatus = 'Paid';
              break;
            } else if (value == 'failed' || value == 'error' || value == 'declined' || value == 'rejected') {
              paymentStatus = 'Payment Failed';
              break;
            } else if (value == 'refunded' || value == 'returned') {
              paymentStatus = 'Refunded';
              break;
            } else if (value == 'partially_paid') {
              paymentStatus = 'Partially Paid';
              break;
            } else {
              paymentStatus = value;
              break;
            }
          }
        }
      }

      // Extract customer's car (if available)
      String carModel = 'Not available';
      
      // For emergency orders, handle vehicle data differently
      if (sourceCollection == 'emergency' && data['vehicle'] != null && data['vehicle'] is Map) {
        final vehicleData = data['vehicle'] as Map;
        String brand = vehicleData['brand'] ?? '';
        String model = vehicleData['model'] ?? '';
        String year = vehicleData['modelYear']?.toString() ?? '';
        String license = vehicleData['carLicense'] ?? '';
        String number = vehicleData['carNumber'] ?? '';
        
        carModel = '$brand $model ${year.isNotEmpty ? '($year)' : ''}';
        if (license.isNotEmpty) carModel += ' - License: $license';
        if (number.isNotEmpty) carModel += ' - Number: $number';
      } else {
        // Existing code for non-emergency orders
        for (final field in ['carModel', 'car', 'vehicleModel', 'vehicle', 'carInfo', 'vehicleInfo']) {
          if (data[field] != null) {
            if (data[field] is String) {
              carModel = data[field];
              break;
            } else if (data[field] is Map) {
              final carData = data[field] as Map;
              for (final subField in ['model', 'name', 'brand', 'make', 'modelName', 'title', 'description']) {
                if (carData[subField] != null) {
                  carModel = carData[subField].toString();
                  break;
                }
              }
              break;
            }
          }
        }
      }
      
      // Extract order ID
      String? orderId;
      for (final field in ['orderId', 'orderNumber', 'referenceCode', 'reference', 'appointmentId', 'transactionId', 'id']) {
        if (data[field] != null && data[field].toString().trim().isNotEmpty) {
          orderId = data[field].toString().trim();
          break;
        }
      }

      // Add to orders list
      orderData = {
        'id': docId,
        'docId': docId,
        'date': formattedDate,
        'service': serviceName,
        'status': status,
        'price': price,
        'carModel': carModel,
        'orderId': orderId,
        'orderType': orderType,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'isServiceOrder': isServiceOrder,
        'sourceCollection': sourceCollection,
        'createdAtTimestamp': createdAtTimestamp,
        'fullData': data,
      };
      
      // Add customer details if available
      _extractCustomerDetails(orderData, data);
      
      // Add amount data
      orderData['amountValue'] = amount;
      orderData['amountCurrency'] = currency;

      // Add delivery details
      _extractDeliveryDetails(orderData, data);

      // Add emergency-specific data
      if (sourceCollection == 'emergency') {
        if (data['location'] != null) {
          orderData['deliveryAddress'] = data['location'];
        }
        if (data['notes'] != null) {
          orderData['deliveryNotes'] = data['notes'];
        }
        if (data['service'] != null && data['service'] is Map) {
          final serviceData = data['service'] as Map;
          if (serviceData['eta'] != null) {
            orderData['eta'] = serviceData['eta'];
          }
          if (serviceData['urgent'] != null) {
            orderData['isUrgent'] = serviceData['urgent'];
          }
        }
      }

      ordersList.add(orderData);
    } catch (e) {
      print('Error processing order data: $e');
    }
  }
  
  // Extract customer details
  void _extractCustomerDetails(Map<String, dynamic> orderData, Map<String, dynamic> data) {
    // Search for customer information in all possible fields
    for (String field in ['customer', 'user', 'client', 'buyer']) {
      if (data[field] != null && data[field] is Map) {
        final customerData = data[field] as Map;
        
        if (customerData['name'] != null) {
          orderData['customerName'] = customerData['name'];
        }
        if (customerData['phone'] != null) {
          orderData['customerPhone'] = customerData['phone'];
        }
        if (customerData['email'] != null) {
          orderData['customerEmail'] = customerData['email'];
        }
        
        // If we found customer data, stop searching
        if (orderData.containsKey('customerName')) break;
      }
    }
    
    // If we didn't find customer data in a dedicated object, search for individual fields
    if (!orderData.containsKey('customerName')) {
      for (String prefix in ['customer', 'user', 'client', 'buyer', '']) {
        String nameField = prefix.isEmpty ? 'name' : '${prefix}Name';
        String phoneField = prefix.isEmpty ? 'phone' : '${prefix}Phone';
        String emailField = prefix.isEmpty ? 'email' : '${prefix}Email';
        
        if (data[nameField] != null) {
          orderData['customerName'] = data[nameField];
        }
        if (data[phoneField] != null) {
          orderData['customerPhone'] = data[phoneField];
        }
        if (data[emailField] != null) {
          orderData['customerEmail'] = data[emailField];
        }
        
        // If we found the customer name, stop searching
        if (orderData.containsKey('customerName')) break;
      }
    }
  }
  
  // Extract delivery details
  void _extractDeliveryDetails(Map<String, dynamic> orderData, Map<String, dynamic> data) {
    // Search for delivery information in all possible fields
    
    // ...
    
  }

  // Format price function for better price display
  String _formatPrice(Map<String, dynamic> order) {
    // If we have amount and currency values, use them
    if (order['amountValue'] != null && order['amountValue'] > 0) {
      return '${order['amountValue'].toStringAsFixed(2)} ${order['amountCurrency'] ?? 'EGP'}';
    }
    
    // Otherwise, use the pre-formatted price value
    return order['price'];
  }

  // Order status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Resolved':
        return Colors.green;
      case 'Processing':
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
        return Colors.blue;
      case 'Accepted':
        return Colors.teal;
      case 'Rejected':
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage ?? 'No previous orders',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchUserOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUserOrders,
                  child: ListView.builder(
                    itemCount: _orders.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_orders[index]);
                    },
                  ),
                ),
      
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Check if this is an emergency order
    bool isEmergencyOrder = order['sourceCollection'] == 'emergency';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order['orderId'] != null ? 'Order #${order['orderId']}' : 'Order #${order['id'].toString().substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: _getStatusColor(order['status']),
                  child: Text(
                    order['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date: ${order['date']}'),
            
            // Show Emergency Order label if applicable
            if (isEmergencyOrder)
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Emergency Order',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            
            // Order type or service
            order['isServiceOrder'] == true 
                ? Text('Service Type: ${order['service']}')
                : Text('Product: ${order['service']}'),
            
            // Show car only if available and different from default value
            if (order['carModel'] != null && order['carModel'] != 'Not available')
              Text('Vehicle: ${order['carModel']}'),
            
            // Amount and payment method
            Text('Amount: ${_formatPrice(order)}'),
            
            // Add payment method 
            if (order['paymentMethod'] != null && order['paymentMethod'] != 'Not specified')
              Text('Payment Method: ${order['paymentMethod']}'),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final fullData = order['fullData'];
    final bool isServiceOrder = order['isServiceOrder'] ?? false;
    final bool isEmergencyOrder = order['sourceCollection'] == 'emergency';
    List? items;
    
    if (isServiceOrder) {
      // If service order, create a default item
      items = [
        {
          'name': fullData['serviceType'] ?? order['service'],
          'price': order['amountValue'] ?? _extractPriceValue(order['price']),
          'currency': fullData['currency'] ?? 'EGP',
          'quantity': 1,
          'packageName': fullData['packageName'],
        }
      ];
    } else {
      // Try to get items for products
      items = fullData['items'] as List?;
      
      if (items == null || items.isEmpty) {
        if (fullData['products'] != null && fullData['products'] is List && (fullData['products'] as List).isNotEmpty) {
          items = fullData['products'] as List;
        } else if (fullData['orderItems'] != null && fullData['orderItems'] is List && (fullData['orderItems'] as List).isNotEmpty) {
          items = fullData['orderItems'] as List;
        } else if (fullData['cart'] != null && fullData['cart'] is List && (fullData['cart'] as List).isNotEmpty) {
          items = fullData['cart'] as List;
        } else {
          items = [
            {
              'name': order['service'],
              'price': _extractPriceValue(order['price']),
              'currency': order['amountCurrency'] ?? 'EGP',
              'quantity': 1,
            }
          ];
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details ${order['orderId'] ?? order['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${order['status']}'),
              Text('Date: ${order['date']}'),
              
              // Show Emergency Order label if applicable
              if (isEmergencyOrder)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Emergency Order',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              // Order type and service
              Text('Order Type: ${isServiceOrder ? 'Service' : 'Products'}'),
              if (fullData['serviceType'] != null)
                Text('Service Type: ${fullData['serviceType']}'),
              if (fullData['packageName'] != null && fullData['packageName'] != 'null')
                Text('Package: ${fullData['packageName']}'),
              
              // Car
              if (order['carModel'] != 'Not available')
                Text('Vehicle: ${order['carModel']}'),
              
              // Payment details
              const Divider(),
              const Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Amount: ${order['price']}'),
              Text('Payment Method: ${order['paymentMethod']}'),
              Text('Payment Status: ${order['paymentStatus']}'),
              
              // Products list or service details
              const Divider(),
              Text('${isServiceOrder ? 'Service Details' : 'Products'}:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              ...(items ?? []).map((item) {
                String name = 'Product';
                double price = 0;
                int quantity = 1;
                
                if (item is Map) {
                  name = item['name'] ?? item['title'] ?? 'Product';
                  price = _extractNumericValue(item['price'] ?? item['cost'] ?? 0);
                  quantity = _extractIntegerValue(item['quantity'] ?? 1);
                } else if (item is String) {
                  name = item;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('$name ${quantity > 1 ? '(${quantity}x)' : ''} - ${price.toStringAsFixed(2)} ${order['amountCurrency'] ?? 'EGP'}'),
                );
              }),
              
              // Delivery information
              if (order['deliveryAddress'] != null || order['hasLocation'] == true) ...[
                const Divider(),
                const Text('Delivery Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (order['deliveryAddress'] != null)
                  Text('Address: ${order['deliveryAddress']}'),
                if (order['deliveryNotes'] != null)
                  Text('Notes: ${order['deliveryNotes']}'),
                if (order['hasLocation'] == true)
                  ElevatedButton(
                    onPressed: () {
                      final location = order['deliveryLocation'];
                      if (location != null && location is Map) {
                        final lat = location['latitude'];
                        final lng = location['longitude'];
                        if (lat != null && lng != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('View location on map: $lat, $lng')),
                          );
                        }
                      }
                    },
                    child: const Text('View Location on Map'),
                  ),
              ],
              
              // Customer information
              if (order['customerName'] != null || fullData['customerName'] != null) ...[
                const Divider(),
                const Text('Customer Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Name: ${order['customerName'] ?? fullData['customerName'] ?? 'Not available'}'),
                if (order['customerPhone'] != null || fullData['customerPhone'] != null)
                  Text('Phone: ${order['customerPhone'] ?? fullData['customerPhone']}'),
                if (order['customerEmail'] != null || fullData['customerEmail'] != null)
                  Text('Email: ${order['customerEmail'] ?? fullData['customerEmail']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 16),
            ),
          ),
          if (_canCancelOrder(order['status']))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCancelOrderDialog(order['id']);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              child: const Text(
                'Cancel Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
  
  bool _canCancelOrder(String status) {
    // Allow cancellation if order is in appropriate state
    return status == 'Pending' || status == 'Accepted' || status == 'In Progress';
  }

  void _showCancelOrderDialog(String orderId) {
    // Find the order to determine which collection it belongs to
    final orderToUpdate = _orders.firstWhere((order) => order['id'] == orderId);
    final String collectionName = orderToUpdate['sourceCollection'] ?? 'orders';
    
    // Determine the appropriate cancel status based on collection
    final String cancelStatus = collectionName == 'emergency' ? 'Cancelled' : 'Rejected';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order Cancellation'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus(orderId, cancelStatus);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            child: const Text(
              'Confirm Cancellation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }


  // Extract numeric value from any data type
  double _extractNumericValue(dynamic value) {
    if (value == null) return 0;
    
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      // Remove any non-numeric characters before conversion
      String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0;
    } else if (value is bool) {
      return value ? 1.0 : 0.0;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is Map) {
      // Try to find value in an object
      for (final key in ['value', 'amount', 'price', 'cost', 'total']) {
        if (value[key] != null) {
          return _extractNumericValue(value[key]);
        }
      }
    }
    
    return 0;
  }

  // Extract integer value
  int _extractIntegerValue(dynamic value) {
    return _extractNumericValue(value).round();
  }
  
  // Extract price value from text
  double _extractPriceValue(String priceText) {
    // Remove currency, spaces and special characters
    String numericPart = priceText.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericPart) ?? 0;
  }
  
  // Method to update order status in Firestore
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Find the order to determine which collection it belongs to
      final orderToUpdate = _orders.firstWhere((order) => order['id'] == orderId);
      final String collectionName = orderToUpdate['sourceCollection'] ?? 'orders';
      
      // Get appropriate status equivalent based on collection
      String firestoreStatus;
      
      if (collectionName == 'emergency') {
        // Convert UI status to Firestore status for emergency orders
        switch (newStatus) {
          case 'Resolved':
            firestoreStatus = 'resolved';
            break;
          case 'In Progress':
            firestoreStatus = 'in_progress';
            break;
          case 'Pending':
            firestoreStatus = 'pending';
            break;
          case 'Cancelled':
            firestoreStatus = 'cancelled';
            break;
          default:
            firestoreStatus = 'pending';
        }
      } else {
        // Convert UI status to Firestore status for regular orders
        switch (newStatus) {
          case 'Completed':
            firestoreStatus = 'completed';
            break;
          case 'Processing':
            firestoreStatus = 'processing';
            break;
          case 'Pending':
            firestoreStatus = 'pending';
            break;
          case 'Accepted':
            firestoreStatus = 'accepted';
            break;
          case 'Rejected':
            firestoreStatus = 'rejected';
            break;
          default:
            firestoreStatus = 'pending';
        }
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(orderId)
          .update({
        'status': firestoreStatus,
        'updatedAt': Timestamp.now(),
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh orders
      await _fetchUserOrders();
    } catch (e) {
      print('Error updating order status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
} 