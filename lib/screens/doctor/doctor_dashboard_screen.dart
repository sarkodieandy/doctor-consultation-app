import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/controllers/notification_controller.dart';
import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class DoctorDashboardScreen extends StatefulWidget {
  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  late AppointmentController _appointmentController;
  late NotificationController _notificationController;
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
    _appointmentController = Get.find<AppointmentController>();
    if (Get.isRegistered<NotificationController>()) {
      _notificationController = Get.find<NotificationController>();
    } else {
      _notificationController = Get.put(NotificationController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appointmentController.fetchDoctorAppointments();
      _notificationController.fetchNotifications();
    });

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
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Full-screen transparent background watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/images/doctorbg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDoctorHeroHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 32),
                            // Stats Row with animations
                            Obx(() {
                              final appointments =
                                  _appointmentController.doctorAppointments;
                              final today = DateTime.now();
                              final todayAppointments = appointments
                                  .where((appointment) =>
                                      appointment.appointmentDate.year ==
                                          today.year &&
                                      appointment.appointmentDate.month ==
                                          today.month &&
                                      appointment.appointmentDate.day ==
                                          today.day)
                                  .length;
                              final pendingRequests = appointments
                                  .where((appointment) =>
                                      appointment.status == 'pending')
                                  .length;

                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildAnimatedStatCard(
                                      'Today\'s\nAppointments',
                                      '$todayAppointments',
                                      Icons.calendar_today,
                                      const Color(0xff64B5F6),
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: _buildAnimatedStatCard(
                                      'Pending\nRequests',
                                      '$pendingRequests',
                                      Icons.pending_actions,
                                      const Color(0xff81C784),
                                    ),
                                  ),
                                ],
                              );
                            })
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),
                            SizedBox(height: 36),

                            // Quick Actions with modern design
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kTitleTextColor,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 350.ms, duration: 400.ms)
                                .slideX(begin: -0.15, end: 0),
                            SizedBox(height: 16),
                            _buildQuickActionsGrid()
                                .animate()
                                .fadeIn(delay: 420.ms, duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),
                            SizedBox(height: 40),

                            // Consultation Summary Section
                            _buildConsultationSummary()
                                .animate()
                                .fadeIn(delay: 600.ms, duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),
                            SizedBox(height: 40),

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
                            ).animate().fadeIn(delay: 520.ms, duration: 400.ms),
                            SizedBox(height: 16),

                            Obx(() {
                              final upcomingAppointments =
                                  _appointmentController.doctorAppointments
                                      .where((appointment) =>
                                          appointment.status == 'pending' ||
                                          appointment.status == 'confirmed')
                                      .take(3)
                                      .toList();

                              if (upcomingAppointments.isEmpty) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No upcoming appointments',
                                      style: TextStyle(
                                        color: kTitleTextColor.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: upcomingAppointments
                                    .map(
                                      (appointment) =>
                                          _buildUpcomingAppointmentCard(
                                              appointment),
                                    )
                                    .toList(),
                              );
                            }),
                          ],
                        ),
                      ),
                      _buildBlueFooter(),
                    ],
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

  Widget _buildDoctorHeroHeader() {
    final user = _authService.currentUser;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xffE8F1FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.13,
              child: Image.asset(
                'assets/images/doctorbg.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isSidebarOpen = true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child:
                            Icon(Icons.menu, color: kTitleTextColor, size: 24),
                      ),
                    ),
                    Row(
                      children: [
                        Obx(() {
                          final unreadCount =
                              _notificationController.unreadCount.value;
                          return InkWell(
                            onTap: () => Get.toNamed('/notifications'),
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: kTitleTextColor,
                                    size: 24,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kBlueColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isOnline = !_isOnline);
                            _authService.toggleDoctorOnline(_isOnline);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isOnline ? Colors.green : Colors.grey,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor:
                                      _isOnline ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _isOnline ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Get.toNamed('/doctor-profile'),
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xffE8F1FF),
                              backgroundImage: _doctorProfileImageProvider(
                                  user?.profileImage),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Hello, Dr. ${user?.lastName ?? ''}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.specialty ?? 'Specialist',
                  style: TextStyle(
                    fontSize: 15,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFeaturedEarningsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object> _doctorProfileImageProvider(String? imagePath) {
    final trimmedPath = imagePath?.trim() ?? '';
    if (trimmedPath.isEmpty) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    if (trimmedPath.startsWith('assets/')) {
      return AssetImage(trimmedPath);
    }
    if (trimmedPath.toLowerCase().contains('.svg')) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    return const AssetImage(DoctorModel.fallbackImagePath);
  }

  Widget _buildAnimatedStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2351C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2351C1).withOpacity(0.30),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff22365a), Color(0xff16233f)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.14), width: 1),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2351C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2351C1).withOpacity(0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.24),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Earnings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'GHS 450',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated from completed consultations today',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(
          label: 'Appointments',
          subtitle: 'Check today\'s schedule',
          icon: Icons.calendar_month_outlined,
          color: const Color(0xff64B5F6),
          onTap: () => Get.toNamed('/doctor-appointments'),
        ),
        _buildQuickActionCard(
          label: 'Messages',
          subtitle: 'Respond to patient chats',
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xffA78BFA),
          onTap: () => Get.toNamed('/doctor-chat'),
        ),
        _buildQuickActionCard(
          label: 'Prescriptions',
          subtitle: 'Review refill requests',
          icon: Icons.medication_outlined,
          color: const Color(0xff81C784),
          onTap: () => Get.toNamed('/doctor-prescriptions'),
        ),
        _buildQuickActionCard(
          label: 'Profile',
          subtitle: 'Update availability and details',
          icon: Icons.person_outline_rounded,
          color: const Color(0xffFFB74D),
          onTap: () => Get.toNamed('/doctor-profile'),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff3B6FEC), Color(0xff2351C1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff2351C1).withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff22365a), Color(0xff16233f)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                border:
                    Border.all(color: Colors.white.withOpacity(0.14), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.78),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTitleTextColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: kBlueColor.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem('Total Patients', '142'),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.black.withOpacity(0.10),
                ),
                _buildSummaryItem('Completed', '89'),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.black.withOpacity(0.10),
                ),
                _buildSummaryItem('Rating', '4.8★'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff242424), Color(0xff090909)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black.withOpacity(0.14),
                width: 0.8,
              ),
            ),
            child: Icon(
              label == 'Total Patients'
                  ? Icons.group_outlined
                  : label == 'Completed'
                      ? Icons.check_circle_outline
                      : Icons.star_outline,
              color: const Color(0xff3B6FEC),
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff111111),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xffE8F1FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 48),
        child: Center(
          child: Text(
            'Your health, our priority',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: kTitleTextColor.withOpacity(0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xffE8F1FF),
            backgroundImage:
                _doctorProfileImageProvider(appointment.patientAvatar),
            child: appointment.patientAvatar.isEmpty
                ? const Icon(Icons.person, color: Color(0xff3B6FEC))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName.isNotEmpty
                      ? appointment.patientName
                      : 'Patient #${appointment.userId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xff1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.speciality} • ${appointment.timeSlot}',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            appointment.status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color:
                  appointment.status == 'pending' ? kOrangeColor : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
