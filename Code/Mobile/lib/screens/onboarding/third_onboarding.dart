import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class ThirdOnboardingScreen extends StatelessWidget {
  const ThirdOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/image/well-done-gif-17.gif',
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
            'We take pride in offering services and products you can trust, ensuring the highest standards of quality in everything we provide. Our team of skilled and experienced mechanics is dedicated to delivering the best experience for you. Your feedback and service evaluation mean the world to us, helping us improve and meet your expectations perfectly.',
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
