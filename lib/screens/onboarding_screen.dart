import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isNavigating = false;

  final List<String> _images = const [
    'assets/images/onboarding_talk_doctors.png',
    'assets/images/onboarding_care_secure.png',
    'assets/images/onboarding_appointments.png',
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _startAutoSlide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    for (final image in _images) {
      precacheImage(AssetImage(image), context);
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || _isNavigating) return;

      if (_currentPage < _images.length - 1) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _goToSignup();
      }
    });
  }

  void _goToSignup() {
    if (_isNavigating) return;

    _isNavigating = true;
    _autoSlideTimer?.cancel();

    Get.offNamed('/signup');
  }

  void _nextPage() {
    _autoSlideTimer?.cancel();

    if (_currentPage < _images.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
      );
      _startAutoSlide();
    } else {
      _goToSignup();
    }
  }

  void _skip() {
    _goToSignup();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;

                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.08)).clamp(0.92, 1.0);
                  }

                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  _images[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              );
            },
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1268F3),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1268F3).withOpacity(0.25),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _images.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 90),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE6EAF0),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Color(0xFF7B8794),
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE6EAF0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF1268F3),
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}