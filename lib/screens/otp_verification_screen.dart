import 'dart:async';

import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;

  String get _otpCode =>
      _controllers.map((controller) => controller.text).join();

  bool get _isComplete => _otpCode.length == 6;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete || _isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    final args = Get.arguments;
    final isDoctor = args is Map ? args['isDoctor'] == true : false;
    final firstName = args is Map ? (args['firstName'] ?? '') as String : '';

    if (!mounted) {
      return;
    }

    Get.offNamed(
      '/account-created-success',
      arguments: {
        'isDoctor': isDoctor,
        'firstName': firstName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final phone = args is Map
        ? (args['phone'] ?? 'your number') as String
        : 'your number';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _isVerifying ? null : () => Get.back(),
                icon: const Icon(Icons.arrow_back_rounded),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Text(
                'Verify your account',
                style: TextStyle(
                  color: kTitleTextColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit OTP sent to $phone. This is a UI simulation for now.',
                style: TextStyle(
                  color: kSearchTextColor,
                  fontSize: 14,
                  height: 1.35,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
              const SizedBox(height: 28),
              Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        enabled: !_isVerifying,
                        style: TextStyle(
                          color: kTitleTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xffEEF2FF),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xffD0D7F5),
                              width: 1.4,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: kBlueColor,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffEAF1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Demo OTP: 274913',
                  style: TextStyle(
                    color: kBlueColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isComplete && !_isVerifying ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrangeColor,
                    disabledBackgroundColor: const Color(0xffF4C8B2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 350.ms)
                  .slideY(begin: 0.12, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
