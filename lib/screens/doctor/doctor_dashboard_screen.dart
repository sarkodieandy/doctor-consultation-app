import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/notification_controller.dart';
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
    if (Get.isRegistered<NotificationController>()) {
      _notificationController = Get.find<NotificationController>();
    } else {
      _notificationController = Get.put(NotificationController());
    }
    _notificationController.fetchNotifications();

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
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),
                            SizedBox(height: 30),

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
                            ).animate().fadeIn(delay: 520.ms, duration: 400.ms),
                            SizedBox(height: 12),

                            // Real appointments will load from Supabase
                            // (mock data removed for real testing)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No appointments yet',
                                  style: TextStyle(
                                    color: kTitleTextColor.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
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
                // Top row: menu + notification + online toggle
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
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
          color: color.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: kTitleTextColor.withOpacity(0.62),
            ),
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
      childAspectRatio: 0.95,
      children: [
        _buildQuickActionCard(
          label: 'Appointments',
          subtitle: 'Check today\'s schedule',
          icon: Icons.calendar_month_outlined,
          color: kBlueColor,
          onTap: () => Get.toNamed('/doctor-appointments'),
        ),
        _buildQuickActionCard(
          label: 'Messages',
          subtitle: 'Respond to patient chats',
          icon: Icons.chat_bubble_outline_rounded,
          color: kOrangeColor,
          onTap: () => Get.toNamed('/doctor-chat'),
        ),
        _buildQuickActionCard(
          label: 'Prescriptions',
          subtitle: 'Review refill requests',
          icon: Icons.medication_outlined,
          color: Colors.green,
          onTap: () => Get.toNamed('/doctor-prescriptions'),
        ),
        _buildQuickActionCard(
          label: 'Profile',
          subtitle: 'Update availability and details',
          icon: Icons.person_outline_rounded,
          color: Colors.deepPurple,
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: kTitleTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(36),
              ),
              child: Opacity(
                opacity: 0.13,
                child: Image.asset(
                  'assets/images/doctorbg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
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
        ],
      ),
    );
  }
}
