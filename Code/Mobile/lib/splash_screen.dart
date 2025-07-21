import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/preferences_service.dart';
import 'auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isFirstTime = await PreferencesService.isFirstTime();
    final isLoggedIn = await PreferencesService.isLoggedIn(); // Assume you have a function to check login status

    if (isFirstTime) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    } else if (isLoggedIn) {
      // Load user data before navigating to the home screen
      await Provider.of<UserProvider>(context, listen: false).loadUser();
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/car-maintenance.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            const Text(
              'Car Care',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
