import 'package:doctor_consultation_app/components/category_card.dart';
import 'package:doctor_consultation_app/components/search_bar.dart'
    as custom_search;
import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/controllers/care_timeline_controller.dart';
import 'package:doctor_consultation_app/controllers/notification_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/screens/detail_screen.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  late AppointmentController _controller;
  late CareTimelineController _careTimelineController;
  late NotificationController _notificationController;
  bool _isSidebarOpen = false;
  String? _selectedCategory;
  String _selectedRegion = patientRegions.first;
  String _selectedLanguage = patientLanguages.first;
  String _selectedMode = patientConsultationModes.first;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AppointmentController>();
    if (Get.isRegistered<CareTimelineController>()) {
      _careTimelineController = Get.find<CareTimelineController>();
    } else {
      _careTimelineController = Get.put(CareTimelineController());
    }
    if (Get.isRegistered<NotificationController>()) {
      _notificationController = Get.find<NotificationController>();
    } else {
      _notificationController = Get.put(NotificationController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchDoctors();
      _careTimelineController.fetchTimeline();
      _notificationController.fetchNotifications();
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _controller.fetchDoctors();
    } else {
      _controller.searchDoctors(query);
    }
  }

  void _onSearchClear() {
    _controller.fetchDoctors();
  }

  bool _matchesFilters(DoctorModel doctor) {
    final meta = patientDoctorMetaFor(doctor);

    final matchesRegion = _selectedRegion == patientRegions.first ||
        meta.region == _selectedRegion;
    final matchesLanguage = _selectedLanguage == patientLanguages.first ||
        meta.languages.contains(_selectedLanguage);
    final matchesMode = _selectedMode == patientConsultationModes.first ||
        meta.consultationModes.contains(_selectedMode);

    return matchesRegion && matchesLanguage && matchesMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Animated, more visible doctor background
          Positioned.fill(
            child: Image.asset(
              'assets/images/doctorbg.png',
              fit: BoxFit.cover,
            )
                .animate()
                .fadeIn(duration: 1200.ms)
                .scale(
                    begin: const Offset(1.05, 1.05),
                    end: Offset(1, 1),
                    duration: 2200.ms)
                .shimmer(
                    delay: 400.ms,
                    duration: 1800.ms,
                    color: Colors.white.withOpacity(0.12)),
          ),
          // Semi-transparent overlay for better contrast
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 20),
                  _buildCareSnapshot()
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 450.ms),
                  const SizedBox(height: 20),
                  buildQuickAccessFeatures()
                      .animate()
                      .fadeIn(delay: 220.ms, duration: 450.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Categories')
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 380.ms)
                      .slideX(begin: -0.15, end: 0),
                  const SizedBox(height: 14),
                  buildCategoryList()
                      .animate()
                      .fadeIn(delay: 320.ms, duration: 420.ms)
                      .slideX(begin: 0.15, end: 0),
                  const SizedBox(height: 14),
                  _buildFilterGroup(
                    'Consultation Mode',
                    patientConsultationModes,
                    _selectedMode,
                    (value) {
                      setState(() {
                        _selectedMode = value;
                      });
                    },
                  ).animate().fadeIn(delay: 380.ms, duration: 380.ms),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Active Doctors')
                      .animate()
                      .fadeIn(delay: 440.ms, duration: 380.ms)
                      .slideX(begin: -0.15, end: 0),
                  const SizedBox(height: 16),
                  buildDoctorList()
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 420.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
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

  Widget _buildHeroHeader() {
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
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildTopBar(),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Find Your Care Team',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: kTitleTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Browse licensed doctors, review your next care step, and keep follow-ups organised in one place.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: kTitleTextColor.withOpacity(0.62),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: custom_search.SearchBar(
                    onSearch: _onSearch,
                    onClear: _onSearchClear,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isSidebarOpen = true;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kTitleTextColor.withOpacity(0.08)),
              ),
              child: Icon(Icons.menu_rounded, color: kTitleTextColor),
            ),
          ),
          const Spacer(),
          Obx(() {
            final unreadCount = _notificationController.unreadCount.value;
            return Row(
              children: [
                InkWell(
                  onTap: () => Get.toNamed('/notifications'),
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kTitleTextColor.withOpacity(0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: kTitleTextColor,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kBlueColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: TextStyle(
                                color: kWhiteColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildPatientAvatarButton(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPatientAvatarButton() {
    final user = _authService.currentUser;
    final avatarImage = profileImageProvider(user?.profileImage);

    return InkWell(
      onTap: () => Get.toNamed('/profile')?.then((_) {
        if (mounted) {
          setState(() {});
        }
      }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kTitleTextColor.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: avatarImage == null
              ? ColoredBox(
                  color: kBlueColor.withValues(alpha: 0.10),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: kBlueColor,
                  ),
                )
              : Image(
                  image: avatarImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return ColoredBox(
                      color: kBlueColor.withValues(alpha: 0.10),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: kBlueColor,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: kTitleTextColor,
          fontSize: 18,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCareBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBlueColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kWhiteColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Patient Care Hub',
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Complete your care journey in one place',
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Consult, review prescriptions, prepare records, and keep follow-up details ready before your appointment.',
              style: TextStyle(
                color: kWhiteColor.withOpacity(0.88),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHighlights() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = patientHomeHighlights[index];
          return Container(
            width: 248,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        item.imageUrl,
                        width: double.infinity,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.02),
                                Colors.black.withOpacity(0.28),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, color: item.color, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                item.eyebrow,
                                style: TextStyle(
                                  color: kTitleTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTitleTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: kTitleTextColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: patientHomeHighlights.length,
      ),
    );
  }

  Widget _buildCareSnapshot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Obx(() {
        final items = _careTimelineController.items;
        final nextItem = _careTimelineController.nextUpcomingItem;
        final unreadUpdates =
            items.where((item) => item.statusLabel == 'NEW').length;
        final prescriptionsDue = items
            .where((item) =>
                item.type == 'prescription' || item.type == 'medication')
            .length;

        final upcomingCount = items
            .where((item) => item.timestamp.isAfter(DateTime.now()))
            .length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xff3B6FEC),
                const Color(0xff2E5ED2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xff2A56C3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Care Snapshot',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: kWhiteColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$upcomingCount upcoming',
                      style: TextStyle(
                        color: kBlueColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                nextItem == null
                    ? 'No urgent step pending. Keep monitoring your timeline and stay ready for your next consultation.'
                    : 'Next step: ${nextItem.title}',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: kWhiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (nextItem != null) ...[
                const SizedBox(height: 6),
                Text(
                  nextItem.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: kWhiteColor.withOpacity(0.9),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSnapshotStat('Upcoming', '$upcomingCount', kBlueColor),
                  _buildSnapshotStat('Updates', '$unreadUpdates', kOrangeColor),
                  _buildSnapshotStat('Meds', '$prescriptionsDue', kYellowColor),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/care-timeline'),
                  icon: const Icon(Icons.timeline, size: 18),
                  label: const Text('Open Care Timeline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kWhiteColor,
                    side: BorderSide(color: kWhiteColor.withOpacity(0.7)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSnapshotStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: kWhiteColor,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kWhiteColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _onCategoryTap(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        _controller.fetchDoctors();
      } else {
        _selectedCategory = category;
        _controller.fetchDoctorsBySpecialty(category);
      }
    });
  }

  Widget buildCategoryList() {
    final categories = [
      {
        'title': 'Dental\nSurgeon',
        'icon': 'assets/images/dental.jpeg',
        'color': kBlueColor,
        'specialty': 'Dental Surgeon'
      },
      {
        'title': 'Heart\nSurgeon',
        'icon': 'assets/images/heart surg.jpeg',
        'color': kYellowColor,
        'specialty': 'Heart Surgeon'
      },
      {
        'title': 'Eye\nSpecialist',
        'icon': 'assets/images/eye.jpeg',
        'color': kOrangeColor,
        'specialty': 'Eye Specialist'
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 30),
          ...categories.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final specialty = cat['specialty'] as String;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CategoryCard(
                cat['title'] as String,
                cat['icon'] as String,
                cat['color'] as Color,
                isSelected: _selectedCategory == specialty,
                onTap: () => _onCategoryTap(specialty),
              )
                  .animate()
                  .fadeIn(delay: (120 + (index * 70)).ms, duration: 320.ms)
                  .slideX(begin: 0.15, end: 0),
            );
          }),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildFilterGroup(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTitleTextColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selected;
                return GestureDetector(
                  onTap: () => onSelected(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? kBlueColor : kWhiteColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? kBlueColor
                            : kTitleTextColor.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? kWhiteColor : kTitleTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCarePrograms() {
    return SizedBox(
      height: 285,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        scrollDirection: Axis.horizontal,
        itemCount: patientCarePrograms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final program = patientCarePrograms[index];
          return Container(
            width: 228,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: program.color.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Image.asset(
                    program.imageUrl,
                    width: double.infinity,
                    height: 108,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: program.color.withOpacity(0.12),
                            child: Icon(program.icon, color: program.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              program.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: kTitleTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        program.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: kTitleTextColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: MaterialButton(
                          onPressed: () {
                            Get.toNamed('/care-timeline');
                          },
                          color: kBlueColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            program.actionLabel,
                            style: TextStyle(
                              color: kWhiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEmergencyStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency symptoms should go to urgent care',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chest pain, breathing trouble, or heavy bleeding should not wait for a remote consult.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: kTitleTextColor.withOpacity(0.65),
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

  Widget buildQuickAccessFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.75,
            children: [
              _buildFeatureCard(
                'Symptom Checker',
                Icons.health_and_safety,
                'AI triage and next step',
                () => Get.toNamed('/symptom-checker'),
                0,
              ),
              _buildFeatureCard(
                'Services',
                Icons.local_hospital,
                'Doctor, pharmacy and care',
                () => Get.toNamed('/service-selection'),
                1,
              ),
              _buildFeatureCard(
                'Find Doctor',
                Icons.manage_search,
                'Browse and filter doctors',
                () => Get.toNamed('/doctor-selection'),
                2,
              ),
              _buildFeatureCard(
                'Track Doctor',
                Icons.route,
                'Live visit tracking',
                () => Get.toNamed('/track-doctor'),
                3,
              ),
              _buildFeatureCard(
                'Appointments',
                Icons.calendar_today,
                'Bookings and schedules',
                () => Get.toNamed('/appointments'),
                4,
              ),
              _buildFeatureCard(
                'Prescriptions',
                Icons.description,
                'Medication and reminders',
                () => Get.toNamed('/prescriptions'),
                5,
              ),
              _buildFeatureCard(
                'Visit Summary',
                Icons.summarize,
                'Post-consultation notes',
                () => Get.toNamed('/consultation-summary'),
                6,
              ),
              _buildFeatureCard(
                'Settings',
                Icons.settings,
                'App preferences',
                () => Get.toNamed('/settings'),
                7,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      String label, IconData icon, String subtitle, VoidCallback onTap,
      [int motionIndex = 0]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kTitleTextColor.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 78;
            final iconBox = isCompact ? 28.0 : 34.0;
            final iconSize = isCompact ? 16.0 : 18.0;
            final titleSize = isCompact ? 11.0 : 12.0;
            final subtitleSize = isCompact ? 9.0 : 10.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 12,
                vertical: isCompact ? 8 : 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: kBlueColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: kWhiteColor, size: iconSize),
                  ),
                  SizedBox(height: isCompact ? 6 : 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                      color: kTitleTextColor,
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: kTitleTextColor.withOpacity(0.55),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (90 + (motionIndex * 70)).ms, duration: 320.ms)
        .slideY(begin: 0.12, end: 0)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }

  Widget buildDoctorList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final filteredDoctors =
          _controller.doctors.where(_matchesFilters).toList();

      final activeDoctors =
          filteredDoctors.where((doctor) => doctor.available).toList();
      final displayedDoctors =
          activeDoctors.isNotEmpty ? activeDoctors : filteredDoctors;

      if (filteredDoctors.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: kBlueColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'No active doctors match this view.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try changing consultation mode or search for a specialty.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: displayedDoctors
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _buildDoctorCard(entry.value)
                      .animate()
                      .fadeIn(
                        delay: (140 + (entry.key * 80)).ms,
                        duration: 340.ms,
                      )
                      .slideY(begin: 0.14, end: 0),
                ),
              )
              .toList(),
        ),
      );
    });
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    final meta = patientDoctorMetaFor(doctor);

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kTitleTextColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: doctor.imageProvider,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kTitleTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doctor.specialty} • ${meta.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: kTitleTextColor.withOpacity(0.68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: doctor.available
                                  ? kBlueColor
                                  : Colors.grey[600],
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: doctor.available
                                    ? const Color(0xff1F4FCC)
                                    : Colors.grey[700]!,
                              ),
                            ),
                            child: Text(
                              doctor.available ? 'Active Now' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: kOrangeColor,
                              borderRadius: BorderRadius.circular(13),
                              border:
                                  Border.all(color: const Color(0xffD75E59)),
                            ),
                            child: Text(
                              'GHS ${doctor.consultationFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildMiniStat(Icons.star, '${doctor.rating}', kYellowColor),
                  _buildMiniStat(
                    Icons.people_outline,
                    '${doctor.reviewCount} reviews',
                    kTitleTextColor,
                  ),
                  _buildMiniStat(
                    Icons.access_time,
                    meta.nextAvailable,
                    kBlueColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildStraightMetaRow(
              Icons.translate,
              meta.languages.join(' • '),
            ),
            const SizedBox(height: 8),
            _buildStraightMetaRow(
              Icons.chat_outlined,
              meta.consultationModes.join(' • '),
            ),
            const SizedBox(height: 8),
            _buildStraightMetaRow(
              Icons.local_hospital_outlined,
              doctor.hospital,
            ),
            const SizedBox(height: 8),
            Text(
              meta.responseTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: kTitleTextColor.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      Get.toNamed('/booking', arguments: doctor);
                    },
                    color: kBlueColor,
                    elevation: 0,
                    height: 44,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Book Appointment',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.to(() => DetailScreen(doctor: doctor));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: kBlueColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: kBlueColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      'View Details',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kBlueColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: kTitleTextColor.withOpacity(0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStraightMetaRow(IconData icon, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: kBlueColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: kTitleTextColor.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
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
