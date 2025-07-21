import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import 'paymob_manager.dart';

class DeepLinkHandler {
  static bool _initialUriIsHandled = false;
  static StreamSubscription? _sub;
  static final AppLinks _appLinks = AppLinks();
  
  // Initialize deep link handling
  static void initUniLinks(BuildContext context) async {
    final BuildContext appContext = context;
    
    // Handle the initial URI if the app was opened with one
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final initialUri = await _appLinks.getInitialLink();
        if (initialUri != null) {
          _handleDeepLink(initialUri.toString(), appContext);
        }
      } catch (e) {
        debugPrint('Error handling initial deep link: $e');
      }
    }
    
    // Listen for subsequent URI events
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri.toString(), appContext);
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
    });
  }
  
  // Dispose stream subscription
  static void dispose() {
    _sub?.cancel();
  }
  
  // Process the deep link
  static void _handleDeepLink(String link, BuildContext context) {
    debugPrint('Received deep link: $link');
    
    // Check if this is a payment callback
    if (link.contains('carcare://')) {
      Uri uri = Uri.parse(link);
      
      // Process payment result
      final paymentResult = PaymobManager.processPaymentResult(uri);
      debugPrint('Processing payment result: $paymentResult');
      
      if (paymentResult != null) {
        debugPrint('Payment result success: ${paymentResult.success}');
        // Get the payment provider regardless of success or failure
        try {
          final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
          paymentProvider.setPaymentTransaction(paymentResult);
          
          // Show success or failure dialog based on payment result
          if (paymentResult.success) {
            // Payment was successful
            _showPaymentResultDialog(context, true, paymentResult);
          } else {
            // Payment failed or was cancelled
            _showPaymentResultDialog(context, false, paymentResult);
          }
        } catch (e) {
          debugPrint('Error handling payment result: $e');
          // If we can't access the provider, at least show a dialog
          _showPaymentResultDialog(context, paymentResult.success, paymentResult);
        }
      } else {
        debugPrint('Could not process payment result from URI: $uri');
        // Show generic error dialog
        _showPaymentResultDialog(context, false, null);
      }
    }
  }
  
  // Show payment result dialog
  static void _showPaymentResultDialog(BuildContext context, bool success, PaymentTransaction? transaction) {
    // Ensure we don't show dialog if context is invalid
    Future.delayed(Duration.zero, () {
      try {
        if (success && transaction != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Payment Successful'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 50),
                  const SizedBox(height: 16),
                  const Text('Your payment was processed successfully!'),
                  const SizedBox(height: 8),
                  Text('Transaction ID: ${transaction.transactionId}'),
                  Text('Amount: ${transaction.amount} ${transaction.currency}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to home or order success page
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        } else {
          String errorMessage = 'Your payment was not completed successfully.';
          
          // عرض رسالة خطأ أكثر تفصيلاً إذا كانت متوفرة
          if (transaction != null && transaction.errorMessage.isNotEmpty) {
            errorMessage = transaction.errorMessage;
          }
          
          // إذا كان خطأ 429، نعرض رسالة مخصصة
          if (transaction != null && transaction.errorCode == '429') {
            errorMessage = 'Too many payment requests. Please wait a moment and try again.';
          }
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Payment Failed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  Text(errorMessage),
                  if (transaction != null) ...[
                    const SizedBox(height: 8),
                    Text('Order ID: ${transaction.orderId}'),
                    if (transaction.errorCode.isNotEmpty)
                      Text('Error Code: ${transaction.errorCode}'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Stay on current screen to let user retry
                  },
                  child: const Text('Try Again'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Go back to payment details
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Payment Options'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error showing payment result dialog: $e');
      }
    });
  }
  
  // Create a deep link URL for Paymob callbacks
  static String getCallbackUrl(String orderId) {
    return 'carcare://payment/callback?order_id=$orderId';
  }
} 