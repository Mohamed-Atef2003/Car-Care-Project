import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../Chat/chat bot/chatbot_screen.dart';
import '../../Chat/customer chat/customer_service_chat_screen.dart';

class SupportServicesScreen extends StatelessWidget {
  const SupportServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Services'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 40),
            _buildServiceCard(
              context,
              'Customer Service',
              'Contact our customer service team for assistance',
              Icons.support_agent,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerServiceChatScreen(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildServiceCard(
              context,
              'AI Assistant',
              'Get immediate answers to your common questions',
              Icons.smart_toy,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatbotScreen(),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'We are here to help you 24/7',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
