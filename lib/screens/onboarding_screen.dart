import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OnboardingSlide {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isNavigating = false;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      imagePath: 'assets/images/onboarding_talk_doctors.png',
      title: 'Talk to Doctors\nAnytime',
      description:
          'Get trusted medical consultations from licensed professionals right on your phone, wherever you are.',
    ),
    OnboardingSlide(
      imagePath: 'assets/images/onboarding_book_appointments.png',
      title: 'Book Appointments\nEasily',
      description:
          'Choose your preferred doctor, select a convenient time, and schedule your consultation in just a few taps.',
    ),
    OnboardingSlide(
      imagePath: 'assets/images/onboarding_care_secure.png',
      title: 'Your Care,\nSafely Managed',
      description:
          'Access prescriptions, consultation history, and follow-up care securely in one convenient place.',
    ),
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

    for (final slide in _slides) {
      precacheImage(AssetImage(slide.imagePath), context);
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || _isNavigating) return;

      if (_currentPage < _slides.length - 1) {
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

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1268F3);
    const titleColor = Color(0xFF071B45);
    const bodyColor = Color(0xFF738099);

    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: topPadding + 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isActive = index == _currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isActive ? 14 : 10,
                height: isActive ? 14 : 10,
                decoration: BoxDecoration(
                  color: isActive ? blue : const Color(0xFFD9DCE1),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 6,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;

                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page ?? 0) - index;
                      value = (1 - value.abs() * 0.08).clamp(0.92, 1.0);
                    }

                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        slide.imagePath,
                        width: double.infinity,
                        height: size.height * 0.55,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(_currentPage),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: blue,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'KazHealth',
                          style: TextStyle(
                            color: blue,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Text(
                      _slides[_currentPage].title,
                      style: const TextStyle(
                        color: titleColor,
                        fontSize: 38,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _slides[_currentPage].description,
                      style: const TextStyle(
                        color: bodyColor,
                        fontSize: 17,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        'Redirecting...',
                        style: TextStyle(
                          color: bodyColor.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
