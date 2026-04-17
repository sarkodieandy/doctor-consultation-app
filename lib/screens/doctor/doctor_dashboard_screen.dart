import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorDashboardScreen extends StatefulWidget {
  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _authService = AuthService();
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _isOnline = _authService.currentUser?.isOnline ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // Header with greeting and online toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Dr. ${user?.lastName ?? ''}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kTitleTextColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          user?.specialty ?? 'Specialist',
                          style: TextStyle(
                            fontSize: 14,
                            color: kTitleTextColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    // Online/Offline toggle
                    Column(
                      children: [
                        Switch(
                          value: _isOnline,
                          onChanged: (value) {
                            setState(() {
                              _isOnline = value;
                            });
                            _authService.toggleDoctorOnline(value);
                          },
                          activeColor: Colors.green,
                        ),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Today\'s\nAppointments',
                        '8',
                        Icons.calendar_today,
                        kBlueColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Pending\nRequests',
                        '3',
                        Icons.pending_actions,
                        kOrangeColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Today\'s\nEarnings',
                        'GHS 450',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'My Schedule',
                        Icons.schedule,
                        kBlueColor,
                        () => Get.toNamed('/doctor-schedule'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Appointments',
                        Icons.assignment,
                        kOrangeColor,
                        () => Get.toNamed('/doctor-appointments'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Earnings',
                        Icons.monetization_on,
                        Colors.green,
                        () => Get.toNamed('/doctor-earnings'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Edit Profile',
                        Icons.person_outline,
                        Colors.purple,
                        () => Get.toNamed('/doctor-profile-edit'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Upcoming Appointments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Appointments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed('/doctor-appointments'),
                      child: Text(
                        'See All',
                        style: TextStyle(color: kBlueColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Mock appointments
                _buildAppointmentCard(
                  'Kwame Mensah',
                  '10:00 AM - 10:30 AM',
                  'General Checkup',
                  'Confirmed',
                  Colors.green,
                ),
                SizedBox(height: 10),
                _buildAppointmentCard(
                  'Ama Serwaa',
                  '11:00 AM - 11:30 AM',
                  'Follow-up Visit',
                  'Pending',
                  kOrangeColor,
                ),
                SizedBox(height: 10),
                _buildAppointmentCard(
                  'Kofi Asante',
                  '2:00 PM - 2:30 PM',
                  'Consultation',
                  'Confirmed',
                  Colors.green,
                ),
                SizedBox(height: 24),

                // Recent Patients
                Text(
                  'Recent Patients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPatientAvatar('KM', 'Kwame'),
                      _buildPatientAvatar('AS', 'Ama'),
                      _buildPatientAvatar('KA', 'Kofi'),
                      _buildPatientAvatar('YB', 'Yaa'),
                      _buildPatientAvatar('EA', 'Esi'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBlueColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Get.toNamed('/doctor-appointments');
              break;
            case 2:
              Get.toNamed('/doctor-schedule');
              break;
            case 3:
              Get.toNamed('/doctor-profile-edit');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: kTitleTextColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kTitleTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    String patientName,
    String time,
    String type,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kBlueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: kBlueColor, size: 24),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$time • $type',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAvatar(String initials, String name) {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kBlueColor.withOpacity(0.1),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kBlueColor,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: kTitleTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
