import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class AccountCreatedSuccessScreen extends StatelessWidget {
  const AccountCreatedSuccessScreen({super.key});

  void _continue(BuildContext context) {
    final args = Get.arguments;
    final isDoctor = args is Map && args['isDoctor'] == true;

    if (isDoctor) {
      Get.offAllNamed('/pending-approval');
      return;
    }

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final firstName = args is Map ? (args['firstName'] ?? '') as String : '';
    final greeting = firstName.isNotEmpty ? 'Welcome, $firstName!' : 'Welcome!';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                tween: Tween(begin: 0.3, end: 1),
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xffE9F7EE),
                    border: Border.all(
                      color: const Color(0xff72D497),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: Color(0xff1FA95A),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Account created successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTitleTextColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              Text(
                '$greeting Your registration flow is complete.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kSearchTextColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 120.ms, duration: 380.ms),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _continue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrangeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 220.ms, duration: 380.ms)
                  .slideY(begin: 0.12, end: 0),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
