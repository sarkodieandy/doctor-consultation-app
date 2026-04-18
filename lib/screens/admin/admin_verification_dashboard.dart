/// Admin Verification Dashboard
/// Platform admin dashboard to review, approve, or reject doctor registrations
/// Shows automated verification results and allows manual override

import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/document_verification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminVerificationDashboard extends StatefulWidget {
  @override
  State<AdminVerificationDashboard> createState() =>
      _AdminVerificationDashboardState();
}

class _AdminVerificationDashboardState
    extends State<AdminVerificationDashboard> {
  final _verificationService = DocumentVerificationService();

  late Future<Map<String, dynamic>> verificationReport;

  @override
  void initState() {
    super.initState();
    verificationReport = _verificationService.getVerificationReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBlueColor,
        elevation: 0,
        title: Text(
          'Doctor Verification Dashboard',
          style: TextStyle(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Stats
            _buildVerificationStats(),
            SizedBox(height: 30),

            // Tabs: Pending Review, Approved, Rejected
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: kBlueColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: kBlueColor,
                    tabs: [
                      Tab(text: 'Pending Review'),
                      Tab(text: 'Approved'),
                      Tab(text: 'Rejected'),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildPendingReviewTab(),
                        _buildApprovedTab(),
                        _buildRejectedTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: verificationReport,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: kBlueColor));
        }

        final report = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total Doctors',
                  '${report['total_doctors'] ?? 0}',
                  Colors.blue,
                  Icons.people,
                ),
                _buildStatCard(
                  'Auto-Approved',
                  '${report['automated_approvals'] ?? 0}',
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatCard(
                  'Manual Review',
                  '${report['pending'] ?? 0}',
                  Colors.orange,
                  Icons.pending_actions,
                ),
                _buildStatCard(
                  'Rejected',
                  '${report['rejected'] ?? 0}',
                  Colors.red,
                  Icons.cancel,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _verificationService.getPendingReviewDoctors(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: kBlueColor));
        }

        final doctors = snapshot.data!;
        if (doctors.isEmpty) {
          return Center(
            child: Text(
              'No doctors pending review',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return _buildDoctorReviewCard(doctor);
          },
        );
      },
    );
  }

  Widget _buildApprovedTab() {
    return Center(
      child: Text(
        'View approved doctors in Platform Admin Web',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildRejectedTab() {
    return Center(
      child: Text(
        'View rejected doctors in Platform Admin Web',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildDoctorReviewCard(Map<String, dynamic> doctor) {
    final doctorName = '${doctor['first_name']} ${doctor['last_name']}';
    final specialty = doctor['specialty'] ?? 'N/A';
    final verification = doctor['doctor_verifications'] is List
        ? (doctor['doctor_verifications'] as List).isNotEmpty
            ? (doctor['doctor_verifications'] as List)[0]
                as Map<String, dynamic>
            : null
        : null;

    final confidenceScore = verification?['confidence_score'] ?? 0.0;
    final licenseVerified = verification?['license_verified'] ?? false;
    final cardVerified = verification?['ghana_card_verified'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kBlueColor,
                child: Text(
                  '${doctor['first_name']?[0]}${doctor['last_name']?[0]}',
                  style: TextStyle(
                      color: kWhiteColor, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                      ),
                    ),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Verification Status
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verification Score',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                      ),
                    ),
                    Text(
                      '${(confidenceScore * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidenceScore,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidenceScore > 0.8 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildVerificationBadge(
                      'License',
                      licenseVerified,
                    ),
                    SizedBox(width: 8),
                    _buildVerificationBadge(
                      'Ghana Card',
                      cardVerified,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _approveDoctor(doctor['id']);
                  },
                  icon: Icon(Icons.check),
                  label: Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: kWhiteColor,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _rejectDoctor(doctor['id']);
                  },
                  icon: Icon(Icons.close),
                  label: Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: kWhiteColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(String label, bool verified) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: verified ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: verified ? Colors.green : Colors.red,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: verified ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _approveDoctor(String doctorId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').update({
        'approval_status': 'approved',
        'approval_note': 'Manually approved after verification review',
      }).eq('id', doctorId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Doctor approved!'), backgroundColor: Colors.green),
      );
      setState(() {
        verificationReport = _verificationService.getVerificationReport();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _rejectDoctor(String doctorId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').update({
        'approval_status': 'rejected',
        'approval_note': 'Rejected after verification review',
      }).eq('id', doctorId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Doctor rejected!'), backgroundColor: Colors.red),
      );
      setState(() {
        verificationReport = _verificationService.getVerificationReport();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
