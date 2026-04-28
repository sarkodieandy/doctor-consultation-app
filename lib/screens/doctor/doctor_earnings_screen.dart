import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorEarningsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Earnings',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: kBlueColor.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No Earnings Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Earnings data will appear here after your first completed consultation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
