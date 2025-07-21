import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import '../../constants/colors.dart';
import '../../services/preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      image: 'assets/image/Splash1.png',
      title: 'Car Care',
      description: 'Welcome to the world of Car Care\nWe\'re everywhere and ready to reach you anytime, anywhere. We provide the best solutions to rescue, repair, clean, and inspect your car. 🚗✨',
    ),
    OnboardingItem(
      image: 'assets/image/Splash2.png',
      title: 'Car Care',
      description: 'You can find all spare parts, including the best and rarest ones, with us You can order them directly or request a mechanic to install them for you. We can also guide you to the nearest branch for your convenience.',
    ),
    OnboardingItem(
      image: 'assets/image/well-done-gif-17.gif',
      title: 'Car Care',
      description: 'We take pride in offering services and products you can trust, ensuring the highest standards of quality in everything we provide. Our team of skilled and experienced mechanics is dedicated to delivering the best experience for you. Your feedback and service evaluation mean the world to us, helping us improve and meet your expectations perfectly.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() async {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await PreferencesService.setFirstTimeCompleted();
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _onSkipPressed() async {
    await PreferencesService.setFirstTimeCompleted();
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _onSkipPressed,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(item: _items[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage == _items.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lets GO',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    FloatingActionButton(
                      onPressed: _onNextPressed,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const _OnboardingPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.image,
            height: 200,
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
