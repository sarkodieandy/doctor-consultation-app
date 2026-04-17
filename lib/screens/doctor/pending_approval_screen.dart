import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PendingApprovalScreen extends StatelessWidget {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isRejected = user?.isDoctorRejected ?? false;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isRejected
                      ? Color(0xffFF6B6B).withOpacity(0.1)
                      : kBlueColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
                  size: 60,
                  color: isRejected ? Color(0xffFF6B6B) : kBlueColor,
                ),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                isRejected ? 'Application Rejected' : 'Under Review',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 16),

              // Description
              Text(
                isRejected
                    ? 'Unfortunately, your application has been rejected.'
                    : 'Your doctor account is currently being reviewed by our admin team. You will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: kTitleTextColor.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              // Rejection reason
              if (isRejected && user?.approvalNote != null) ...[
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xffFF6B6B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xffFF6B6B).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xffFF6B6B),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        user!.approvalNote!,
                        style: TextStyle(
                          fontSize: 13,
                          color: kTitleTextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16),

              // Application details
              if (!isRejected)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBlueColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Name', user?.fullName ?? ''),
                      _buildDetailRow('Specialty', user?.specialty ?? ''),
                      _buildDetailRow('Experience', user?.experience ?? ''),
                      _buildDetailRow('Status', 'Pending Review'),
                    ],
                  ),
                ),

              SizedBox(height: 40),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    _authService.logout();
                    Get.offAllNamed('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kBlueColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: kBlueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: kTitleTextColor.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
