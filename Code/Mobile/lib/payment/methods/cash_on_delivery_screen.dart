import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../models/payment_model.dart';
import '../../../constants/colors.dart';
import '../widgets/payment_success_screen.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/user_provider.dart';
import '../paymob_manager.dart';

class CashOnDeliveryScreen extends StatefulWidget {
  final PaymentSummary paymentSummary;
  final String? orderId;

  const CashOnDeliveryScreen({
    super.key,
    required this.paymentSummary,
    this.orderId,
  });

  @override
  _CashOnDeliveryScreenState createState() => _CashOnDeliveryScreenState();
}

class _CashOnDeliveryScreenState extends State<CashOnDeliveryScreen> {
  bool _isProcessing = false;
  bool _isPaymentSuccess = false;
  String? _errorMessage;
  PaymentTransaction? _transaction;
  
  // Additional fields specific to Cash on Delivery
  final TextEditingController _notesController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing) {
          return false;
        }
        
        bool shouldPop = false;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to cancel this purchase?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Continue Order'),
              ),
              ElevatedButton(
                onPressed: () {
                  shouldPop = true;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text('Cancel Order'),
              ),
            ],
          ),
        );
        
        return shouldPop;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cash Collection'),
          backgroundColor: AppColors.primary,
          elevation: 2,
          centerTitle: true,
          leading: _isProcessing ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: _isPaymentSuccess
            ? PaymentSuccessScreen(
                transaction: _transaction!,
                onContinue: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary information
                    Card(
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Order Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_long, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Order ID: ${widget.orderId?.substring(0, 8) ?? "Not available"}',
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${widget.paymentSummary.total.toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (widget.paymentSummary.discount > 0) ...[
                              const Divider(height: 24),
                              _buildOrderDetail('Subtotal', widget.paymentSummary.subtotal, widget.paymentSummary.currency),
                              _buildOrderDetail('Discount', widget.paymentSummary.discount, widget.paymentSummary.currency, isDiscount: true),
                            ],
                            
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${widget.paymentSummary.total.toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cash on Delivery Card
                    Card(
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.local_shipping, color: Colors.amber, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Cash on Delivery',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Cash on Delivery Icon
                            Center(
                              child: Container(
                                height: 80,
                                width: 80,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.payments_outlined,
                                    size: 40,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Description
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'You will pay cash when your order is delivered.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Please ensure you have the amount ready: ${widget.paymentSummary.total.toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Additional notes
                            const SizedBox(height: 20),
                            const Text(
                              'Additional delivery notes (optional):',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Add special delivery instructions or other notes...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                            
                            // Terms checkbox
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 1.0,
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    activeColor: AppColors.primary,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      'I agree to the terms and conditions for cash on delivery and commit to paying the full amount upon receipt of the order.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Additional information
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Important Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Delivery will be within 3-5 business days. The delivery agent will call you before arrival. Please ensure you or a representative is present at the delivery location.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    
                    // Error message if present
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Confirm order button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _agreeToTerms ? _processOrder : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 2,
                        ),
                        child: _isProcessing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Confirming order...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Confirm Order for ${widget.paymentSummary.total.toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),

                    // Return to previous screen
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Return to Previous Screen'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _processOrder() async {
    if (!_agreeToTerms) {
      _showMessage('Please agree to the terms and conditions', isError: true);
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Simulate order processing
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random order failure (5% chance)
      final double failureChance = Random().nextDouble();
      if (failureChance < 0.05) {
        throw Exception('Failed to confirm order. Please try again.');
      }

      // Ensure we use a consistent order ID for the transaction
      // Always use the orderId passed to the widget if available
      final String orderId = widget.orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Using orderId for both Firebase and Paymob: $orderId');

      // Create additionalData map for the transaction
      Map<String, dynamic> additionalData = {
        'paymentMethod': 'Cash on Delivery',
        'orderId': orderId, // Use the consistent orderId
        'processingTime': DateTime.now().toString(),
        'deliveryNotes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'paymentStatus': 'Pending',
      };

      // Copy relevant data from paymentSummary
      if (widget.paymentSummary.additionalData != null) {
        // Copy discount information
        if (widget.paymentSummary.additionalData!.containsKey('discount')) {
          additionalData['discount'] = widget.paymentSummary.additionalData!['discount'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('discountCode')) {
          additionalData['discountCode'] = widget.paymentSummary.additionalData!['discountCode'];
        }
        
        // Copy delivery address
        if (widget.paymentSummary.additionalData!.containsKey('deliveryAddress')) {
          additionalData['deliveryAddress'] = widget.paymentSummary.additionalData!['deliveryAddress'];
        }
        
        // Copy customer ID
        if (widget.paymentSummary.additionalData!.containsKey('customerId')) {
          additionalData['customerId'] = widget.paymentSummary.additionalData!['customerId'];
        }
        
        // Copy items
        if (widget.paymentSummary.additionalData!.containsKey('items')) {
          additionalData['items'] = widget.paymentSummary.additionalData!['items'];
        }
        // Copy service data
        if (widget.paymentSummary.additionalData!.containsKey('serviceType')) {
          additionalData['serviceType'] = widget.paymentSummary.additionalData!['serviceType'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('packageName')) {
          additionalData['packageName'] = widget.paymentSummary.additionalData!['packageName'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('description')) {
          additionalData['description'] = widget.paymentSummary.additionalData!['description'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('notes')) {
          additionalData['notes'] = widget.paymentSummary.additionalData!['notes'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('serviceName')) {
          additionalData['serviceName'] = widget.paymentSummary.additionalData!['serviceName'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('serviceFeatures')) {
          additionalData['serviceFeatures'] = widget.paymentSummary.additionalData!['serviceFeatures'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('packageFeatures')) {
          additionalData['packageFeatures'] = widget.paymentSummary.additionalData!['packageFeatures'];
        }
      }

      _transaction = PaymentTransaction(
        transactionId: 'cod_${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.paymentSummary.total,
        currency: widget.paymentSummary.currency,
        timestamp: DateTime.now(),
        paymentMethod: 'cash_on_delivery',
        success: true,
        additionalData: additionalData,
        orderId: orderId, // Use the consistent orderId
      );
      
      // Save order to Firestore
      final bool savedToFirestore = await _saveOrderToFirestore(_transaction!);
      
      // Register payment with Paymob using the same orderId
      try {
        debugPrint('Registering Cash on Delivery payment with Paymob...');
        
        // Get user info for billing data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;
        
        // Get delivery address from additionalData
        String? deliveryAddress;
        if (additionalData.containsKey('deliveryAddress')) {
          deliveryAddress = additionalData['deliveryAddress']?.toString();
        }
        
        // Register the cash payment with Paymob with more complete information
        // Pass the same orderId to Paymob
        await PaymobManager.processCashPayment(
          context: context,
          paymentSummary: widget.paymentSummary,
          orderId: orderId, // Use the consistent orderId here
          customerInfo: {
            'name': user != null ? '${user.firstName} ${user.lastName}' : 'Customer',
            'email': user?.email ?? 'customer@example.com',
            'phone': user?.mobile ?? '+201000000000',
            'address': deliveryAddress ?? 'Address not specified',
          },
          onSuccess: (paymobTransaction) {
            debugPrint('Payment successfully registered with Paymob: ${paymobTransaction.transactionId}');
            // We already have our own transaction object, so we don't need to replace it
            // Add Paymob transaction ID to our transaction for reference
            if (_transaction != null && _transaction!.additionalData != null) {
              _transaction!.additionalData!['paymobTransactionId'] = paymobTransaction.transactionId;
            }
          },
          onError: (error) {
            // Just log the error but don't fail the order process
            debugPrint('Error registering with Paymob: $error');
          },
        );
        
        debugPrint('Successfully registered cash payment with Paymob');
      } catch (e) {
        // If Paymob registration fails, log the error but continue with the order
        debugPrint('Error registering payment with Paymob: $e');
        // We don't want to fail the order just because Paymob registration failed
      }
      
      if (!savedToFirestore) {
        // If saving to Firestore failed, show an error but continue with the checkout
        _showMessage('Order completed but there was a problem saving the data', isError: true);
      } else {
        _showMessage('Order successfully completed and data saved');
        
        // Clear cart after successful order only if data was saved to Firestore
        final storeProvider = Provider.of<StoreProvider>(context, listen: false);
        storeProvider.clearCart();
        
        debugPrint('Shopping cart cleared after successful order save');
      }

      setState(() {
        _isPaymentSuccess = true;
      });

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transaction: _transaction!,
            onContinue: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isPaymentSuccess = false;
      });

      _showMessage(_errorMessage ?? 'An error occurred while confirming your order', isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // Save order to Firestore
  Future<bool> _saveOrderToFirestore(PaymentTransaction transaction) async {
    debugPrint('Starting order save in Firestore...');
    debugPrint('Order details:');
    debugPrint('Amount: ${transaction.amount}');
    debugPrint('Transaction ID: ${transaction.transactionId}');
    debugPrint('Processing time: ${transaction.timestamp}');
    debugPrint('Payment method: ${transaction.paymentMethod}');
    debugPrint('Additional data: ${transaction.additionalData}');

    // Extract customerId from transaction data or current user
    String? customerId;
    if (transaction.additionalData != null && transaction.additionalData!.containsKey('customerId')) {
      customerId = transaction.additionalData!['customerId']?.toString();
    }
    if (customerId == null || customerId.isEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      customerId = userProvider.user?.id;
      debugPrint('Customer ID not found in transaction data. Using current user ID: $customerId');
    }

    // Extract orderId from data
    String orderId = transaction.orderId;
    
    // Extract items from data
    List<dynamic> items = [];
    if (transaction.additionalData != null && transaction.additionalData!.containsKey('items')) {
      items = transaction.additionalData!['items'] as List<dynamic>;
    }
    
    // Check if order is for a service
    bool isServiceOrder = false;
    String? serviceType;
    String? packageName;
    List<String>? serviceFeatures;
    List<String>? packageFeatures;
    
    if (transaction.additionalData != null) {
      if (transaction.additionalData!.containsKey('serviceType')) {
        isServiceOrder = true;
        serviceType = transaction.additionalData!['serviceType'];
        debugPrint('Service type: $serviceType');
      }
      
      if (transaction.additionalData!.containsKey('packageName')) {
        packageName = transaction.additionalData!['packageName'];
        debugPrint('Package name: $packageName');
      }
      
      if (transaction.additionalData!.containsKey('serviceFeatures')) {
        var features = transaction.additionalData!['serviceFeatures'];
        if (features is List) {
          serviceFeatures = List<String>.from(features);
        }
      }
      
      if (transaction.additionalData!.containsKey('packageFeatures')) {
        var features = transaction.additionalData!['packageFeatures'];
        if (features is List) {
          packageFeatures = List<String>.from(features);
        }
      }
    }
    
    // Prepare Firestore data
    final Map<String, dynamic> firestoreData = {
      'customerId': customerId,
      'orderId': orderId,
      'amount': transaction.amount,
      'currency': transaction.currency,
      'status': 'Pending',
      'paymentMethod': 'Cash Collection',
      'paymentStatus': 'Pending',
      'createdAt': Timestamp.fromDate(transaction.timestamp),
      'updatedAt': Timestamp.fromDate(transaction.timestamp),
    };
    
    // Add customer info if available
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      firestoreData['customerName'] = '${userProvider.user!.firstName} ${userProvider.user!.lastName}';
      firestoreData['customerEmail'] = userProvider.user!.email;
      firestoreData['customerPhone'] = userProvider.user!.mobile;
    }
    
    // Add service info if order is for a service
    if (isServiceOrder) {
      firestoreData['orderType'] = 'service';
      firestoreData['serviceType'] = serviceType;
      firestoreData['packageName'] = packageName;
      
      // Extract and save description if available
      if (widget.paymentSummary.items != null && 
          widget.paymentSummary.items!.isNotEmpty && 
          widget.paymentSummary.items![0].containsKey('description')) {
        firestoreData['description'] = widget.paymentSummary.items![0]['description'];
      }
      
      // Extract and save notes if available
      if (widget.paymentSummary.items != null && 
          widget.paymentSummary.items!.isNotEmpty && 
          widget.paymentSummary.items![0].containsKey('notes')) {
        firestoreData['notes'] = widget.paymentSummary.items![0]['notes'];
      }
      
      if (serviceFeatures != null) {
        firestoreData['serviceFeatures'] = serviceFeatures;
      }
      
      if (packageFeatures != null) {
        firestoreData['packageFeatures'] = packageFeatures;
      }
    } else {
      firestoreData['orderType'] = 'product';
      firestoreData['items'] = items.map((item) => {
        'productId': item['productId'] ?? '',
        'name': item['name'] ?? 'Unknown',
        'price': item['price'] ?? 0.0,
        'quantity': item['quantity'] ?? 1,
        'category': item['category'] ?? 'Uncategorized',
        'imageUrl': item['imageUrl'] ?? '',
      }).toList();
    }
    
    // Add delivery notes if available
    if (transaction.additionalData != null && transaction.additionalData!.containsKey('deliveryNotes')) {
      firestoreData['deliveryNotes'] = transaction.additionalData!['deliveryNotes'];
    }
    
    // Add delivery address if available
    if (transaction.additionalData != null && transaction.additionalData!.containsKey('deliveryAddress')) {
      firestoreData['deliveryAddress'] = transaction.additionalData!['deliveryAddress'];
    }
    
    // Add notes if available
    if (transaction.additionalData != null && transaction.additionalData!.containsKey('notes')) {
      firestoreData['notes'] = transaction.additionalData!['notes'];
    }
    
    try {
      debugPrint('Order data to be saved: $firestoreData');
      
      // Save to Firestore using orderId as document ID
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)  // Use orderId as the document ID
          .set(firestoreData);
      
      debugPrint('Order saved successfully in Firestore with document ID = orderID: $orderId');
      return true;
    } catch (e) {
      debugPrint('Error saving order to Firestore: $e');
      return false;
    }
  }

  // Build order detail row
  Widget _buildOrderDetail(String label, double amount, String currency, {bool isDiscount = false}) {
    final formattedAmount = amount.toStringAsFixed(2);
    final prefix = isDiscount ? '- ' : '';
    final textColor = isDiscount ? Colors.green : null;
    final fontWeight = isDiscount ? FontWeight.bold : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: textColor),
          ),
          Text(
            '$prefix$formattedAmount $currency',
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
} 