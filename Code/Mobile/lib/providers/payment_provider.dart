import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentSummary? _currentPaymentSummary;
  PaymentMethod? _selectedPaymentMethod;
  PaymentTransaction? _lastTransaction;
  
  // Getters
  PaymentSummary? get currentPaymentSummary => _currentPaymentSummary;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  PaymentTransaction? get lastTransaction => _lastTransaction;
  
  PaymentProvider() {
    _initializePaymentMethod();
  }
  
  void _initializePaymentMethod() {
    // Initialize with only cash payment method
    _selectedPaymentMethod = PaymentMethod(
      id: 'cash_on_delivery',
      name: 'Cash Payment',
      icon: 'local_shipping',
      isDefault: true,
    );
    
    notifyListeners();
  }
  
  void setPaymentSummary(PaymentSummary summary) {
    _currentPaymentSummary = summary;
    notifyListeners();
  }
  
  void setLastTransaction(PaymentTransaction transaction) {
    _lastTransaction = transaction;
    notifyListeners();
  }
  
  void clearPaymentState() {
    _currentPaymentSummary = null;
    _lastTransaction = null;
    notifyListeners();
  }
  
  // Set payment transaction after processing
  void setPaymentTransaction(PaymentTransaction transaction) {
    _lastTransaction = transaction;
    notifyListeners();
  }
} 