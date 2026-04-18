import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
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
                      const Divider(height: 1),
                      // Menu Items
                      Expanded(
                        child: _buildMenuList(),
                      ),
                      // Footer
                      const Divider(height: 1),
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kBlueColor,
            child: Text(
              user != null ? '${user.firstName[0]}${user.lastName[0]}' : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kTitleTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    final items = <_MenuItem>[
      _MenuItem(Icons.home_rounded, 'Home', '/home'),
      _MenuItem(Icons.person_rounded, 'Profile', '/profile'),
      _MenuItem(Icons.calendar_today_rounded, 'Appointments', '/appointments'),
      _MenuItem(Icons.chat_bubble_rounded, 'Messages', '/chat'),
      _MenuItem(Icons.description_rounded, 'Prescriptions', '/prescriptions'),
      _MenuItem(Icons.favorite_rounded, 'Health Records', '/health-records'),
      _MenuItem(Icons.videocam_rounded, 'Consultations', '/consultations'),
      _MenuItem(Icons.star_rounded, 'Reviews', '/reviews'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCurrentRoute = Get.currentRoute == item.route;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 60)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(-30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrentRoute
                  ? kOrangeColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(
                item.icon,
                color: isCurrentRoute ? kOrangeColor : kTitleTextColor,
                size: 24,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight:
                      isCurrentRoute ? FontWeight.bold : FontWeight.w500,
                  color: isCurrentRoute ? kOrangeColor : kTitleTextColor,
                  fontSize: 15,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onTap: () async {
                await _closeDrawer();
                if (!isCurrentRoute) {
                  Get.toNamed(item.route);
                }
              },
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
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: MaterialButton(
            onPressed: () async {
              await _closeDrawer();
              await _authService.logout();
              Get.offAllNamed('/login');
            },
            color: kOrangeColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: kWhiteColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
