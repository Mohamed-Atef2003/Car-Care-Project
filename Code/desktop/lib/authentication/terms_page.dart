import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).round()),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'CAR CARE DESKTOP APP TERMS & CONDITIONS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'IMPORTANT:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'These Terms and Conditions ("Conditions") define the basis upon which Car Care will provide you with access to the Car Care Desktop Application Platform, pursuant to which you will be able to manage your car care services, including but not limited to scheduling, tracking, and managing orders, through Car Care\'s Desktop Application Platform. These Conditions (together with the documents referred to herein) set out the terms of use on which you may, as a customer, use the desktop app and manage your car care services. By using the desktop app and ticking the acceptance box, you indicate that you accept these Terms of Use which apply, among other things, to all services hereinunder to be rendered to or by you via the desktop app and that you agree to abide by them.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '1. Acceptance of Terms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'By accessing or using the Car Care Desktop Application ("Desktop App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, you must not use the Desktop App.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. Services Provided',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'The Desktop App allows you to manage your car care services, including but not limited to scheduling, tracking, and managing orders. These services are provided by third-party service providers who are independent contractors and not employees of Car Care.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. User Responsibilities',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• You must provide accurate and complete information when using the Desktop App.\n'
                        '• You are responsible for maintaining the confidentiality of your account and password.\n'
                        '• You agree to use the Desktop App only for lawful purposes and in accordance with these Terms and Conditions.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '4. Payment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'All payments for services managed through the Desktop App must be made via the payment methods provided within the Desktop App. Car Care reserves the right to change pricing at any time without prior notice.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '5. Cancellation and Refunds',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'You may cancel a service request through the Desktop App, subject to the cancellation policy of the service provider.\n'
                        'Refunds, if applicable, will be processed in accordance with the service provider\'s refund policy.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '6. Limitation of Liability',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Car Care shall not be liable for any damages, losses, or injuries arising from the use of the Desktop App or the services provided by third-party service providers.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '7. Changes to Terms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Car Care reserves the right to modify these Terms and Conditions at any time. Any changes will be effective immediately upon posting on the Desktop App. Your continued use of the Desktop App constitutes your acceptance of the revised terms.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '8. Governing Law',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'These Terms and Conditions shall be governed by and construed in accordance with the laws of the jurisdiction in which Car Care operates.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
