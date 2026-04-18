import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorDashboardScreen extends StatefulWidget {
  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  bool _isOnline = false;
  bool _isSidebarOpen = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isOnline = _authService.currentUser?.isOnline ?? false;

    // Fade animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Slide animation
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),

                        // Header with menu and online toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isSidebarOpen = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kWhiteColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.menu,
                                  color: kTitleTextColor,
                                  size: 24,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isOnline = !_isOnline;
                                    });
                                    _authService.toggleDoctorOnline(_isOnline);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _isOnline
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 4,
                                          backgroundColor: _isOnline
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          _isOnline ? 'Online' : 'Offline',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _isOnline
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Greeting
                        Text(
                          'Hello, Dr. ${user?.lastName ?? ''}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: kTitleTextColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          user?.specialty ?? 'Specialist',
                          style: TextStyle(
                            fontSize: 15,
                            color: kTitleTextColor.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Stats Row with animations
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnimatedStatCard(
                                'Today\'s\nAppointments',
                                '8',
                                Icons.calendar_today,
                                kBlueColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAnimatedStatCard(
                                'Pending\nRequests',
                                '3',
                                Icons.pending_actions,
                                kOrangeColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAnimatedStatCard(
                                'Today\'s\nEarnings',
                                'GHS 450',
                                Icons.account_balance_wallet,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Quick Actions with modern design
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTitleTextColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildQuickActionsGrid(),
                        SizedBox(height: 30),

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
                              onPressed: () =>
                                  Get.toNamed('/doctor-appointments'),
                              child: Text(
                                'See All',
                                style: TextStyle(
                                  color: kBlueColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Appointment cards
                        _buildAppointmentCard(
                          'Kwame Mensah',
                          '10:00 AM - 10:30 AM',
                          'General Checkup',
                          'Confirmed',
                          Colors.green,
                        ),
                        SizedBox(height: 12),
                        _buildAppointmentCard(
                          'Ama Serwaa',
                          '11:00 AM - 11:30 AM',
                          'Follow-up Visit',
                          'Pending',
                          kOrangeColor,
                        ),
                        SizedBox(height: 12),
                        _buildAppointmentCard(
                          'Kofi Asante',
                          '2:00 PM - 2:30 PM',
                          'Consultation',
                          'Confirmed',
                          Colors.green,
                        ),
                        SizedBox(height: 30),

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
                              _buildPatientAvatar('KM', 'Kwame', kBlueColor),
                              _buildPatientAvatar('AS', 'Ama', kOrangeColor),
                              _buildPatientAvatar('KA', 'Kofi', kYellowColor),
                              _buildPatientAvatar('YB', 'Yaa', Colors.red),
                              _buildPatientAvatar('EA', 'Esi', Colors.purple),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sidebar
          if (_isSidebarOpen)
            SidebarDrawer(
              onClose: () {
                setState(() {
                  _isSidebarOpen = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          'My Schedule',
          Icons.schedule,
          kBlueColor,
          () => Get.toNamed('/doctor-schedule'),
        ),
        _buildActionCard(
          'Appointments',
          Icons.assignment,
          kOrangeColor,
          () => Get.toNamed('/doctor-appointments'),
        ),
        _buildActionCard(
          'Earnings',
          Icons.monetization_on,
          Colors.green,
          () => Get.toNamed('/doctor-earnings'),
        ),
        _buildActionCard(
          'Edit Profile',
          Icons.person_outline,
          Colors.purple,
          () => Get.toNamed('/doctor-profile-edit'),
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard(
      String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
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
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.person_outline,
              color: statusColor,
              size: 28,
            ),
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
                SizedBox(height: 6),
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1,
              ),
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

  Widget _buildPatientAvatar(String initials, String name, Color color) {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: kTitleTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
