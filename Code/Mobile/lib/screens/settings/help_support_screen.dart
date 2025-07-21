import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Chat/customer chat/customer_service_chat_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    // Clean phone number
    phoneNumber = phoneNumber.replaceAll(' ', '').replaceAll('-', '');
    
    // Create URI for calling
    final Uri uri = Uri.parse('tel:$phoneNumber');
    
    try {
      // Open phone app directly
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call number: $phoneNumber')),
      );
      print('Error launching phone call: $e');
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@carcare.com',
      queryParameters: {
        'subject': 'Support Request',
        'body': 'Hello, I need help with...',
      },
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email')),
      );
      print('Error launching email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            _buildQuickActions(context),
            _buildFAQSection(),
            _buildContactSection(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent,
            color: Colors.white,
            size: 60,
          ),
          const SizedBox(height: 15),
          const Text(
            'How can we help you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Find answers to common questions or get in touch with our support team',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  Icons.chat_bubble_outline,
                  'Live Chat',
                  'Chat with our support team',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerServiceChatScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  Icons.phone_outlined,
                  'Call Us',
                  'Speak with an agent',
                  () => _makePhoneCall(context, '+2 012-0000-0000'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<Map<String, dynamic>> faqs = [
      {
        'question': 'How do I book a service?',
        'answer': 'To book a service, go to the Services tab, select your desired service, choose a date and time, and complete the booking process.',
      },
      {
        'question': 'What payment methods are accepted?',
        'answer': 'We accept all major credit cards, mobile payment apps, and cash on delivery for certain services.',
      },
      {
        'question': 'How can I track my service status?',
        'answer': 'You can track your service status in the My Appointments section of the app. You\'ll receive real-time updates about your service progress.',
      },
      {
        'question': 'What is your cancellation policy?',
        'answer': 'You can cancel or reschedule your appointment up to 24 hours before the scheduled time without any charges.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return _buildFAQItem(faqs[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              faq['answer'],
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildContactOption(
            context,
            Icons.email_outlined,
            'Email Support',
            'support@carcare.com',
            () => _sendEmail(context),
          ),
          _buildContactOption(
            context,
            Icons.location_on_outlined,
            'Visit Our Center',
            'Main Road, Cairo, Egypt',
            () => _launchUrl('https://www.google.com/maps/search/?api=1&query=30.0500,31.2333'),
          ),
          _buildContactOption(
            context,
            Icons.schedule_outlined,
            'Working Hours',
            '24/7 All Time',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
} 