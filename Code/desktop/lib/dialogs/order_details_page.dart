import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// منع تعارض الخيوط عند استخدام Firestore
// Service class to handle Firestore operations on the main thread
class FirebaseService {
  static Future<void> updateProductStock(String productId, int newStock) async {
    // Ensure we are on the main thread
    await _ensureMainThread();
    
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'stockCount': newStock,
        'inStock': newStock > 0,
      });
    } catch (e) {
      debugPrint('Error updating product stock: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getProductData(String productId) async {
    // Ensure we are on the main thread
    await _ensureMainThread();
    
    try {
      return await FirebaseFirestore.instance.collection('products').doc(productId).get();
    } catch (e) {
      debugPrint('Error getting product data: $e');
      rethrow;
    }
  }

  // Helper method to ensure we're on the main thread
  static Future<void> _ensureMainThread() async {
    if (!WidgetsBinding.instance.isRootWidgetAttached) {
      // If we're not on the main thread, schedule the work on the main thread
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        completer.complete();
      });
      await completer.future;
    }
  }
}

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  
  const OrderDetailsPage({
    super.key,
    required this.orderDetails,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late String _selectedStatus;
  
  @override
  void initState() {
    super.initState();
    // Normalize the status value to match the dropdown items exactly
    String initialStatus = widget.orderDetails['status'] ?? 'Pending';
    
    // Make sure the value matches exactly one of the options in the dropdown
    // The error happens when the value doesn't match the case of the dropdown items
    if (initialStatus.toLowerCase() == 'rejected') {
      _selectedStatus = 'Rejected';
    }else if (initialStatus.toLowerCase() == 'pending') {
      _selectedStatus = 'Pending';
    } else if (initialStatus.toLowerCase() == 'processing') {
      _selectedStatus = 'Processing';
    } else if (initialStatus.toLowerCase() == 'accepted') {
      _selectedStatus = 'Accepted';
    } else if (initialStatus.toLowerCase() == 'completed') {
      _selectedStatus = 'Completed';
    }  else {
      // Default to Pending if status is not recognized
      _selectedStatus = 'Pending';
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
      case 'accepted':
        return Colors.green;
      case 'Rejected':
      case 'rejected':
        return Colors.red;
      case 'Completed':
      case 'completed':
        return Colors.blue;
      case 'Processing':
      case 'processing':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
  
  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedStatus,
        icon: const Icon(Icons.keyboard_arrow_down),
        underline: Container(),
        isExpanded: true,
        onChanged: (newValue) {
          setState(() {
            _selectedStatus = newValue!;
          });
        },
        items: ['Rejected', 'Pending', 'Processing', 'Accepted', 'Completed']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(value),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildStatusTimeline() {
    final steps = ['Pending', 'Processing', 'Accepted', 'Completed'];
    final currentIndex = steps.indexOf(_selectedStatus);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index <= currentIndex;
            final isLast = index == steps.length - 1;
            
            return Expanded(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive 
                              ? _getStatusColor(steps[index])
                              : Colors.grey.shade300,
                          border: Border.all(
                            color: isActive 
                                ? _getStatusColor(steps[index])
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          index == 0 
                              ? Icons.receipt_outlined
                              : index == 1 
                                  ? Icons.pending_actions
                                  : index == 2 
                                      ? Icons.check
                                      : Icons.task_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentIndex
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildServiceFeatures() {
    final serviceFeatures = widget.orderDetails['serviceFeatures'];
    final packageFeatures = widget.orderDetails['packageFeatures'];
    
    if ((serviceFeatures == null || serviceFeatures.isEmpty) && 
        (packageFeatures == null || packageFeatures.isEmpty)) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Service Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        if (serviceFeatures != null && serviceFeatures.isNotEmpty) ...[
          const Text(
            'Service Features:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(serviceFeatures.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(serviceFeatures[index]),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        
        if (packageFeatures != null && packageFeatures.isNotEmpty) ...[
          const Text(
            'Package Features:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(packageFeatures.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(packageFeatures[index]),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildOrderItems() {
    final items = widget.orderDetails['items'];
    
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Order Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(item['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item['category'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item['category'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item['price']} ${widget.orderDetails['currency'] ?? 'SAR'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item['quantity'] ?? 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdditionalNotes() {
    final notes = widget.orderDetails['notes'];
    final description = widget.orderDetails['description'];
    final deliveryNotes = widget.orderDetails['deliveryNotes'];
    
    if ((notes == null || notes.isEmpty) && 
        (description == null || description.isEmpty) &&
        (deliveryNotes == null || deliveryNotes.isEmpty)) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Additional Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        
        if (description != null && description.isNotEmpty) ...[
          _buildInfoRow(
            Icons.description_outlined,
            'Description:',
            description,
          ),
          const SizedBox(height: 8),
        ],
        
        if (notes != null && notes.isNotEmpty) ...[
          _buildInfoRow(
            Icons.sticky_note_2_outlined,
            'Notes:',
            notes,
          ),
          const SizedBox(height: 8),
        ],
        
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) ...[
          _buildInfoRow(
            Icons.local_shipping_outlined,
            'Delivery Notes:',
            deliveryNotes,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details #${widget.orderDetails['orderId']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order Date: ${_formatDate(widget.orderDetails['createdAt'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      child: _buildStatusDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatusTimeline(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Information
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
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Name:',
                            widget.orderDetails['customerName'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.email_outlined,
                            'Email:',
                            widget.orderDetails['email'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone Number:',
                            widget.orderDetails['phoneNumber'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Address:',
                            widget.orderDetails['address'] ?? 'Not Available',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Order Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.inventory_2_outlined,
                            'Order Type:',
                            widget.orderDetails['orderType'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.design_services_outlined,
                            'Service Type:',
                            widget.orderDetails['service'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.inventory_outlined,
                            'Package:',
                            widget.orderDetails['packageName'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.attach_money,
                            'Amount:',
                            '${widget.orderDetails['orderCost']} ${widget.orderDetails['currency'] ?? 'SAR'}',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.payment_outlined,
                            'Payment Method:',
                            widget.orderDetails['paymentMethod'] ?? 'Not Available',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.analytics_outlined,
                            'Payment Status:',
                            widget.orderDetails['paymentStatus'] ?? 'Not Available',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Service Features
                _buildServiceFeatures(),
                
                // Order Items (for product orders)
                _buildOrderItems(),
                
                // Additional Notes, Description, Delivery Notes
                _buildAdditionalNotes(),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // Log change information
                        debugPrint('Saving changes to order status:');
                        debugPrint('Document ID: ${widget.orderDetails['documentId']}');
                        debugPrint('New Status: $_selectedStatus');
                        
                        // Check if this is a product order changing to Processing status
                        final String orderType = widget.orderDetails['orderType'] ?? '';
                        final String originalStatus = widget.orderDetails['status'] ?? '';
                        final List<dynamic> items = widget.orderDetails['items'] ?? [];
                        
                        debugPrint('Order Type: $orderType');
                        debugPrint('Original Status: $originalStatus');
                        debugPrint('Items Count: ${items.length}');
                        
                        // Debug item structure
                        if (items.isNotEmpty) {
                          debugPrint('First item structure:');
                          final firstItem = items[0];
                          firstItem.forEach((key, value) {
                            debugPrint('  $key: $value (${value.runtimeType})');
                          });
                        }
                        
                        // If it's a product order and status changing from Pending/Rejected to Processing
                        if (orderType.toLowerCase() == 'product' && 
                            (originalStatus.toLowerCase() == 'pending' || 
                             originalStatus.toLowerCase() == 'rejected') && 
                            _selectedStatus == 'Processing' &&
                            items.isNotEmpty) {
                          
                          try {
                            debugPrint('Processing product order with ${items.length} items');
                            
                            // Update stock for each product in the order
                            for (final item in items) {
                              debugPrint('Processing item: $item');
                              
                              // Get product ID - check different possible field names
                              String productId = '';
                              if (item['productId'] != null) {
                                productId = item['productId'];
                              } else if (item['id'] != null) {
                                productId = item['id'];
                              } else if (item['product_id'] != null) {
                                productId = item['product_id'];
                              }
                              
                              // Get quantity - check different possible field names
                              int quantity = 1;
                              if (item['quantity'] != null) {
                                quantity = int.tryParse(item['quantity'].toString()) ?? 1;
                              } else if (item['qty'] != null) {
                                quantity = int.tryParse(item['qty'].toString()) ?? 1;
                              } else if (item['amount'] != null) {
                                quantity = int.tryParse(item['amount'].toString()) ?? 1;
                              }
                              
                              debugPrint('Product ID: $productId, Quantity: $quantity');
                              
                              if (productId.isNotEmpty && quantity > 0) {
                                // Get product data using the service class
                                final docSnapshot = await FirebaseService.getProductData(productId);
                                
                                if (!docSnapshot.exists) {
                                  debugPrint('Product not found: $productId');
                                  continue;
                                }
                                
                                // Log document data
                                final data = docSnapshot.data() as Map<String, dynamic>;
                                debugPrint('Current product data: $data');
                                
                                // Get current stock count
                                final int currentStock = int.tryParse(data['stockCount']?.toString() ?? '0') ?? 0;
                                debugPrint('Current stock: $currentStock');
                                
                                // Calculate new stock count (ensure it doesn't go below zero)
                                final int newStock = (currentStock >= quantity) ? currentStock - quantity : 0;
                                debugPrint('New stock will be: $newStock');
                                
                                // Update product with new stock count using the service class
                                await FirebaseService.updateProductStock(productId, newStock);
                                
                                debugPrint('Updated stock for product $productId: $currentStock -> $newStock (Ordered: $quantity)');
                              } else {
                                debugPrint('Invalid product data: ID=$productId, Quantity=$quantity');
                              }
                            }
                            
                            debugPrint('Stock count updated for all products in the order');
                            
                          } catch (e) {
                            debugPrint('Error updating product stock: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating product stock: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          debugPrint('Conditions not met for stock update:');
                          debugPrint('- Order type is product: ${orderType.toLowerCase() == 'product'}');
                          debugPrint('- Original status is pending/rejected: ${originalStatus.toLowerCase() == 'pending' || originalStatus.toLowerCase() == 'rejected'}');
                          debugPrint('- New status is Processing: ${_selectedStatus == 'Processing'}');
                          debugPrint('- Has items: ${items.isNotEmpty}');
                        }
                        
                        // Return data structure with new status and document ID
                        Navigator.of(context).pop({
                          'status': _selectedStatus,
                          'documentId': widget.orderDetails['documentId'],
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
