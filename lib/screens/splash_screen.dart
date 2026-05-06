import 'dart:async';

import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _doctorCarouselTimer;
  Timer? _navigationTimer;

  int _currentDoctorIndex = 0;
  final List<String> doctors = [
    'assets/images/doctor1.png',
    'assets/images/doctor2.png',
    'assets/images/doctor3.png',
  ];

  @override
  void initState() {
    super.initState();

    // Fade animation for logo
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Slide animation for text
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Scale animation for doctor images
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward().then((_) {
      _startDoctorCarousel();
    });
    _scaleController.forward();

    // Navigate after delay
    _navigateToNextScreen();
  }

  void _startDoctorCarousel() {
    _doctorCarouselTimer?.cancel();
    _doctorCarouselTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        _changeDoctorImage();
      }
    });
  }

  void _changeDoctorImage() {
    if (mounted) {
      setState(() {
        _currentDoctorIndex = (_currentDoctorIndex + 1) % doctors.length;
      });

      if (mounted) {
        _scaleController.forward(from: 0.0).then((_) {
          if (mounted) {
            _doctorCarouselTimer?.cancel();
            _doctorCarouselTimer =
                Timer(Duration(seconds: 2), _changeDoctorImage);
          }
        });
      }
    }
  }

  void _navigateToNextScreen() {
    _navigationTimer?.cancel();
    _navigationTimer = Timer(Duration(seconds: 4), () async {
      if (mounted) {
        final authService = AuthService();
        try {
          // Always restore persisted session first before deciding route.
          await authService.initSession().timeout(
                Duration(seconds: 5),
                onTimeout: () {},
              );
        } catch (_) {
          // Fall through to login when restore fails.
        }

        final user = authService.currentUser;
        if (user != null && user.isDoctor) {
          Get.offAllNamed('/doctor-home');
        } else if (user != null) {
          Get.offAllNamed('/home');
        } else {
          Get.offAllNamed('/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _doctorCarouselTimer?.cancel();
    _navigationTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kBlueColor.withOpacity(0.1),
              kOrangeColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBlueColor.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kOrangeColor.withOpacity(0.1),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated doctor image
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 250,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kBlueColor.withOpacity(0.2),
                              spreadRadius: 5,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            doctors[_currentDoctorIndex],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),

                    // Animated text and branding
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'HealthCare',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: kTitleTextColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Consult Doctors Anytime',
                            style: TextStyle(
                              fontSize: 14,
                              color: kBlueColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    // Animated tagline
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        decoration: BoxDecoration(
                          color: kOrangeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: kOrangeColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Your Health, Our Priority',
                          style: TextStyle(
                            fontSize: 13,
                            color: kOrangeColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),

                    // Loading indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(0),
                        SizedBox(width: 8),
                        _buildDot(1),
                        SizedBox(width: 8),
                        _buildDot(2),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer info
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Connecting Patients with Doctors',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kBlueColor,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kOrangeColor,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kYellowColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final opacity = (_fadeAnimation.value - (index * 0.15)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity > 0.3 ? opacity : 0.3,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBlueColor,
            ),
          ),
        );
      },
    );
  }
}
