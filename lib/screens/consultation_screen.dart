import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/consultation_controller.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ConsultationScreen extends StatefulWidget {
  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  late ConsultationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ConsultationController>();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          elevation: 0,
          title: Text(
            'Consultations',
            style: TextStyle(
              color: kTitleTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: kBlueColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kBlueColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUpcomingTab(),
            _buildCompletedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: kBlueColor),
        );
      }

      if (controller.upcomingConsultations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.videocam_off_outlined,
          title: 'No upcoming consultations',
          subtitle: 'Booked visits will appear here once scheduled.',
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _buildStatsBar(),
          const SizedBox(height: 16),
          ...controller.upcomingConsultations.map(
            (c) => _buildConsultationCard(c, isUpcoming: true),
          ),
        ],
      );
    });
  }

  Widget _buildCompletedTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: kBlueColor),
        );
      }

      if (controller.completedConsultations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.assignment_turned_in_outlined,
          title: 'No completed consultations',
          subtitle:
              'Past consultation summaries and follow-ups will appear here.',
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          ...controller.completedConsultations.map(
            (c) => _buildConsultationCard(c, isUpcoming: false),
          ),
        ],
      );
    });
  }

  // ── Stats bar (upcoming tab only) ─────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kBlueColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _stat('${controller.upcomingConsultations.length}', 'Upcoming'),
          _statDivider(),
          _stat('${controller.completedConsultations.length}', 'Completed'),
          _statDivider(),
          _stat('${controller.consultations.length}', 'Total'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 32,
        color: Colors.white30,
      );

  // ── Consultation card ──────────────────────────────────────────────────────
  Widget _buildConsultationCard(dynamic consultation,
      {required bool isUpcoming}) {
    final typeIcon = consultation.consultationType == 'audio'
        ? Icons.call_outlined
        : consultation.consultationType == 'text'
            ? Icons.chat_bubble_outline
            : Icons.videocam_outlined;

    return GestureDetector(
      onTap: () => Get.toNamed('/consultation-detail', arguments: consultation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header strip ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? const Color(0xffEAF1FF)
                    : Colors.green.withOpacity(0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _avatarProvider(consultation.doctorAvatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consultation.doctorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kTitleTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(typeIcon,
                                size: 13,
                                color: isUpcoming
                                    ? kBlueColor
                                    : Colors.green[700]),
                            const SizedBox(width: 4),
                            Text(
                              consultation.consultationType
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    isUpcoming ? kBlueColor : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? kBlueColor.withOpacity(0.12)
                          : Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUpcoming ? 'Upcoming' : 'Completed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUpcoming ? kBlueColor : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _metaChip(
                        Icons.calendar_today_outlined,
                        DateFormat('MMM dd, yyyy')
                            .format(consultation.scheduledTime),
                      ),
                      const SizedBox(width: 8),
                      _metaChip(
                        Icons.access_time_outlined,
                        DateFormat('hh:mm a')
                            .format(consultation.scheduledTime),
                      ),
                      const SizedBox(width: 8),
                      _metaChip(
                        Icons.timer_outlined,
                        '${consultation.duration.inMinutes} min',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Buttons ────────────────────────────────
                  if (isUpcoming)
                    Row(
                      children: [
                        Expanded(
                          child: _outlineBtn(
                            'Details',
                            Icons.info_outline,
                            () => Get.toNamed('/consultation-detail',
                                arguments: consultation),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _solidBtn(
                            'Join Now',
                            Icons.videocam_rounded,
                            () => Get.toNamed('/video-consultation',
                                arguments: consultation),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _outlineBtn(
                            'Summary',
                            Icons.description_outlined,
                            () => Get.toNamed('/consultation-detail',
                                arguments: consultation),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _solidBtn(
                            'Review',
                            Icons.star_outline_rounded,
                            () => Get.toNamed('/reviews'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: kBlueColor),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: kTitleTextColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _solidBtn(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlueColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _outlineBtn(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: kBlueColor,
          side: BorderSide(color: kBlueColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xffEAF1FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: kBlueColor),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: kTitleTextColor)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    height: 1.5,
                    fontSize: 13,
                    color: kTitleTextColor.withOpacity(0.55))),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object> _avatarProvider(String avatar) {
    if (avatar.trim().isEmpty) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    if (avatar.startsWith('assets/')) return AssetImage(avatar);
    if (avatar.toLowerCase().contains('.svg')) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    return const AssetImage(DoctorModel.fallbackImagePath);
  }
}

class ConsultationDetailScreen extends StatelessWidget {
  final controller = Get.find<ConsultationController>();

  @override
  Widget build(BuildContext context) {
    final consultation = Get.arguments;
    final isUpcoming =
        consultation.isUpcoming || consultation.status == 'scheduled';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Consultation Details',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Doctor card ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: kBlueColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    backgroundImage: _avatarProvider(consultation.doctorAvatar),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consultation.doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE, MMM dd · hh:mm a')
                              .format(consultation.scheduledTime),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUpcoming
                                ? Colors.greenAccent.withOpacity(0.25)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            consultation.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUpcoming
                                  ? Colors.greenAccent
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Info tiles ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoTile(
                    Icons.videocam_outlined,
                    'Type',
                    consultation.consultationType
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                  ),
                  _divider(),
                  _infoTile(
                    Icons.timer_outlined,
                    'Duration',
                    '${consultation.duration.inMinutes} minutes',
                  ),
                  if (consultation.roomId != null) ...[
                    _divider(),
                    _infoTile(
                      Icons.meeting_room_outlined,
                      'Room',
                      consultation.roomId!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Notes / Summary ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUpcoming ? 'Before you join' : 'Consultation Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kBlueColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isUpcoming
                        ? 'Have your medications, lab reports and a short symptom list ready. Use chat to send anything the doctor should know beforehand.'
                        : (consultation.summary?.isNotEmpty ?? false)
                            ? consultation.summary!
                            : 'No summary recorded yet.',
                    style: TextStyle(
                      height: 1.55,
                      fontSize: 13,
                      color: kTitleTextColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ───────────────────────────────
            if (isUpcoming) ...[
              _blueButton(
                label: 'Join Session',
                icon: Icons.videocam_rounded,
                onPressed: () =>
                    Get.toNamed('/video-consultation', arguments: consultation),
              ),
              const SizedBox(height: 10),
              _outlineButton(
                label: 'Open Chat',
                icon: Icons.chat_bubble_outline,
                onPressed: () => Get.toNamed('/chat'),
              ),
            ] else ...[
              _blueButton(
                label: 'Leave a Review',
                icon: Icons.star_outline_rounded,
                onPressed: () => Get.toNamed('/reviews'),
              ),
              const SizedBox(height: 10),
              _outlineButton(
                label: 'Download Recording',
                icon: Icons.download_outlined,
                onPressed: () => controller.downloadRecording(consultation.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: kBlueColor),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  color: kTitleTextColor.withOpacity(0.55), fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: kTitleTextColor)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _blueButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlueColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: kBlueColor,
          side: BorderSide(color: kBlueColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  ImageProvider<Object> _avatarProvider(String avatar) {
    if (avatar.trim().isEmpty) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    if (avatar.toLowerCase().contains('.svg')) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    return const AssetImage(DoctorModel.fallbackImagePath);
  }
}

class LegacyVideoConsultationScreen extends StatefulWidget {
  @override
  State<LegacyVideoConsultationScreen> createState() =>
      _LegacyVideoConsultationScreenState();
}

class _LegacyVideoConsultationScreenState
    extends State<LegacyVideoConsultationScreen> {
  late ConsultationController controller;
  bool isCameraOn = true;
  bool isMicOn = true;
  bool isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ConsultationController>();
    final consultation = Get.arguments;
    if (consultation != null) {
      controller.getConsultationDetails(consultation.id);
      controller.startConsultation(consultation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedConsultation.value ?? Get.arguments;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Container(
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _avatarProvider(selected?.doctorAvatar ?? ''),
                  ),
                  SizedBox(height: 20),
                  Text(
                    selected?.doctorName ?? 'Doctor',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Connected to your consultation session',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selected == null
                            ? '00:00'
                            : '${selected.duration.inMinutes}:00',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Live session',
                        style: TextStyle(color: kWhiteColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Use this screen to manage the live consultation. End the session when the visit is complete.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kWhiteColor, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _controlButton(
                          icon: isMicOn ? Icons.mic : Icons.mic_off,
                          active: isMicOn,
                          onTap: () => setState(() => isMicOn = !isMicOn),
                        ),
                        _controlButton(
                          icon:
                              isCameraOn ? Icons.videocam : Icons.videocam_off,
                          active: isCameraOn,
                          onTap: () => setState(() => isCameraOn = !isCameraOn),
                        ),
                        _controlButton(
                          icon:
                              isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          active: isSpeakerOn,
                          onTap: () =>
                              setState(() => isSpeakerOn = !isSpeakerOn),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (selected != null) {
                              await controller.endConsultation(
                                selected.id,
                                'Consultation ended. Review medications and follow up if symptoms continue.',
                              );
                            }
                            if (!mounted) {
                              return;
                            }
                            Get.offNamed('/consultations');
                          },
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.call_end, color: kWhiteColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: active ? Colors.white24 : Colors.white10,
        child: Icon(icon, color: kWhiteColor),
      ),
    );
  }

  ImageProvider<Object> _avatarProvider(String avatar) {
    if (avatar.trim().isEmpty) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    if (avatar.toLowerCase().contains('.svg')) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    return const AssetImage(DoctorModel.fallbackImagePath);
  }
}
