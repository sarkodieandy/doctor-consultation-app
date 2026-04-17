import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorEarningsScreen extends StatelessWidget {
  // Mock earnings data
  final double totalEarnings = 12500.00;
  final double thisMonthEarnings = 3200.00;
  final double pendingPayout = 850.00;

  final List<Map<String, dynamic>> transactions = [
    {
      'patient': 'Kwame Mensah',
      'amount': 150.00,
      'date': 'Today, 10:30 AM',
      'type': 'Consultation',
      'status': 'completed',
    },
    {
      'patient': 'Ama Serwaa',
      'amount': 200.00,
      'date': 'Today, 11:30 AM',
      'type': 'Follow-up',
      'status': 'completed',
    },
    {
      'patient': 'Kofi Asante',
      'amount': 150.00,
      'date': 'Yesterday, 2:30 PM',
      'type': 'Consultation',
      'status': 'pending',
    },
    {
      'patient': 'Yaa Boateng',
      'amount': 300.00,
      'date': 'Apr 14, 9:00 AM',
      'type': 'Full Checkup',
      'status': 'completed',
    },
    {
      'patient': 'Esi Ampofo',
      'amount': 150.00,
      'date': 'Apr 13, 3:00 PM',
      'type': 'Consultation',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kTitleTextColor),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Summary
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBlueColor, kBlueColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: TextStyle(
                        color: kWhiteColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'GHS ${totalEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'This Month',
                            'GHS ${thisMonthEarnings.toStringAsFixed(2)}',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: kWhiteColor.withOpacity(0.3),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Pending',
                            'GHS ${pendingPayout.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Quick stats
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStat(
                      'Consultations',
                      '48',
                      Icons.medical_services_outlined,
                      kBlueColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStat(
                      'Avg Rating',
                      '4.8',
                      Icons.star_outline,
                      kYellowColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStat(
                      'Patients',
                      '35',
                      Icons.people_outline,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Transaction History
              Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 16),

              ...transactions.map((tx) => _buildTransactionCard(tx)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: kWhiteColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: kWhiteColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: kTitleTextColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final isPending = tx['status'] == 'pending';
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPending
                  ? kOrangeColor.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPending ? Icons.pending : Icons.check_circle,
              color: isPending ? kOrangeColor : Colors.green,
              size: 22,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['patient'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${tx['type']} • ${tx['date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTitleTextColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'GHS ${(tx['amount'] as double).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
