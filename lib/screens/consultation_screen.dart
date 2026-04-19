import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/consultation_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
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
            labelColor: kOrangeColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kOrangeColor,
            tabs: [
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
          child: CircularProgressIndicator(color: kOrangeColor),
        );
      }

      if (controller.upcomingConsultations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.videocam_off,
          title: 'No upcoming consultations',
          subtitle:
              'Booked visits that become consultations will appear here with join details and preparation steps.',
        );
      }

      return ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildOverviewCard(
            upcomingCount: controller.upcomingConsultations.length,
            completedCount: controller.completedConsultations.length,
          ),
          SizedBox(height: 16),
          _buildSupportCard(
            title: 'Before you join',
            items: patientConsultationPrepItems,
            icon: Icons.check_circle_outline,
            color: kBlueColor,
          ),
          SizedBox(height: 16),
          ...controller.upcomingConsultations.map((consultation) {
            return _buildConsultationCard(consultation, true);
          }).toList(),
        ],
      );
    });
  }

  Widget _buildCompletedTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: kOrangeColor),
        );
      }

      if (controller.completedConsultations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.assignment_turned_in_outlined,
          title: 'No completed consultations',
          subtitle:
              'After a consultation ends, its summary and follow-up information will appear here.',
        );
      }

      return ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSupportCard(
            title: 'After your visit',
            items: const [
              'Review your prescription and care summary.',
              'Send a follow-up message if dosage or timing is unclear.',
              'Leave a review to track care quality.',
            ],
            icon: Icons.assignment_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          ...controller.completedConsultations.map((consultation) {
            return _buildConsultationCard(consultation, false);
          }).toList(),
        ],
      );
    });
  }

  Widget _buildConsultationCard(dynamic consultation, bool isUpcoming) {
    final typeColor = _typeColor(consultation.consultationType);

    return GestureDetector(
      onTap: () {
        Get.toNamed('/consultation-detail', arguments: consultation);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? kBlueColor.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: _avatarProvider(consultation.doctorAvatar),
                  ),
                  SizedBox(width: 12),
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
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                consultation.consultationType == 'video'
                                    ? Icons.videocam
                                    : consultation.consultationType == 'audio'
                                        ? Icons.call
                                        : Icons.chat_bubble_outline,
                                size: 12,
                                color: typeColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                consultation.consultationType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isUpcoming ? kOrangeColor : Colors.green)
                          .withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUpcoming ? 'Upcoming' : 'Completed',
                      style: TextStyle(
                        fontSize: 11,
                        color: isUpcoming ? kOrangeColor : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date & Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy hh:mm a')
                                .format(consultation.scheduledTime),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${consultation.duration.inMinutes} min',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUpcoming
                          ? 'Join on time, keep your records nearby, and use chat for anything the doctor should know beforehand.'
                          : (consultation.summary?.isNotEmpty ?? false)
                              ? consultation.summary!
                              : 'Consultation completed in local preview mode. Follow-up guidance will appear here.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: kTitleTextColor.withOpacity(0.68),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (isUpcoming)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Get.toNamed('/consultation-detail',
                                  arguments: consultation);
                            },
                            child: Text('Details'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: MaterialButton(
                            onPressed: () {
                              Get.toNamed('/video-consultation',
                                  arguments: consultation);
                            },
                            color: kOrangeColor,
                            height: 42,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Join Now',
                              style: TextStyle(
                                color: kWhiteColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.toNamed('/consultation-detail',
                              arguments: consultation);
                        },
                        child: Text('View Summary'),
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

  Widget _buildOverviewCard({
    required int upcomingCount,
    required int completedCount,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildOverviewStat('$upcomingCount', 'Upcoming')),
          Expanded(child: _buildOverviewStat('$completedCount', 'Completed')),
          Expanded(child: _buildOverviewStat('3', 'Prep Items')),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: kBlueColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kTitleTextColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
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
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[300]),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
          ],
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
    return NetworkImage(avatar);
  }

  Color _typeColor(String consultationType) {
    switch (consultationType) {
      case 'audio':
        return Colors.green;
      case 'text':
        return Colors.teal;
      default:
        return Colors.blue;
    }
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            _avatarProvider(consultation.doctorAvatar),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              consultation.doctorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: kTitleTextColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy hh:mm a')
                                  .format(consultation.scheduledTime),
                              style: TextStyle(
                                color: kTitleTextColor.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _detailRow(
                      'Type', consultation.consultationType.toUpperCase()),
                  _detailRow(
                      'Duration', '${consultation.duration.inMinutes} minutes'),
                  _detailRow('Status', consultation.status.toUpperCase()),
                  if (consultation.roomId != null)
                    _detailRow('Room', consultation.roomId!),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUpcoming ? 'Preparation Notes' : 'Consultation Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    isUpcoming
                        ? 'Keep your medications, lab reports, and a short symptom summary ready before you join. Use chat if you need to update the doctor beforehand.'
                        : (consultation.summary?.isNotEmpty ?? false)
                            ? consultation.summary!
                            : 'No summary has been recorded yet in local preview mode.',
                    style: TextStyle(
                      height: 1.5,
                      color: kTitleTextColor.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Follow-up Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  _actionLine('Open messages to share updates or files.'),
                  _actionLine('Review prescriptions after the visit.'),
                  _actionLine('Use reviews to record your experience.'),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (isUpcoming)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.toNamed('/chat'),
                      child: Text('Open Chat'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed('/video-consultation',
                          arguments: consultation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrangeColor,
                      ),
                      child: Text(
                        'Join Session',
                        style: TextStyle(color: kWhiteColor),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          controller.downloadRecording(consultation.id),
                      child: Text('Download'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed('/reviews'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlueColor,
                      ),
                      child: Text(
                        'Leave Review',
                        style: TextStyle(color: kWhiteColor),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: kBlueColor),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
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
    return NetworkImage(avatar);
  }
}

class VideoConsultationScreen extends StatefulWidget {
  @override
  State<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
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
                    'Connected in local preview mode',
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
                        'Preview session',
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
                        'Use this screen as a local UI placeholder for video calls. End the consultation to move it into completed state.',
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
                                'Consultation ended in local preview mode. Review medications and follow up if symptoms continue.',
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
    return NetworkImage(avatar);
  }
}
