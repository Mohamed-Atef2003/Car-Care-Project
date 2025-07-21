import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BaseAuthPage extends StatefulWidget {
  final List<String> images;
  final Widget child;

  const BaseAuthPage({
    super.key,
    required this.images,
    required this.child,
  });

  @override
  State<BaseAuthPage> createState() => _BaseAuthPageState();
}

class _BaseAuthPageState extends State<BaseAuthPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.images.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate flex values for 34.27% : 65.73% ratio
    // For better precision, multiply by 100
    const int totalFlex = 10000;
    const int leftFlex = 3427; // 34.27% of total
    const int rightFlex = totalFlex - leftFlex; // 65.73% of total

    return Scaffold(
      body: Row(
        children: [
          // Left side - Image section
          Expanded(
            flex: leftFlex,
            child: Container(
              color: Colors.grey[300],
              child: Stack(
                children: [
                  // Page View
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image
                          Image.asset(
                            widget.images[index],
                            fit: BoxFit.cover,
                          ),
                          // Dark overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(77), // 0.3 opacity
                                  Colors.black.withAlpha(128), // 0.5 opacity
                                ],
                              ),
                            ),
                          ),
                          // Car Care Text
                          Positioned(
                            top: 50,
                            left: 50,
                            child: Text(
                              'Car Care',
                              style: TextStyle(
                                fontSize: 50,
                                fontFamily: 'MacondoSwashCaps',
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Page Indicator
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: widget.images.length,
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
                ],
              ),
            ),
          ),
          // Right side - Content
          Expanded(
            flex: rightFlex,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 640,
                    maxHeight: 649,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: widget.child,
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
