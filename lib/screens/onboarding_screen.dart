import 'dart:async';

import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_talk_doctors.png',
      title: 'Care that starts with the right person',
      description:
          'Choose whether you are joining KazHealth to book care or to provide care, then move straight into the right registration path.',
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_book_appointments.png',
      title: 'Appointments, records, and follow-up in one place',
      description:
          'Patients can book quickly while doctors manage schedules, consultation flow, and verification from the same product language.',
    ),
    _OnboardingSlide(
      imagePath: 'assets/images/onboarding_care_secure.png',
      title: 'Built for trusted digital consultation',
      description:
          'Profiles, documents, and communication stay structured so both patients and providers can move with confidence.',
    ),
  ];

  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _didPrecacheSlides = false;
  String _selectedRole = 'patient';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _scheduleAutoSlide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheSlides) {
      return;
    }

    for (final slide in _slides) {
      precacheImage(AssetImage(slide.imagePath), context);
    }
    _didPrecacheSlides = true;
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _scheduleAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final nextPage = (_currentPage + 1) % _slides.length;
      _animateToPage(nextPage);
    });
  }

  void _animateToPage(int page, {bool isManual = false}) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: isManual ? 520 : 720),
      curve: isManual ? Curves.easeOutCubic : Curves.easeInOutCubicEmphasized,
    );
  }

  void _continueToSignup() {
    final arguments =
        _selectedRole == 'doctor' ? <String, dynamic>{'role': 'doctor'} : null;
    Get.offNamed('/signup', arguments: arguments);
  }

  void _openLogin() {
    Get.offNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _autoSlideTimer?.cancel();
                    }
                    if (notification is ScrollEndNotification) {
                      _scheduleAutoSlide();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    allowImplicitScrolling: true,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                      _scheduleAutoSlide();
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double distance = 0;
                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions) {
                            distance = (_pageController.page! - index).abs();
                          } else {
                            distance = (_currentPage - index).abs().toDouble();
                          }

                          final opacity = (1 - distance * 0.22).clamp(0.0, 1.0);
                          final scale = (1 - distance * 0.035).clamp(0.96, 1.0);

                          return Opacity(
                            opacity: opacity,
                            child: Transform.scale(scale: scale, child: child),
                          );
                        },
                        child: _buildSlideCard(slide),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildPageIndicators(),
              const SizedBox(height: 18),
              _buildRoleSelector(),
              const SizedBox(height: 16),
              _buildPrimaryButton(),
              const SizedBox(height: 10),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: kBlueColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.local_hospital_rounded, color: kWhiteColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KazHealth',
                style: TextStyle(
                  color: kTitleTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your entry path before you create an account.',
                style: TextStyle(
                  color: kSearchTextColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlideCard(_OnboardingSlide slide) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: kSearchBackgroundColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kSearchBackgroundColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Digital consultation platform',
                style: TextStyle(
                  color: kCategoryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              slide.title,
              style: TextStyle(
                color: kTitleTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slide.description,
              style: TextStyle(
                color: kSearchTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? kBlueColor : kSearchBackgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: Icons.person_outline_rounded,
            title: 'Patient',
            subtitle: 'Book visits, manage records, and follow up.',
            isSelected: _selectedRole == 'patient',
            onTap: () => setState(() => _selectedRole = 'patient'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon: Icons.medical_services_outlined,
            title: 'Doctor',
            subtitle: 'Complete verification and start consultations.',
            isSelected: _selectedRole == 'doctor',
            onTap: () => setState(() => _selectedRole = 'doctor'),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    final label = _selectedRole == 'doctor'
        ? 'Continue as Doctor'
        : 'Continue as Patient';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continueToSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlueColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _openLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: kTitleTextColor,
          side: BorderSide(color: kSearchBackgroundColor),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'I already have an account',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : kWhiteColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? kBlueColor : kSearchBackgroundColor,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? kBlueColor : kSearchBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : kCategoryTextColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: kTitleTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: kSearchTextColor,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
