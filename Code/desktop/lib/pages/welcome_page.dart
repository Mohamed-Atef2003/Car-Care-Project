import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../authentication/login_page.dart';
import 'package:car_care/theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  final List<String> _images = [
    'assets/image/Landing_Page_0.jpg',
    'assets/image/Landing_Page_1.jpg',
    'assets/image/Landing_Page_2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Automatically change page every 5 seconds
    Future.delayed(const Duration(seconds: 5), _autoChangePage);
  }

  void _autoChangePage() {
    if (_pageController.hasClients) {
      int nextPage = _pageController.page!.toInt() + 1;
      if (nextPage >= _images.length) {
        nextPage = 0;
      }
      _pageController
          .animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) =>
              Future.delayed(const Duration(seconds: 5), _autoChangePage));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _images[index],
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.textPrimary.withOpacity(0.3),
                          AppColors.textPrimary.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Page Indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _images.length,
                effect: const WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 8,
                  dotColor: Color(0xFFA3A3A3),
                  activeDotColor: Colors.white,
                ),
              ),
            ),
          ),
          // Lets Go Button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 200,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lets Go',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
