import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class SecondOnboardingScreen extends StatelessWidget {
  const SecondOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/image/Splash2.png',
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
            'You can find all spare parts, including the best and rarest ones, with us You can order them directly or request a mechanic to install them for you. We can also guide you to the nearest branch for your convenience.',
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
