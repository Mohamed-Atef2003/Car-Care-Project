import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class FirstOnboardingScreen extends StatelessWidget {
  const FirstOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/image/Splash1.png',
            height: 200,
          ),
          const SizedBox(height: 32),
          const Text(
            'Car Care',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to the world of Car Care\nWe\'re everywhere and ready to reach you anytime, anywhere. We provide the best solutions to rescue, repair, clean, and inspect your car. 🚗✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
