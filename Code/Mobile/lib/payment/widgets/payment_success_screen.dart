import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../models/payment_model.dart';
import '../../../constants/colors.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentTransaction transaction;
  final VoidCallback onContinue;

  const PaymentSuccessScreen({
    super.key,
    required this.transaction,
    required this.onContinue,
  });

  // Method to display messages consistently

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onContinue();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Payment Successful'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success animation
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 100,
                    ).animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                      ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transaction Completed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
              const SizedBox(height: 8),
              Text(
                'Thank you! Your order has been confirmed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
              const SizedBox(height: 40),
              
              // Transaction details
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildTransactionDetail(
                        'Transaction ID',
                        transaction.transactionId.substring(0, min(transaction.transactionId.length, 12)),
                      ),
                      _buildTransactionDetail(
                        'Date & Time',
                        DateFormat('dd/MM/yyyy - hh:mm a').format(transaction.timestamp),
                      ),
                      _buildTransactionDetail(
                        'Amount',
                        '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                        isAmount: true,
                      ),
                      _buildTransactionDetail(
                        'Payment Method',
                        _getFormattedPaymentMethod(transaction.paymentMethod),
                      ),
                      
                      // Additional data
                      if (transaction.additionalData != null && transaction.additionalData!.containsKey('orderId'))
                        _buildTransactionDetail(
                          'Order ID',
                          transaction.additionalData!['orderId']?.toString() ?? 'Not available',
                        ),
                      
                      // Show payment status for online payments
                      if (transaction.paymentMethod == 'card' || transaction.paymentMethod == 'mobile_wallet')
                        _buildTransactionDetail(
                          'Status',
                          'Successful',
                          isAmount: true,
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
              
              const SizedBox(height: 40),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Order successful and cart already cleared
                    onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Return to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 1100)),
              
              const SizedBox(height: 16),
              
            ],
          ),
        ),
      ),
    );
  }

  // Create transaction detail
  Widget _buildTransactionDetail(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              color: isAmount ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  // Convert payment method ID to human-readable name
  String _getFormattedPaymentMethod(String methodId) {
    switch (methodId) {
      case 'cash_on_delivery':
        return 'Cash Collection';
      case 'card':
        return 'Credit/Debit Card';
      case 'mobile_wallet':
        return 'Mobile Wallet';
      default:
        return methodId.split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
    }
  }
  
  // Utility function to get minimum of two numbers
  int min(int a, int b) {
    return a < b ? a : b;
  }
} 