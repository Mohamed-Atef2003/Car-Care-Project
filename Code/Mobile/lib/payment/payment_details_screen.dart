import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Add import for Random

import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/store_provider.dart';
import '../../constants/colors.dart';
import '../../constants/constant.dart';
import 'methods/cash_on_delivery_screen.dart';
import 'widgets/payment_success_screen.dart';
import 'paymob_manager.dart';
import 'deep_link_handler.dart';
import '../../providers/user_provider.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final PaymentSummary paymentSummary;
  final String? orderId;

  const PaymentDetailsScreen({
    super.key,
    required this.paymentSummary,
    this.orderId,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  bool _isDiscountExpanded = false;
  final TextEditingController _discountCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController(); // Add missing controller
  bool _isApplyingDiscount = false;
  String? _discountError;
  double _appliedDiscountAmount = 0.0;
  String _appliedDiscountCode = '';
  bool _isLoadingLocation = false;
  bool _isProcessingPayment = false;
  
  // Add _transaction variable declaration
  PaymentTransaction? _transaction;

  // Payment method selection
  String _selectedPaymentMethod = 'Cash Collection'; // Default payment method

  // Available payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash_collection',
      'name': 'Cash Collection',
      'icon': Icons.local_shipping,
      'color': Colors.orange,
      'description': 'Pay when you receive'
    },
    {
      'id': 'online_card',
      'name': 'Online Card',
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'description': 'Pay with credit/debit card'
    },
    {
      'id': 'mobile_wallet',
      'name': 'Mobile Wallet',
      'icon': Icons.phone_android,
      'color': Colors.green,
      'description': 'Pay with your mobile wallet'
    },
  ];

  // Available discount codes
  final List<Map<String, dynamic>> _availableDiscountCodes = [
    {
      'code': 'DISCOUNT20',
      'description': '20% discount on order',
      'type': 'percentage',
      'value': 0.20,
      'minOrderValue': 100.0,
    },
    {
      'code': 'NEWUSER',
      'description': '15% discount for new users',
      'type': 'percentage',
      'value': 0.15,
      'minOrderValue': 50.0,
    },
    {
      'code': 'FREE',
      'description': 'Free delivery',
      'type': 'shipping',
      'value': 1.0, // 100% of delivery fee
      'minOrderValue': 200.0,
    },
    {
      'code': 'SUMMER2023',
      'description': '10% summer discount',
      'type': 'percentage',
      'value': 0.10,
      'minOrderValue': 0.0,
    },
    {
      'code': 'WELCOME50',
      'description': 'EGP 50 discount on first order',
      'type': 'fixed',
      'value': 50.0,
      'minOrderValue': 150.0,
    },
  ];

  // Suggested discount codes to display
  List<Map<String, dynamic>> get _suggestedDiscountCodes {
    final orderValue = widget.paymentSummary.total;
    return _availableDiscountCodes
        .where((discount) => discount['minOrderValue'] <= orderValue)
        .take(3)
        .toList();
  }

  late final PaymentProvider _paymentProvider;
  late final UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    // Initialize the payment provider with the current payment summary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _paymentProvider.setPaymentSummary(widget.paymentSummary);
    });
  }

  @override
  void dispose() {
    _discountCodeController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Get current user location
  Future<void> _getUserLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permission permanently denied, please enable it in device settings')),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
        setState(() {
          _addressController.text = address;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _addressController.text = 'No address found for current location';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location')),
      );
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _applyDiscount() {
    // This would be connected to a service to validate the discount code
    setState(() {
      _isApplyingDiscount = true;
      _discountError = null;
    });

    // Simulate network request
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      final discountCode = _discountCodeController.text.toUpperCase();

      // Search for discount code in the list
      final discountInfo = _availableDiscountCodes.firstWhere(
        (discount) => discount['code'] == discountCode,
        orElse: () => {
          'code': '',
          'description': '',
          'type': '',
          'value': 0.0,
          'minOrderValue': 0.0,
        },
      );

      // Verify code validity
      if (discountInfo['code'].isNotEmpty) {
        // Check minimum order value
        if (widget.paymentSummary.total < discountInfo['minOrderValue']) {
          setState(() {
            _isApplyingDiscount = false;
            _discountError =
                'This code requires a minimum order of ${discountInfo['minOrderValue']} ${widget.paymentSummary.currency}';

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Cannot apply code. Minimum order: ${discountInfo['minOrderValue']} ${widget.paymentSummary.currency}'),
                backgroundColor: Colors.red,
                duration: const Duration(milliseconds: 5),
              ),
            );
          });
          return;
        }

        // Calculate discount amount based on type
        double discountAmount = 0.0;

        switch (discountInfo['type']) {
          case 'percentage':
            discountAmount =
                widget.paymentSummary.total * discountInfo['value'];
            break;
          case 'fixed':
            discountAmount = discountInfo['value'];
            break;
          case 'shipping':
            discountAmount =
                widget.paymentSummary.deliveryFee * discountInfo['value'];
            break;
        }

        setState(() {
          _appliedDiscountAmount = discountAmount;
          _appliedDiscountCode = discountInfo['code'];
          _isApplyingDiscount = false;
          _discountError = null;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Successfully applied ${discountInfo['description']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Close discount section
          _isDiscountExpanded = false;
        });
      } else {
        setState(() {
          _isApplyingDiscount = false;
          _discountError = 'Invalid discount code';

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid discount code, please try another one'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        });
      }
    });
  }

  void _proceedToPayment() async {
    // Set processing state to true
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Check address field and get current location if empty
      if (_addressController.text.trim().isEmpty) {
        // Show message that location is being fetched
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching your current location...')),
        );

        // Get current location
        await _getUserLocation();

        if (!mounted) return;
        
        // Check again if field is still empty (in case location fetch failed)
        if (_addressController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not fetch your location. Please enter address manually or try again')),
          );
          setState(() {
            _isProcessingPayment = false;
          });
          return;
        }
      }

      // Simulate order validation
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Generate a unique order ID or use the provided one
      final String orderId = widget.orderId ??
          'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}';
      debugPrint('Using order ID: $orderId');

      // Calculate final cost after discount
      final serviceCharge =
          widget.paymentSummary.subtotal * 0.01; // 1% service charge
      final finalTotal =
          widget.paymentSummary.total - _appliedDiscountAmount + serviceCharge;

      // Compile discount information if exists
      Map<String, dynamic>? discountData;
      if (_appliedDiscountAmount > 0) {
        final discountInfo = _availableDiscountCodes.firstWhere(
          (discount) => discount['code'] == _appliedDiscountCode,
          orElse: () => {
            'code': _appliedDiscountCode,
            'description': 'Discount',
            'type': 'Unknown',
          },
        );

        discountData = {
          'code': _appliedDiscountCode,
          'amount': _appliedDiscountAmount,
          'type': discountInfo['type'],
          'description': discountInfo['description'],
        };
      }

      // Create comprehensive additionalData map
      final Map<String, dynamic> additionalDataMap = {
        'orderId': orderId,
        'processingTime': DateTime.now().toString(),
      };

      // Add discount information when needed
      if (discountData != null) {
        additionalDataMap['discount'] = discountData;
        additionalDataMap['discountCode'] = _appliedDiscountCode;
        additionalDataMap['discountType'] = discountData['type'];
      }

      // Add delivery address to payment data
      additionalDataMap['deliveryAddress'] = _addressController.text;

      // Get user information
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        additionalDataMap['customerId'] = userProvider.user!.id;
        additionalDataMap['customerName'] =
            '${userProvider.user!.firstName} ${userProvider.user!.lastName}';
        additionalDataMap['customerEmail'] = userProvider.user!.email;
        additionalDataMap['customerPhone'] = userProvider.user!.mobile;
      }

      // Copy information from items
      if (widget.paymentSummary.items != null &&
          widget.paymentSummary.items!.isNotEmpty) {
        // Add items to the additionalData
        additionalDataMap['items'] = widget.paymentSummary.items;

        // Extract first item's data for convenience
        final firstItem = widget.paymentSummary.items![0];

        // Add description if available
        if (firstItem.containsKey('description')) {
          additionalDataMap['description'] = firstItem['description'];
        }

        // Add notes if available
        if (firstItem.containsKey('notes')) {
          additionalDataMap['notes'] = firstItem['notes'];
        }

        // Add category if available
        if (firstItem.containsKey('category')) {
          additionalDataMap['category'] = firstItem['category'];
        }

        // Check if this is a service order
        if (firstItem.containsKey('serviceType')) {
          additionalDataMap['serviceType'] = firstItem['serviceType'];
        }

        // Add package name if available
        if (firstItem.containsKey('packageName')) {
          additionalDataMap['packageName'] = firstItem['packageName'];
        }

        // Add service name if available
        if (firstItem.containsKey('serviceName')) {
          additionalDataMap['serviceName'] = firstItem['serviceName'];
        }
      }

      // Add any additional info from original payment summary
      if (widget.paymentSummary.additionalData != null) {
        // Copy service-related data
        for (final key in [
          'serviceType',
          'serviceName',
          'packageName',
          'serviceFeatures',
          'packageFeatures',
          'description',
          'notes',
          'customerId'
        ]) {
          if (widget.paymentSummary.additionalData!.containsKey(key) &&
              !additionalDataMap.containsKey(key)) {
            additionalDataMap[key] = widget.paymentSummary.additionalData![key];
          }
        }
      }

      // Create final payment summary
      final updatedSummary = PaymentSummary(
        subtotal: widget.paymentSummary.subtotal,
        tax: widget.paymentSummary.tax,
        deliveryFee: widget.paymentSummary.deliveryFee,
        discount: _appliedDiscountAmount,
        total: finalTotal,
        currency: widget.paymentSummary.currency,
        items: widget.paymentSummary.items,
        additionalData: additionalDataMap,
      );

      // Show confirmation before proceeding if there's a discount
      if (_appliedDiscountAmount > 0) {
        setState(() {
          _isProcessingPayment = false;
        });
        _showDiscountConfirmation(discountData!, updatedSummary);
      } else {
        // Go directly to payment screen if no discount
        setState(() {
          _isProcessingPayment = false;
        });
        _navigateToPaymentScreen(updatedSummary);
      }
    } catch (e) {
      debugPrint('Error in _proceedToPayment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  // Separate function to show discount confirmation dialog
  void _showDiscountConfirmation(
      Map<String, dynamic> discountInfo, PaymentSummary updatedSummary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'The following discount has been applied to your order:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount code:'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          discountInfo['code'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount type:'),
                      Text(discountInfo['description']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount before discount:'),
                      Text(
                          '${widget.paymentSummary.total.toStringAsFixed(2)} ${widget.paymentSummary.currency}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount amount:'),
                      Text(
                          '${_appliedDiscountAmount.toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final amount:'),
                      Text(
                          '${updatedSummary.total.toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (updatedSummary.total !=
                      widget.paymentSummary.total - _appliedDiscountAmount) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '(including service fees)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPaymentScreen(updatedSummary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );
  }

  // Navigate based on selected payment method
  void _navigateToPaymentScreen(PaymentSummary paymentSummary) {
    // Add delivery address to payment data
    Map<String, dynamic> additionalData = paymentSummary.additionalData ?? {};
    additionalData['deliveryAddress'] = _addressController.text;
    additionalData['paymentMethod'] = _selectedPaymentMethod;

    // Add description if available in items
    if (paymentSummary.items != null &&
        paymentSummary.items!.isNotEmpty &&
        paymentSummary.items![0].containsKey('description')) {
      additionalData['description'] = paymentSummary.items![0]['description'];
    }

    // Add notes if available in items
    if (paymentSummary.items != null &&
        paymentSummary.items!.isNotEmpty &&
        paymentSummary.items![0].containsKey('notes')) {
      additionalData['notes'] = paymentSummary.items![0]['notes'];
    }

    // Create updated payment summary
    final updatedSummary = PaymentSummary(
      subtotal: paymentSummary.subtotal,
      tax: paymentSummary.tax,
      deliveryFee: paymentSummary.deliveryFee,
      discount: paymentSummary.discount,
      total: paymentSummary.total,
      currency: paymentSummary.currency,
      items: paymentSummary.items,
      additionalData: additionalData,
    );

    // Generate order ID if not available
    final String orderId = widget.orderId ??
        'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}';

    // Navigate based on selected payment method
    switch (_selectedPaymentMethod) {
      case 'Cash Collection':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CashOnDeliveryScreen(
              paymentSummary: updatedSummary,
              orderId: orderId,
            ),
          ),
        );
        break;

      case 'Online Card':
        // Initialize PaymobManager and process payment
        _processCardPayment(updatedSummary, orderId);
        break;

      case 'Mobile Wallet':
        // Show mobile wallet payment dialog
        _showMobileWalletPaymentDialog(updatedSummary, orderId);
        break;

      default:
        // Default to cash on delivery
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CashOnDeliveryScreen(
              paymentSummary: updatedSummary,
              orderId: orderId,
            ),
          ),
        );
    }
  }

  // Process card payment via Paymob
  Future<void> _processCardPayment(
      PaymentSummary paymentSummary, String orderId) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get callback URL using the deep link handler
      final callbackUrl = DeepLinkHandler.getCallbackUrl(orderId);

      // Create comprehensive additionalData for consistent Firebase storage
      Map<String, dynamic> additionalData = paymentSummary.additionalData ?? {};
      additionalData['orderId'] = orderId;
      additionalData['paymentMethod'] = 'Online Card';
      additionalData['deliveryAddress'] = _addressController.text;
      additionalData['deliveryNotes'] = _notesController.text.isNotEmpty ? _notesController.text : null;
      
      // Create updated payment summary with the comprehensive data
      final updatedSummary = PaymentSummary(
        subtotal: paymentSummary.subtotal,
        tax: paymentSummary.tax,
        deliveryFee: paymentSummary.deliveryFee,
        discount: paymentSummary.discount,
        total: paymentSummary.total,
        currency: paymentSummary.currency,
        items: paymentSummary.items,
        additionalData: additionalData,
      );

      // Start card payment with callback URL
      await PaymobManager.processCardPayment(
        context: context,
        paymentSummary: updatedSummary, // Use updated summary with all data
        orderId: orderId,
        customerInfo: {
          'name': _userProvider.user != null
              ? '${_userProvider.user!.firstName} ${_userProvider.user!.lastName}'
              : 'Customer',
          'email': _userProvider.user?.email ?? 'customer@example.com',
          'phone': _userProvider.user?.mobile ?? '+201000000000',
          'address': _addressController.text,
        },
        callbackUrl: callbackUrl,
        onSuccess: (transaction) {
          _handleSuccessfulPayment(transaction);
        },
        onError: (error) {
          _handlePaymentError(error);
        },
      );
    } catch (e) {
      _handlePaymentError('Failed to process card payment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  // Show mobile wallet payment dialog
  void _showMobileWalletPaymentDialog(
      PaymentSummary paymentSummary, String orderId) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Create comprehensive additionalData for consistent Firebase storage
      Map<String, dynamic> additionalData = paymentSummary.additionalData ?? {};
      additionalData['orderId'] = orderId;
      additionalData['paymentMethod'] = 'Mobile Wallet';
      additionalData['deliveryAddress'] = _addressController.text;
      additionalData['deliveryNotes'] = _notesController.text.isNotEmpty ? _notesController.text : null;
      
      // Create updated payment summary with the comprehensive data
      final updatedSummary = PaymentSummary(
        subtotal: paymentSummary.subtotal,
        tax: paymentSummary.tax,
        deliveryFee: paymentSummary.deliveryFee,
        discount: paymentSummary.discount,
        total: paymentSummary.total,
        currency: paymentSummary.currency,
        items: paymentSummary.items,
        additionalData: additionalData,
      );
      
      // Get the payment manager instance
      final manager = PaymobManager();

      // Get the payment key from Paymob
      final String paymentKey = await manager.payWithPaymob(
        context: context,
        amount: updatedSummary.total,
        orderId: orderId,
        integrationType: 'wallet',
      );

      if (!mounted) return;

      // Generate callback URL
      final String callbackUrl = 'carcare://payment/callback?order_id=$orderId';
      final String encodedCallbackUrl = Uri.encodeComponent(callbackUrl);

      // Build the direct iframe URL with the specific ID 910189
      final String iframeUrl =
          'https://accept.paymob.com/api/acceptance/iframes/${Constants.paymobWalletIframeId}?payment_token=$paymentKey&callback_url=$encodedCallbackUrl';

      // Navigate directly to the WebView with the iframe
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymobWebView(
            url: iframeUrl,
            callbackUrl: callbackUrl,
            paymentSummary: updatedSummary, // Use updated summary with all data
            orderId: orderId,
            onSuccess: (transaction) {
              _handleSuccessfulPayment(transaction);
            },
            onError: (error) {
              _handlePaymentError(error);
            },
          ),
        ),
      );
    } catch (e) {
      _handlePaymentError('Failed to process wallet payment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  // Save order to Firestore (adapted from CashOnDeliveryScreen)
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
    if (transaction.additionalData != null &&
        transaction.additionalData!.containsKey('customerId')) {
      customerId = transaction.additionalData!['customerId']?.toString();
    }
    if (customerId == null || customerId.isEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      customerId = userProvider.user?.id;
      debugPrint(
          'Customer ID not found in transaction data. Using current user ID: $customerId');
    }

    // Extract orderId from data
    String orderId = transaction.orderId;

    // Extract items from data
    List<dynamic> items = [];
    if (transaction.additionalData != null &&
        transaction.additionalData!.containsKey('items')) {
      items = transaction.additionalData!['items'] as List<dynamic>;
    } //else if (widget.paymentSummary.items != null) {
    //   items = widget.paymentSummary.items!;
    // }

    // Check if order is for a service
    bool isServiceOrder = false;
    String? serviceType;
    String? packageName;
    String? serviceName;
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

      if (transaction.additionalData!.containsKey('serviceName')) {
        serviceName = transaction.additionalData!['serviceName'];
        debugPrint('Service name: $serviceName');
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
      'paymentMethod': _getFormattedPaymentMethod(transaction.paymentMethod),
      'paymentStatus': transaction.paymentMethod.toLowerCase().contains('cash')
          ? 'Pending'
          : 'Paid',
      'transactionId': transaction.transactionId,
      'createdAt': Timestamp.fromDate(transaction.timestamp),
      'updatedAt': Timestamp.fromDate(transaction.timestamp),
    };

    // Add customer info if available
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      firestoreData['customerName'] =
          '${userProvider.user!.firstName} ${userProvider.user!.lastName}';
      firestoreData['customerEmail'] = userProvider.user!.email;
      firestoreData['customerPhone'] = userProvider.user!.mobile;
    }

    // Add service info if order is for a service
    if (isServiceOrder) {
      firestoreData['orderType'] = 'service';
      firestoreData['serviceType'] = serviceType;
      firestoreData['packageName'] = packageName;


      if (packageName != null) {
        firestoreData['packageName'] = packageName;
      }

      if (serviceName != null) {
        firestoreData['serviceName'] = serviceName;
      }

      if (serviceFeatures != null) {
        firestoreData['serviceFeatures'] = serviceFeatures;
      }
      
      if (packageFeatures != null) {
        firestoreData['packageFeatures'] = packageFeatures;
      }

      // Extract and save description if available
      if (widget.paymentSummary.items != null &&
          widget.paymentSummary.items!.isNotEmpty) {
        if (widget.paymentSummary.items![0].containsKey('description')) {
          firestoreData['description'] =
              widget.paymentSummary.items![0]['description'];
        }

        // Extract and save notes if available
      if (widget.paymentSummary.items != null && 
          widget.paymentSummary.items!.isNotEmpty && 
          widget.paymentSummary.items![0].containsKey('notes')) {
        firestoreData['notes'] = widget.paymentSummary.items![0]['notes'];
      }

        // Extract category if available
        if (widget.paymentSummary.items![0].containsKey('category')) {
          firestoreData['category'] =
              widget.paymentSummary.items![0]['category'];
        }
      }

      if (serviceFeatures != null) {
        firestoreData['serviceFeatures'] = serviceFeatures;
      }

      if (packageFeatures != null) {
        firestoreData['packageFeatures'] = packageFeatures;
      }
    } else {
      firestoreData['orderType'] = 'product';
      firestoreData['items'] = items
          .map((item) => {
                'productId': item['productId'] ?? '',
                'name': item['name'] ?? 'Unknown',
                'price': item['price'] ?? 0.0,
                'quantity': item['quantity'] ?? 1,
                'category': item['category'] ?? 'Uncategorized',
                'imageUrl': item['imageUrl'] ?? '',
              })
          .toList();
    }

    // Add delivery notes if available
    if (transaction.additionalData != null &&
        transaction.additionalData!.containsKey('deliveryNotes')) {
      firestoreData['deliveryNotes'] =
          transaction.additionalData!['deliveryNotes'];
    }

    // Add delivery address if available
    if (transaction.additionalData != null &&
        transaction.additionalData!.containsKey('deliveryAddress')) {
      firestoreData['deliveryAddress'] =
          transaction.additionalData!['deliveryAddress'];
    } else if (_addressController.text.isNotEmpty) {
      firestoreData['deliveryAddress'] = _addressController.text;
    }

    // Add notes if available
    if (transaction.additionalData != null &&
        transaction.additionalData!.containsKey('notes')) {
      firestoreData['notes'] = transaction.additionalData!['notes'];
    }

    // Add discount information if available
    if (transaction.additionalData != null) {
      if (transaction.additionalData!.containsKey('discount')) {
        firestoreData['discount'] = transaction.additionalData!['discount'];
      }
      if (transaction.additionalData!.containsKey('discountCode')) {
        firestoreData['discountCode'] =
            transaction.additionalData!['discountCode'];
      }
    }

    try {
      // Attempt to get user's location for delivery
      Position? currentPosition;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            currentPosition = await Geolocator.getCurrentPosition();
            firestoreData['deliveryLocation'] = {
              'latitude': currentPosition.latitude,
              'longitude': currentPosition.longitude,
            };
          }
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
      }

      debugPrint('Order data to be saved: $firestoreData');

      // Save to Firestore with orderId as document ID
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)  // Use orderId as the document ID
            .set(firestoreData);

        debugPrint('Order saved successfully in Firestore with document ID = orderID: $orderId');
        return true;
      } catch (e) {
        debugPrint('Error saving order in Firestore: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error saving order in Firestore: $e');
      return false;
    }
  }

  // Helper method to format payment method string
  String _getFormattedPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
      case 'card_payment':
        return 'Credit/Debit Card';
      case 'mobile_wallet':
      case 'wallet':
        return 'Mobile Wallet';
      case 'cash_on_delivery':
      case 'cash_collection':
        return 'Cash Collection';
      default:
        return method;
    }
  }

  // Handle payment error
  void _handlePaymentError(String errorMessage) {
    if (!mounted) return;

    // Clear is processing flag
    setState(() {
      _isProcessingPayment = false;
    });

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Helper method to show messages consistently
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

  // Handle payment success
  void _handleSuccessfulPayment(PaymentTransaction transaction) async {
    if (!mounted) return;

    // Clear is processing flag
    setState(() {
      _isProcessingPayment = false;
    });

    try {
      // Simulate order processing
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      
      // Simulate random order failure (5% chance)
      final double failureChance = Random().nextDouble();
      if (failureChance < 0.05) {
        throw Exception('Failed to confirm order. Please try again.');
      }

      // Ensure we use a consistent order ID for the transaction
      // Always use the orderId passed to the widget if available
      final String orderId = widget.orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Using orderId for both Firebase and Paymob: $orderId');

      // Create or update additionalData map for the transaction to ensure all payment methods
      // have consistent data format
      Map<String, dynamic> additionalData = transaction.additionalData ?? {};
      
      // Ensure required fields are present regardless of payment method
      if (!additionalData.containsKey('paymentMethod')) {
        additionalData['paymentMethod'] = transaction.paymentMethod;
      }
      if (!additionalData.containsKey('orderId')) {
        additionalData['orderId'] = orderId;
      }
      if (!additionalData.containsKey('processingTime')) {
        additionalData['processingTime'] = DateTime.now().toString();
      }
      if (!additionalData.containsKey('deliveryNotes') && _notesController.text.isNotEmpty) {
        additionalData['deliveryNotes'] = _notesController.text;
      }
      if (!additionalData.containsKey('paymentStatus')) {
        additionalData['paymentStatus'] = transaction.paymentMethod.toLowerCase().contains('cash') ? 
          'Pending' : 'Paid';
      }
      if (!additionalData.containsKey('deliveryAddress')) {
        additionalData['deliveryAddress'] = _addressController.text;
      }

      // Copy relevant data from paymentSummary if not already in additionalData
      if (widget.paymentSummary.additionalData != null) {
        // Copy discount information
        if (widget.paymentSummary.additionalData!.containsKey('discount') && 
            !additionalData.containsKey('discount')) {
          additionalData['discount'] = widget.paymentSummary.additionalData!['discount'];
        }
        if (widget.paymentSummary.additionalData!.containsKey('discountCode') && 
            !additionalData.containsKey('discountCode')) {
          additionalData['discountCode'] = widget.paymentSummary.additionalData!['discountCode'];
        }
        
        // Copy customer ID
        if (widget.paymentSummary.additionalData!.containsKey('customerId') && 
            !additionalData.containsKey('customerId')) {
          additionalData['customerId'] = widget.paymentSummary.additionalData!['customerId'];
        }
        
        // Copy items
        if (widget.paymentSummary.additionalData!.containsKey('items') && 
            !additionalData.containsKey('items')) {
          additionalData['items'] = widget.paymentSummary.additionalData!['items'];
        }

        // Copy service data
        final serviceFields = [
          'serviceType', 'packageName', 'description', 'notes', 
          'serviceName', 'serviceFeatures', 'packageFeatures'
        ];
        
        for (String field in serviceFields) {
          if (widget.paymentSummary.additionalData!.containsKey(field) && 
              !additionalData.containsKey(field)) {
            additionalData[field] = widget.paymentSummary.additionalData![field];
          }
        }
      }

      // Create a new transaction with consistent data if it doesn't already exist
      _transaction ??= PaymentTransaction(
          transactionId: transaction.transactionId,
          amount: transaction.amount,
          currency: transaction.currency,
          timestamp: transaction.timestamp,
          paymentMethod: transaction.paymentMethod,
          success: transaction.success,
          additionalData: additionalData,
          orderId: orderId,
        );

      // Update payment provider with transaction data
      _paymentProvider.setLastTransaction(transaction);

      // Save order to Firestore with consistent data structure
      debugPrint('Attempting to save order to Firestore...');
      final bool savedToFirestore = await _saveOrderToFirestore(_transaction ?? transaction);
      
      if (!mounted) return;

      try {
        // For cash payment methods, register with Paymob
        if (transaction.paymentMethod.toLowerCase().contains('cash')) {
          debugPrint('Registering Cash on Delivery payment with Paymob...');
          
          // Get user info for billing data
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final user = userProvider.user;
          
          // Get delivery address from additionalData
          String? deliveryAddress = _addressController.text;
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
              if (!mounted) return;
              debugPrint('Payment successfully registered with Paymob: ${paymobTransaction.transactionId}');
              // We already have our own transaction object, so we don't need to replace it
              // Add Paymob transaction ID to our transaction for reference
              if (_transaction != null && _transaction!.additionalData != null) {
                _transaction!.additionalData!['paymobTransactionId'] = paymobTransaction.transactionId;
              }
            },
            onError: (error) {
              if (!mounted) return;
              // Just log the error but don't fail the order process
              debugPrint('Error registering with Paymob: $error');
            },
          );
          
          debugPrint('Successfully registered cash payment with Paymob');
        }
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

      if (!mounted) return;
      // Navigate to success screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transaction: transaction,
            onContinue: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error in _handleSuccessfulPayment: $e');
      if (!mounted) return;
      // Even if there's an error in our processing, the payment was successful
      // So we should show a success message but log the error
      _showMessage(
          'Payment successful, but there was an error processing some order details',
          isError: true);

      // Still navigate to success page since payment was successful
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            transaction: transaction,
            onContinue: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }

  // Show dialog for payment methods that are not yet implemented (original method, keeping for reference)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order information and date
                Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Order ID: ${widget.orderId != null ? (widget.orderId!.length > 8 ? widget.orderId!.substring(0, 8) : widget.orderId) : "Not available"}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Order date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Order time: ${DateFormat('hh:mm a').format(DateTime.now())}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Product details (if available)
                if (widget.paymentSummary.items != null &&
                    widget.paymentSummary.items!.isNotEmpty)
                  Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.paymentSummary.items!.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final item = widget.paymentSummary.items![index];
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Product',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (item['category'] != null)
                                          Text(
                                            item['category'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${item['quantity'] ?? 1} × ${item['price'] ?? 0} ${widget.paymentSummary.currency}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // Cost summary breakdown
                Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCostRow('Subtotal',
                            '${widget.paymentSummary.subtotal.toStringAsFixed(2)} ${widget.paymentSummary.currency}'),
                        _buildCostRow(
                            'Tax (${(widget.paymentSummary.tax / widget.paymentSummary.subtotal * 100).toStringAsFixed(0)}%)',
                            '${widget.paymentSummary.tax.toStringAsFixed(2)} ${widget.paymentSummary.currency}'),
                        _buildCostRow('Delivery Fee',
                            '${widget.paymentSummary.deliveryFee.toStringAsFixed(2)} ${widget.paymentSummary.currency}'),

                        // Coupon Discount
                        _isDiscountExpanded
                            ? _buildExpandedDiscountSection()
                            : _buildCostRow(
                                'Coupon Discount',
                                _appliedDiscountAmount > 0
                                    ? '- ${_appliedDiscountAmount.toStringAsFixed(2)} ${widget.paymentSummary.currency}'
                                    : 'Add coupon',
                                isAction: _appliedDiscountAmount <= 0,
                                onTap: () {
                                  setState(() {
                                    _isDiscountExpanded = true;
                                  });
                                },
                                valueColor: _appliedDiscountAmount > 0
                                    ? Colors.green
                                    : AppColors.primary,
                              ),

                        const Divider(height: 24),

                        // Service fee
                        _buildCostRow('Service Fee',
                            '${(widget.paymentSummary.subtotal * 0.01).toStringAsFixed(2)} ${widget.paymentSummary.currency}'),

                        const Divider(height: 24),

                        // Total with big font
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(widget.paymentSummary.total - _appliedDiscountAmount + (widget.paymentSummary.subtotal * 0.01)).toStringAsFixed(2)} ${widget.paymentSummary.currency}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        if (_appliedDiscountAmount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You saved ${_appliedDiscountAmount.toStringAsFixed(2)} ${widget.paymentSummary.currency} with your discount coupon!',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Delivery address section
                Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Address',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          style: GoogleFonts.cairo(),
                          decoration: InputDecoration(
                            hintText: 'Enter delivery address',
                            hintStyle: GoogleFonts.cairo(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.teal.shade400),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isLoadingLocation
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.teal.shade700,
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.my_location,
                                          color: Colors.teal.shade700,
                                          size: 20),
                                      onPressed: _getUserLocation,
                                    ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter delivery address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Payment methods
                Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Payment method options
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) =>
                              Divider(height: 1),
                          itemCount: _paymentMethods.length,
                          itemBuilder: (context, index) {
                            final method = _paymentMethods[index];
                            final isSelected =
                                _selectedPaymentMethod == method['name'];

                            return RadioListTile<String>(
                              title: Text(
                                method['name'] as String,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(method['description'] as String),
                              secondary: Icon(
                                method['icon'] as IconData,
                                color: method['color'] as Color,
                                size: 28,
                              ),
                              value: method['name'] as String,
                              groupValue: _selectedPaymentMethod,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Cancellation and return policy
                Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cancellation & Return Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.access_time, color: Colors.blue[300]),
                          minLeadingWidth: 0,
                          title: const Text(
                            'You can cancel the order within 24 hours',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.replay, color: Colors.orange[300]),
                          minLeadingWidth: 0,
                          title: const Text(
                            'You can return products within 14 days of receipt',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.security, color: Colors.green[300]),
                          minLeadingWidth: 0,
                          title: const Text(
                            'All payment transactions are secure and encrypted',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Payment button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 2,
                    ),
                    child: _isProcessingPayment
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Processing...',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Show different icon based on payment method
                              Icon(
                                  _selectedPaymentMethod == 'Cash Collection'
                                      ? Icons.local_shipping
                                      : _selectedPaymentMethod == 'Online Card'
                                          ? Icons.credit_card
                                          : Icons.phone_android,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Pay with $_selectedPaymentMethod (${(widget.paymentSummary.total - _appliedDiscountAmount + (widget.paymentSummary.subtotal * 0.01)).toStringAsFixed(2)} ${widget.paymentSummary.currency})',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Function to create a cost row
  Widget _buildCostRow(String label, String value,
      {bool isAction = false, VoidCallback? onTap, Color? valueColor}) {
    return InkWell(
      onTap: isAction ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: valueColor,
                  ),
                ),
                if (isAction) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: valueColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Suggested coupons
  Wrap _buildSuggestedCoupons() {
    return Wrap(
      spacing: 8,
      children: _suggestedDiscountCodes.map((discount) {
        return _buildSuggestedCoupon(
          discount['code'],
          discount['description'],
        );
      }).toList(),
    );
  }

  // Discount coupon entry section
  Widget _buildExpandedDiscountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Discount Coupon',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isDiscountExpanded = false;
                  });
                },
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountCodeController,
                  decoration: InputDecoration(
                    labelText: 'Discount Code',
                    errorText: _discountError,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isApplyingDiscount ? null : _applyDiscount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(80, 48),
                ),
                child: _isApplyingDiscount
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Suggested coupons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_suggestedDiscountCodes.isNotEmpty) ...[
                const Text(
                  'Available coupons:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                _buildSuggestedCoupons(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Suggested coupon
  Widget _buildSuggestedCoupon(String code, String description) {
    return InkWell(
      onTap: () {
        setState(() {
          _discountCodeController.text = code;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
