
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SidebarDrawer extends StatefulWidget {
  final VoidCallback onClose;

  const SidebarDrawer({Key? key, required this.onClose}) : super(key: key);

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _closeDrawer() async {
    await _animController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Stack(
          children: [
            // Overlay
            GestureDetector(
              onTap: _closeDrawer,
              child: Container(
                color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
              ),
            ),
            // Drawer
            Transform.translate(
              offset: Offset(screenWidth * 0.75 * _slideAnimation.value, 0),
              child: Container(
                width: screenWidth * 0.75,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(5, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(user),
                      // Menu Items
                      Expanded(child: _buildMenuList()),
                      // Footer
                      Container(height: 1, color: kBlueColor.withOpacity(0.1)),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(dynamic user) {
    final isDoctor = user?.role.toString() == 'UserRole.doctor';
    final initials = user != null
        ? '${user.firstName[0]}${user.lastName[0]}'
        : 'U';
    final avatarImage = profileImageProvider(user?.profileImage as String?);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff3B6FEC), Color(0xff2351C1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: avatarImage != null
                        ? Image(
                            image: avatarImage,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Guest',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDoctor
                        ? Icons.medical_services_rounded
                        : Icons.person_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDoctor ? 'Doctor' : 'Patient',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildMenuList() {
    final user = _authService.currentUser;
    final isDoctor = user?.role.toString() == 'UserRole.doctor';

    // Patient menu items
    final patientItems = <_MenuItem>[
      _MenuItem(Icons.home_rounded, 'Home', '/home'),
      _MenuItem(Icons.person_rounded, 'Profile', '/profile'),
      _MenuItem(Icons.calendar_today_rounded, 'Appointments', '/appointments'),
      _MenuItem(Icons.chat_bubble_rounded, 'Messages', '/chat'),
      _MenuItem(Icons.description_rounded, 'Prescriptions', '/prescriptions'),
      _MenuItem(Icons.favorite_rounded, 'Health Records', '/health-records'),
      _MenuItem(Icons.videocam_rounded, 'Consultations', '/consultations'),
      _MenuItem(Icons.star_rounded, 'Reviews', '/reviews'),
    ];

    // Doctor menu items
    final doctorItems = <_MenuItem>[
      _MenuItem(Icons.home_rounded, 'Dashboard', '/doctor-home'),
      _MenuItem(Icons.person_rounded, 'Profile', '/doctor-profile-edit'),
      _MenuItem(Icons.calendar_today_rounded, 'Schedule', '/doctor-schedule'),
      _MenuItem(
        Icons.event_note_rounded,
        'Appointments',
        '/doctor-appointments',
      ),
      _MenuItem(Icons.chat_bubble_rounded, 'Messages', '/chat'),
      _MenuItem(Icons.attach_money_rounded, 'Earnings', '/doctor-earnings'),
    ];

    final items = isDoctor ? doctorItems : patientItems;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCurrentRoute = Get.currentRoute == item.route;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 180 + (index * 65)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(-48 * (1 - value), 0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.92 + 0.08 * value,
                  alignment: Alignment.centerLeft,
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: GestureDetector(
              onTap: () async {
                await _closeDrawer();
                if (!isCurrentRoute) {
                  Get.toNamed(item.route);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isCurrentRoute ? kBlueColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isCurrentRoute
                            ? Colors.white.withOpacity(0.22)
                            : kBlueColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: isCurrentRoute ? Colors.white : kBlueColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isCurrentRoute
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrentRoute ? Colors.white : kTitleTextColor,
                        fontSize: 15,
                      ),
                    ),
                    if (isCurrentRoute) ...[
                      const Spacer(),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: GestureDetector(
          onTap: () async {
            await _closeDrawer();
            await _authService.logout();
            Get.offAllNamed('/login');
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBlueColor, Color(0xff2351C1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kBlueColor.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;

  _MenuItem(this.icon, this.label, this.route);
}
