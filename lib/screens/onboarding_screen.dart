import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/onboarding_illustration.png',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height / 6,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Connect To Care\nAcross Ghana',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: kTitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Find trusted doctors, prepare records before your visit, and keep prescriptions and follow-ups in one place.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: kTitleTextColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOnboardingPoint(
                      Icons.verified_user_outlined,
                      'Verified local specialists',
                    ),
                    const SizedBox(height: 12),
                    _buildOnboardingPoint(
                      Icons.translate,
                      'Choose care by region and language',
                    ),
                    const SizedBox(height: 12),
                    _buildOnboardingPoint(
                      Icons.medical_information_outlined,
                      'Keep records and prescriptions ready',
                    ),
                    const SizedBox(height: 28),
                    MaterialButton(
                      onPressed: () {
                        Get.offNamed('/home');
                      },
                      color: kOrangeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildOnboardingPoint(IconData icon, String text) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: kBlueColor.withOpacity(0.12),
          child: Icon(icon, color: kBlueColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTitleTextColor,
          ),
        ),
      ],
    );
  }
}
