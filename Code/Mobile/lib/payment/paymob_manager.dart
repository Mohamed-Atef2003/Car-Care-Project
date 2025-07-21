import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constant.dart';
import '../providers/user_provider.dart';
import '../models/payment_model.dart';

class PaymobManager {
  final Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));
  
  // Adding retry control constants
  static const int maxRetries = 3;
  static const int initialBackoffMs = 1000; // 1 second
  
  // Iframe IDs for different payment methods
  // static const int paymobWalletIframeId = 910189;

  // Main method to initiate payment process
  Future<String> payWithPaymob({
    required BuildContext context,
    required double amount,
    required String orderId,
    String? integrationType,
    Map<String, String>? customerInfo,
  }) async {
    if (!context.mounted) {
      throw Exception('BuildContext is no longer valid');
    }
    
    try {
      // Add small delay between requests to avoid too many requests at the same time
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Convert amount to cents (Paymob requires amount in cents)
      final int amountInCents = (amount * 100).toInt();
      
      // Step 1: Authentication and obtain token
      String token = await _executeWithRetry(() => postToken());
      debugPrint('Paymob authentication token obtained');
      
      if (!context.mounted) {
        throw Exception('BuildContext is no longer valid');
      }
      
      // Add small delay between requests
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 2: Order registration - pass the external orderId
      int registeredOrderId = await _executeWithRetry(() => postOrder(
        token: token, 
        amount: amountInCents.toString(),
        externalOrderId: orderId, // Pass the orderId to maintain consistency
      ));
      debugPrint('Paymob order registered with ID: $registeredOrderId');
      
      if (!context.mounted) {
        throw Exception('BuildContext is no longer valid');
      }
      
      // Add small delay between requests
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 3: Payment key generation
      String paymentKey = await _executeWithRetry(() => getPaymentKey(
        context: context,
        token: token, 
        orderId: registeredOrderId.toString(), 
        amount: amountInCents.toString(),
        integrationType: integrationType,
        customerInfo: customerInfo,
      ));
      debugPrint('Paymob payment key generated successfully');
      
      return paymentKey;
    } catch (e) {
      debugPrint('Error in payWithPaymob: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          debugPrint('Response status: ${response.statusCode}');
          debugPrint('Response data: ${response.data}');
          
          if (response.statusCode == 429) {
            throw Exception('Payment gateway error: Too many requests. Please wait a moment and try again.');
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            throw Exception('Payment gateway error: Authentication failed. Please check your API keys.');
          } else if (response.data is Map && response.data.containsKey('message')) {
            throw Exception('Payment gateway error: ${response.data['message']}');
          }
        }
      }
      throw Exception('Failed to initialize payment: $e');
    }
  }
  
  // Retry mechanism with exponential backoff
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (e is DioException && e.response?.statusCode == 429 && attempt < maxRetries) {
          // Increase wait time significantly to avoid hitting rate limits again
          final waitTime = initialBackoffMs * (1 << (attempt)); // Increase wait time exponentially
          debugPrint('Rate limited (429). Retrying after $waitTime ms. Attempt $attempt of $maxRetries');
          await Future.delayed(Duration(milliseconds: waitTime));
          continue;
        }
        // Rethrow exception if it's not a 429 error or max attempts are reached
        rethrow;
      }
    }
  }

  // Step 1: Get authentication token
  Future<String> postToken() async {
    try {
      Response response = await dio.post(
        'https://accept.paymob.com/api/auth/tokens',
        data: {
          'api_key': Constants.paymobApiKey,
        },
        options: Options(
          headers: {
            'content-type': 'application/json',
          },
        ),
      );
      return response.data['token'];
    } catch (e) {
      debugPrint('Error in postToken: $e');
     rethrow;
    }
  }

  // Step 2: Register order
  Future<int> postOrder({
    required String token,
    required String amount,
    String? externalOrderId, // Optional external order ID to use
  }) async {
    try {
      // Create a unique reference for this order based on the external ID if provided
      final String orderReference = externalOrderId != null 
          ? 'ext_$externalOrderId' 
          : 'order_${DateTime.now().millisecondsSinceEpoch}';
          
      debugPrint('Registering order with Paymob using reference: $orderReference');

      Response response = await dio.post(
        'https://accept.paymob.com/api/ecommerce/orders',
        data: {
          'auth_token': token,
          'delivery_needed': 'false',
          'amount_cents': amount,
          'currency': 'EGP', // Change based on your currency
          'items': [],
          'merchant_order_id': orderReference, // Use our reference as merchant_order_id
        },
        options: Options(
          headers: {
            'content-type': 'application/json',
          },
        ),
      );
      return response.data['id'];
    } catch (e) {
      debugPrint('Error in postOrder: $e');
      rethrow;
    }
  }

  // Step 3: Get payment key
  Future<String> getPaymentKey({
    required BuildContext context,
    required String token,
    required String orderId,
    required String amount,
    String? integrationType,
    Map<String, String>? customerInfo,
  }) async {
    try {
      // Get user data from provider if not provided
      Map<String, dynamic> billingData;
      
      if (customerInfo != null) {
        // Use provided customer info
        billingData = {
          'apartment': 'NA',
          'email': customerInfo['email'] ?? 'customer@example.com',
          'floor': 'NA',
          'first_name': customerInfo['name']?.split(' ').first ?? 'Customer',
          'street': customerInfo['address'] ?? 'NA',
          'building': 'NA',
          'phone_number': customerInfo['phone'] ?? '+201000000000',
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'NA',
          'country': 'EG',
          'last_name': (customerInfo['name']?.split(' ').length ?? 0) > 1 
              ? customerInfo['name']?.split(' ').last ?? 'Customer'
              : 'Customer',
          'state': 'NA',
        };
      } else {
        // Get user data from provider if customer info not provided
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;
        
        if (user == null) {
          throw Exception('User not logged in');
        }
        
        // Prepare billing data from user
        billingData = {
          'apartment': 'NA',
          'email': user.email,
          'floor': 'NA',
          'first_name': user.firstName,
          'street': 'NA',
          'building': 'NA',
          'phone_number': user.mobile,
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'NA',
          'country': 'EG',
          'last_name': user.lastName,
          'state': 'NA',
        };
      }

      // Determine which integration ID to use based on the payment type
      int integrationId;
      if (integrationType == 'wallet') {
        integrationId = Constants.paymobWalletIntegrationId;
        debugPrint('Using wallet integration ID: $integrationId');
      } else if (integrationType == 'cash') {
        integrationId = Constants.paymobCashCollectionId;
        debugPrint('Using cash collection integration ID: $integrationId');
      } else {
        integrationId = Constants.paymobIntegrationId; // Default to card payment
        debugPrint('Using card integration ID: $integrationId');
      }

      Response response = await dio.post(
        'https://accept.paymob.com/api/acceptance/payment_keys',
        data: {
          'auth_token': token,
          'amount_cents': amount,
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': billingData,
          'currency': 'EGP', // Change based on your currency
          'integration_id': integrationId,
          'lock_order_when_paid': 'false',
        },
        options: Options(
          headers: {
            'content-type': 'application/json',
          },
        ),
      );
      return response.data['token'];
    } catch (e) {
      debugPrint('Error in getPaymentKey: $e');
      rethrow;
    }
  }

  // Method to handle card payment
  Future<void> makeCardPayment({
    required BuildContext context,
    required String paymentKey,
    required PaymentSummary paymentSummary,
    required String orderId,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Get callback URL from DeepLinkHandler
      final String callbackUrl = 'carcare://payment/callback?order_id=$orderId';
      
      // Encode the callback URL for safe inclusion in the iframe URL
      final String encodedCallbackUrl = Uri.encodeComponent(callbackUrl);
      
      // Adding authentication with new keys
      final Map<String, String> cardOptions = {
        'public_key': Constants.paymobPublicKey,
        'secret_key': Constants.paymobSecretKey,
        'callback_url': callbackUrl,
      };
      
      // Building iframe URL with public authentication key
      final String iframeUrl = 'https://accept.paymob.com/api/acceptance/iframes/${Constants.paymobIframeId}?payment_token=$paymentKey&public_key=${Uri.encodeComponent(Constants.paymobPublicKey)}&callback_url=$encodedCallbackUrl';
      
      debugPrint('Opening iframe URL with public key: $iframeUrl');
      
      // Navigate to WebView for payment
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymobWebView(
            url: iframeUrl,
            callbackUrl: callbackUrl,
            paymentSummary: paymentSummary,
            orderId: orderId,
            onSuccess: onSuccess,
            onError: onError,
          ),
        ),
      );
    } catch (e) {
      onError('Failed to open payment page: $e');
    }
  }

  // Method to handle mobile wallet payment
  Future<void> makeMobileWalletPayment({
    required BuildContext context,
    required String paymentKey,
    required String phoneNumber,
    required PaymentSummary paymentSummary,
    required String orderId,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Get callback URL from DeepLinkHandler
      final String callbackUrl = 'carcare://payment/callback?order_id=$orderId';
      final String encodedCallbackUrl = Uri.encodeComponent(callbackUrl);
      
      // For wallet payments, first check if we should use a specific iframe
      // or direct payment API depending on the wallet provider
      if (phoneNumber.startsWith('010') || phoneNumber.startsWith('011') || 
          phoneNumber.startsWith('012') || phoneNumber.startsWith('015')) {
        // For vodafone, etisalat, orange, and we - use the iframe
        // إضافة مفتاح API العام إلى URL الإطار
        final String iframeUrl = 'https://accept.paymob.com/api/acceptance/iframes/${Constants.paymobWalletIframeId}?payment_token=$paymentKey&public_key=${Uri.encodeComponent(Constants.paymobPublicKey)}&callback_url=$encodedCallbackUrl';
        
        debugPrint('Using wallet iframe with public key: $iframeUrl');
        
        // Navigate to WebView for payment with specific params for wallet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymobWebView(
              url: iframeUrl,
              callbackUrl: callbackUrl,
              paymentSummary: paymentSummary,
              orderId: orderId,
              onSuccess: onSuccess,
              onError: onError,
            ),
          ),
        );
        return;
      }
      
      // If not using iframe, fall back to API-based wallet payment
      debugPrint('Using API for wallet payment with phone: $phoneNumber');
      Response response = await dio.post(
        'https://accept.paymob.com/api/acceptance/payments/pay',
        data: {
          'source': {
            'identifier': phoneNumber,
            'subtype': 'WALLET',
          },
          'payment_token': paymentKey,
          'return_url': callbackUrl,
        },
        options: Options(
          headers: {
            'content-type': 'application/json',
            'public-key': Constants.paymobPublicKey,
            'authorization': Constants.paymobSecretKey,
          },
        ),
      );
      
      debugPrint('Mobile wallet payment response: ${response.data}');
      
      // Check for redirect URL
      if (response.data['redirect_url'] != null) {
        String redirectUrl = response.data['redirect_url'];
        if (redirectUrl.isNotEmpty) {
          debugPrint('Redirecting to: $redirectUrl');
          final redirectUri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(redirectUri)) {
            await launchUrl(redirectUri, mode: LaunchMode.externalApplication);
            // Note: The actual success callback will be handled by the deep link handler
            
            // Return success for immediate response
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Processing your payment. Please complete the process in your wallet app.'),
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            throw 'Could not launch $redirectUrl';
          }
        } else {
          onError('Empty redirect URL received');
        }
      }
      // Check payment status for immediate response
      else if (response.data['success'] == true) {
        // Payment succeeded, create transaction record
        final transaction = PaymentTransaction(
          transactionId: 'paymob_$orderId',
          amount: paymentSummary.total,
          currency: paymentSummary.currency,
          timestamp: DateTime.now(),
          paymentMethod: 'mobile_wallet',
          success: true,
          orderId: orderId,
          additionalData: {
            'paymentMethod': 'Mobile Wallet',
            'orderId': orderId,
          },
        );
        
        onSuccess(transaction);
      } else {
        onError('Payment failed: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Error in makeMobileWalletPayment: $e');
      if (e is DioException) {
        debugPrint('Status: ${e.response?.statusCode}');
        debugPrint('Data: ${e.response?.data}');
        
        if (e.response?.data != null && e.response?.data['message'] != null) {
          onError('Payment error: ${e.response?.data['message']}');
        } else {
          onError('Error processing wallet payment: ${e.toString()}');
        }
      } else {
        onError('Error processing wallet payment: ${e.toString()}');
      }
    }
  }
  
  // Parse query string to map
  static Map<String, String> parseQueryString(String query) {
    return Uri.parse('?$query').queryParameters;
  }

  // Process payment result from callback URL
  static PaymentTransaction? processPaymentResult(Uri uri) {
    debugPrint('Processing URI: ${uri.toString()}, scheme: ${uri.scheme}, path: ${uri.path}, query: ${uri.query}');
    
    // First check if this is our carcare scheme
    if (uri.scheme == 'carcare') {
      final params = uri.queryParameters;
      final success = params['success'] == 'true';
      
      debugPrint('Processing carcare callback with success: $success, params: $params');
      
      // Extract error codes and messages if any
      String errorCode = '';
      String errorMessage = '';
      
      if (!success) {
        errorCode = params['error_code'] ?? params['error_occured'] ?? params['txn_response_code'] ?? '';
        errorMessage = params['error_message'] ?? params['error'] ?? 'Payment failed';
        
        // Check if it's a 429 error (too many requests)
        if (errorCode == '429' || errorMessage.contains('429') || errorMessage.contains('too many requests')) {
          errorCode = '429';
          errorMessage = 'Too many payment requests. Please wait a moment and try again.';
        }
        
        debugPrint('Error detected: code=$errorCode, message=$errorMessage');
      }
      
      return PaymentTransaction(
        success: success,
        transactionId: params['txn_id'] ?? params['transaction_id'] ?? params['id'] ?? '',
        orderId: params['order_id'] ?? '',
        amount: double.tryParse(params['amount'] ?? '0') ?? 0,
        currency: params['currency'] ?? 'EGP',
        paymentMethod: params['source_data_type'] ?? params['method'] ?? 'Unknown',
        timestamp: DateTime.now(),
        errorCode: errorCode,
        errorMessage: errorMessage,
        additionalData: Map<String, dynamic>.from(params),
      );
    }
    // Handle any URL that contains success or error indicators
    else if (uri.toString().contains('success=true') || 
             uri.toString().contains('success=false') ||
             uri.toString().contains('error')) {
      
      debugPrint('Processing non-carcare URL with payment indicators');
      
      // Convert query parameters or extract them from the fragment
      Map<String, String> params = {};
      if (uri.hasQuery) {
        params.addAll(uri.queryParameters);
      }
      
      // Sometimes data comes in the fragment
      if (uri.hasFragment) {
        final fragmentUri = Uri.parse('?${uri.fragment}');
        params.addAll(fragmentUri.queryParameters);
      }
      
      final success = params['success'] == 'true' || uri.toString().contains('success=true');
      
      // Extract error codes and messages if any
      String errorCode = '';
      String errorMessage = '';
      
      if (!success) {
        errorCode = params['error_code'] ?? params['error_occured'] ?? params['txn_response_code'] ?? '';
        errorMessage = params['error_message'] ?? params['error'] ?? 'Payment failed';
        
        // Check if it's a 429 error (too many requests)
        if (errorCode == '429' || errorMessage.contains('429') || errorMessage.contains('too many requests')) {
          errorCode = '429';
          errorMessage = 'Too many payment requests. Please wait a moment and try again.';
        }
        
        debugPrint('Error detected: code=$errorCode, message=$errorMessage');
      }
      
      debugPrint('Extracted params: $params, success: $success');
      
      return PaymentTransaction(
        success: success,
        transactionId: params['txn_id'] ?? params['transaction_id'] ?? params['id'] ?? '',
        orderId: params['order_id'] ?? '',
        amount: double.tryParse(params['amount'] ?? '0') ?? 0,
        currency: params['currency'] ?? 'EGP',
        paymentMethod: params['source_data_type'] ?? params['method'] ?? 'Unknown',
        timestamp: DateTime.now(),
        errorCode: errorCode,
        errorMessage: errorMessage,
        additionalData: Map<String, dynamic>.from(params),
      );
    }
    
    // Could not process the result
    debugPrint('Could not process payment result from URI: $uri');
    return null;
  }

  // Process card payment with a single method
  static Future<void> processCardPayment({
    required BuildContext context,
    required PaymentSummary paymentSummary,
    required String orderId,
    required Map<String, String> customerInfo,
    required String callbackUrl,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      if (!context.mounted) return;
      
      final manager = PaymobManager();
      
      // Step 1: Get payment token from Paymob
      final String paymentKey = await manager.payWithPaymob(
        context: context,
        amount: paymentSummary.total,
        orderId: orderId,
        integrationType: 'card', // Specify this is for card payment
        customerInfo: customerInfo,
      );
      
      if (!context.mounted) return;
      
      // Step 2: Process card payment with callback URL
      // Note: The makeCardPayment method now generates its own callback URL,
      // but we'll add the callbackUrl handling in a future update if needed
      await manager.makeCardPayment(
        context: context,
        paymentKey: paymentKey,
        paymentSummary: paymentSummary,
        orderId: orderId,
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      onError('Error processing card payment: $e');
    }
  }

  // Process wallet payment with a single method
  static Future<void> processWalletPayment({
    required BuildContext context,
    required PaymentSummary paymentSummary,
    required String orderId,
    required String phoneNumber,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      if (!context.mounted) return;
      
      final manager = PaymobManager();
      
      // Step 1: Get payment token from Paymob
      final String paymentKey = await manager.payWithPaymob(
        context: context,
        amount: paymentSummary.total,
        orderId: orderId,
        integrationType: 'wallet',
      );
      
      if (!context.mounted) return;
      
      // Step 2: Process mobile wallet payment
      await manager.makeMobileWalletPayment(
        context: context,
        paymentKey: paymentKey,
        phoneNumber: phoneNumber,
        paymentSummary: paymentSummary,
        orderId: orderId,
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      onError('Error processing wallet payment: $e');
    }
  }

  // Open Card Payment Gateway (WebView)
  void openCardPaymentGateway({
    required BuildContext context,
    required String paymentKey,
    String? callbackUrl,
    Function(Map<String, dynamic>)? onSuccess,
    Function(String)? onError,
  }) {
    try {
      String iframeUrl =
          'https://accept.paymob.com/api/acceptance/iframes/757193?payment_token=$paymentKey';

      debugPrint('Opening WebView with URL: $iframeUrl');

      if (callbackUrl != null) {
        debugPrint('Using callback URL: $callbackUrl');
      }

      // Create a wrapper function to convert PaymentTransaction to Map
      final transactionToMapAdapter = onSuccess != null ? 
          (PaymentTransaction transaction) => onSuccess(transaction.additionalData ?? {}) : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymobWebView(
            url: iframeUrl,
            callbackUrl: callbackUrl,
            onSuccess: transactionToMapAdapter,
            onError: onError,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening card payment gateway: $e');
      onError?.call('Error opening payment page: $e');
    }
  }

  // Register a cash collection payment
  Future<void> registerCashPayment({
    required BuildContext context,
    required String paymentKey,
    required PaymentSummary paymentSummary,
    required String orderId,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
    Map<String, String>? customerInfo,
  }) async {
    try {
      // Create a callback URL for reference
      final String callbackUrl = 'carcare://payment/callback?order_id=$orderId';
      
      // Prepare cash payment data - enhanced to ensure approval
      Map<String, dynamic> paymentData = {
        'payment_token': paymentKey,
        'source': {
          'identifier': 'CASH',
          'subtype': 'CASH',
        },
        'payment_method': 'cash',
        'amount_cents': (paymentSummary.total * 100).toInt(),
        'order_id': orderId,
        'currency': paymentSummary.currency,
        'return_url': callbackUrl,
      };
      
      // Add customer data if available
      if (customerInfo != null) {
        paymentData['billing_data'] = {
          'email': customerInfo['email'] ?? 'customer@example.com',
          'first_name': customerInfo['name']?.split(' ').first ?? 'Customer',
          'last_name': (customerInfo['name']?.split(' ').length ?? 0) > 1 
              ? customerInfo['name']?.split(' ').last ?? 'Customer'
              : 'Customer',
          'phone_number': customerInfo['phone'] ?? '+201000000000',
          'street': customerInfo['address'] ?? 'NA',
          'apartment': 'NA',
          'floor': 'NA',
          'building': 'NA',
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'NA',
          'country': 'EG',
          'state': 'NA',
        };
      }
      
      debugPrint('Sending cash payment data to Paymob: $paymentData');
      
      // Call Paymob API to register a cash payment with new authentication
      Response response = await dio.post(
        'https://accept.paymob.com/api/acceptance/payments/pay',
        data: paymentData,
        options: Options(
          headers: {
            'content-type': 'application/json',
            'public-key': Constants.paymobPublicKey,
            'authorization': Constants.paymobSecretKey,
          },
        ),
      );
      
      debugPrint('Cash payment registration response: ${response.data}');
      
      // Check if registration was successful
      // Even with "declined" status, we'll treat it as success for cash payments
      // as they are meant to be collected later
      if (response.data['id'] != null) {
        // Create transaction object with the SAME orderId
        final transaction = PaymentTransaction(
          transactionId: response.data['id']?.toString() ?? 'cash_$orderId',
          amount: paymentSummary.total,
          currency: paymentSummary.currency,
          timestamp: DateTime.now(),
          paymentMethod: 'cash_collection',
          success: true,
          orderId: orderId, // Always use the original orderId
          additionalData: {
            'paymentMethod': 'Cash Collection',
            'orderId': orderId, // Include the original orderId in additionalData as well
            'paymobData': response.data,
            'paymobStatus': response.data['success'] == true ? 'success' : 'pending',
            'paymobOrderId': response.data['order']?.toString() ?? orderId, // Store Paymob's order ID for reference
          },
        );
        
        onSuccess(transaction);
      } else {
        onError('Failed to register cash payment: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Error in registerCashPayment: $e');
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          debugPrint('Response data: ${e.response!.data}');
          if (e.response!.data['message'] != null) {
            onError('Payment error: ${e.response!.data['message']}');
            return;
          }
        }
      }
      onError('Error registering cash payment: $e');
    }
  }
  
  // Process cash collection payment with a single method
  static Future<void> processCashPayment({
    required BuildContext context,
    required PaymentSummary paymentSummary,
    required String orderId,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
    Map<String, String>? customerInfo,
  }) async {
    try {
      if (!context.mounted) return;
      
      final manager = PaymobManager();
      
      // Step 1: Get payment token from Paymob
      final String paymentKey = await manager.payWithPaymob(
        context: context,
        amount: paymentSummary.total,
        orderId: orderId,
        integrationType: 'cash', // Specify this is for cash payment
        customerInfo: customerInfo,
      );
      
      if (!context.mounted) return;
      
      // Step 2: Register cash payment - modified to ensure approval
      await manager.registerCashPayment(
        context: context,
        paymentKey: paymentKey,
        paymentSummary: paymentSummary,
        orderId: orderId,
        customerInfo: customerInfo,
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      onError('Error processing cash payment: $e');
    }
  }
}

// WebView to handle Paymob iframe for card payments
class PaymobWebView extends StatefulWidget {
  final String url;
  final String? callbackUrl;
  final Function(PaymentTransaction)? onSuccess;
  final Function(String)? onError;
  final PaymentSummary? paymentSummary;
  final String? orderId;

  const PaymobWebView({
    super.key,
    required this.url,
    this.callbackUrl,
    this.onSuccess,
    this.onError,
    this.paymentSummary,
    this.orderId,
  });

  @override
  State<PaymobWebView> createState() => _PaymobWebViewState();
}

class _PaymobWebViewState extends State<PaymobWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _paymentProcessed = false;
  String _lastUrl = '';
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}, errorType: ${error.errorType}');
            setState(() {
              _loadError = 'Error: ${error.description}';
            });
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            setState(() {
              _lastUrl = url;
              _isLoading = true;
              _loadError = '';
            });
            
            // تحقق من URL للتعرف على نتائج الدفع بشكل سريع
            _checkForEarlyPaymentResult(url);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _lastUrl = url;
              });
            }
            debugPrint('Page finished loading: $url');
            
            // Check if the URL contains success or failure indicators
            _checkForPaymentStatus(url);
            
            // إضافة كود جافا سكريبت للتعامل مع 3D Secure
            _injectPaymentStatusMonitor();
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation to: ${request.url}');
            
            // Check if the URL is our callback URL
            if (request.url.startsWith('carcare://payment/callback') ||
                request.url.contains('success=true') ||
                request.url.contains('success=false')) {
              
              _checkForPaymentStatus(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      );
    
    // Load the URL
    debugPrint('Loading initial URL: ${widget.url}');
    _controller.loadRequest(Uri.parse(widget.url));
  }
  
  // التحقق المبكر من نتائج الدفع عند بدء تحميل الصفحة
  void _checkForEarlyPaymentResult(String url) {
    // تحقق سريع إذا كان URL يحتوي على علامات واضحة للنجاح أو الفشل
    if (url.contains('success=true') || 
        url.contains('success=false') || 
        url.contains('error') ||
        url.contains('carcare://payment')) {
      _checkForPaymentStatus(url);
    }
  }
  
  // إضافة كود جافا سكريبت لمراقبة حالة الدفع
  void _injectPaymentStatusMonitor() {
    // لا تضيف الكود إذا تمت معالجة الدفع بالفعل
    if (_paymentProcessed) return;
    
    // كود جافا سكريبت لمراقبة استجابات المدفوعات ومشاكل 3D Secure
    _controller.runJavaScript('''
      // Monitor all form submissions
      document.addEventListener('submit', function(e) {
        console.log('Form submitted', e.target.action);
      });
      
      // Monitor payment results
      function checkPaymentStatus() {
        // Check for success elements
        if (document.querySelector('.success-payment') || 
            document.querySelector('[data-status="success"]') ||
            document.body.innerHTML.includes('payment successful')) {
          window.flutter_inappwebview.callHandler('paymentSuccess');
        }
        
        // Check for failure elements
        if (document.querySelector('.failed-payment') || 
            document.querySelector('[data-status="error"]') || 
            document.body.innerHTML.includes('payment failed') ||
            document.body.innerHTML.includes('payment declined')) {
          window.flutter_inappwebview.callHandler('paymentFailed');
        }
      }
      
      // Check every 2 seconds
      setInterval(checkPaymentStatus, 2000);
      
      // Also check on load
      window.addEventListener('load', checkPaymentStatus);
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
            widget.onError?.call('Payment cancelled by user');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
              setState(() {
                _isLoading = true;
                _loadError = '';
              });
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          // تأكيد خروج المستخدم من صفحة الدفع
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Payment?'),
              content: const Text('Are you sure you want to cancel the payment process?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No, Continue'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          ) ?? false;
          
          if (shouldPop) {
            widget.onError?.call('Payment cancelled by user');
          }
          
          return shouldPop;
        },
        child: Stack(
          children: [
            if (_loadError.isNotEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _loadError,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last URL: $_lastUrl',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _controller.reload();
                        setState(() {
                          _isLoading = true;
                          _loadError = '';
                        });
                      },
                      child: const Text('Retry Loading'),
                    ),
                  ],
                ),
              )
            else
              WebViewWidget(controller: _controller),
              
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading payment page...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to process payment status from URLs
  void _checkForPaymentStatus(String url) {
    if (_paymentProcessed) return; // Avoid processing twice
    
    debugPrint('Checking payment status for URL: $url');
    
    if (url.startsWith('carcare://payment/callback')) {
      debugPrint('Detected callback URL: $url');
      
      // Parse the URL and extract parameters
      final uri = Uri.parse(url);
      _processPaymentResult(uri);
    } 
    else if (url.contains('success=true')) {
      debugPrint('Detected success in URL: $url');
      
      // Create a local URI with our scheme to process
      final fixedUrl = url.replaceAll('https://', 'carcare://');
      final uri = Uri.parse(fixedUrl);
      _processPaymentResult(uri);
    }
    else if (url.contains('success=false') || url.contains('error_occured=true')) {
      debugPrint('Detected failure in URL: $url');
      
      // Create a simple failure URI
      final uri = Uri.parse('carcare://payment/callback?success=false&error_message=Payment+failed');
      _processPaymentResult(uri);
    }
  }
  
  // Process the payment result
  void _processPaymentResult(Uri uri) {
    if (_paymentProcessed) return; // Avoid processing twice
    _paymentProcessed = true;
    
    final params = uri.queryParameters;
    
    // Check if payment was successful
    if (params.containsKey('success') && params['success'] == 'true') {
      // If paymentSummary and orderId provided, create a transaction object
      if (widget.paymentSummary != null && widget.orderId != null) {
        // Determine the payment type correctly based on the presence of 'wallet' in the URL
        String paymentMethod = 'card';
        
        // Check if URL contains the word 'wallet'
        if (widget.url.toLowerCase().contains('wallet') || 
            _lastUrl.toLowerCase().contains('wallet')) {
          paymentMethod = 'mobile_wallet';
          debugPrint('Detected Mobile Wallet payment from URL');
        } 
        // Or check additionalData in paymentSummary
        else if (widget.paymentSummary?.additionalData != null &&
            widget.paymentSummary!.additionalData!.containsKey('paymentMethod') &&
            widget.paymentSummary!.additionalData!['paymentMethod'] == 'Mobile Wallet') {
          paymentMethod = 'mobile_wallet';
          debugPrint('Detected Mobile Wallet payment from additionalData');
        }
        // Or check source_data_type
        else if (params.containsKey('source_data_type') && 
                 params['source_data_type']!.toLowerCase().contains('wallet')) {
          paymentMethod = 'mobile_wallet';
          debugPrint('Detected Mobile Wallet payment from source_data_type');
        }
        
        final transaction = PaymentTransaction(
          transactionId: params['txn_id'] ?? 'paymob_${widget.orderId}',
          amount: widget.paymentSummary!.total,
          currency: widget.paymentSummary!.currency,
          timestamp: DateTime.now(),
          paymentMethod: paymentMethod,
          success: true,
          orderId: widget.orderId!,
          additionalData: {
            'paymentMethod': paymentMethod,
            'orderId': widget.orderId!,
            ...params,
          },
        );
        
        // Additional information for correction
        debugPrint('Payment transaction created. Method: $paymentMethod');
        
        // Navigate back and call success callback
        Navigator.pop(context);
        widget.onSuccess?.call(transaction);
      } else {
        // For backwards compatibility with Map<String, dynamic> callbacks
        Navigator.pop(context);
        
        // Determine the payment type correctly based on the presence of 'wallet' in the URL
        String paymentMethod = 'card';
        if (widget.url.toLowerCase().contains('wallet') || 
            _lastUrl.toLowerCase().contains('wallet')) {
          paymentMethod = 'mobile_wallet';
        }
        
        final responseData = {
          'success': true,
          'txn_id': params['txn_id'] ?? '',
          'order_id': params['order_id'] ?? widget.orderId,
          'paymentMethod': paymentMethod,  // تعيين نوع الدفع الصحيح
          ...params,
        };
        
        // Create dummy transaction for type matching
        final dummyTransaction = PaymentTransaction(
          transactionId: params['txn_id'] ?? 'dummy',
          amount: 0,
          currency: 'EGP',
          paymentMethod: paymentMethod,  // تعيين نوع الدفع الصحيح
          success: true,
          timestamp: DateTime.now(),
          orderId: params['order_id'] ?? widget.orderId ?? 'dummy',
          additionalData: responseData,
        );
        
        try {
          widget.onSuccess?.call(dummyTransaction);
        } catch (e) {
          debugPrint('Error in callback: $e');
          widget.onError?.call('Invalid callback response format');
        }
      }
    } else {
      // Payment failed, extract error message if available
      final errorMessage = params['error_message'] ?? 'Payment failed';
      
      // Navigate back and call error callback
      Navigator.pop(context);
      widget.onError?.call(errorMessage);
    }
  }
}