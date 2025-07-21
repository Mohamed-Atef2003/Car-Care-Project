import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  
  factory PaymentService() {
    return _instance;
  }
  
  PaymentService._internal();
  
  // Process Cash on Delivery
  Future<Map<String, dynamic>> processCashOnDelivery({
    required double amount,
    required String currency,
    required String address,
  }) async {
    try {
      // Simulate processing
      await Future.delayed(const Duration(seconds: 1));
      
      return {
        'success': true,
        'orderId': 'cod_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
        'paymentMethod': 'cashOnDelivery',
        'address': address,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Save order data for reference
  Future<bool> saveOrderData(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderId = orderData['orderId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('last_order_$orderId', orderData.toString());
      return true;
    } catch (e) {
      debugPrint('Error saving order data: $e');
      return false;
    }
  }
} 