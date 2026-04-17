import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/consultation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ConsultationScreen extends StatelessWidget {
  final controller = Get.find<ConsultationController>();

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
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        if (controller.upcomingConsultations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, size: 60, color: Colors.grey[300]),
                SizedBox(height: 20),
                Text('No upcoming consultations'),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            ...controller.upcomingConsultations.map((consultation) {
              return _buildConsultationCard(consultation, true);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            ...controller.completedConsultations.map((consultation) {
              return _buildConsultationCard(consultation, false);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildConsultationCard(dynamic consultation, bool isUpcoming) {
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
                    backgroundImage: NetworkImage(consultation.doctorAvatar),
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
                            color: consultation.consultationType == 'video'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                consultation.consultationType == 'video'
                                    ? Icons.videocam
                                    : Icons.call,
                                size: 12,
                                color: consultation.consultationType == 'video'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                consultation.consultationType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      consultation.consultationType == 'video'
                                          ? Colors.blue
                                          : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kOrangeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 11,
                          color: kOrangeColor,
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
                  if (isUpcoming)
                    SizedBox(
                      width: double.infinity,
                      child: MaterialButton(
                        onPressed: () {
                          Get.toNamed('/video-consultation',
                              arguments: consultation);
                        },
                        color: kOrangeColor,
                        height: 40,
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
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: MaterialButton(
                            onPressed: () {},
                            color: kBlueColor.withOpacity(0.1),
                            height: 40,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.download,
                              color: kBlueColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: MaterialButton(
                            onPressed: () {},
                            color: kBlueColor.withOpacity(0.1),
                            height: 40,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.share,
                              color: kBlueColor,
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
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video area (placeholder)
          Center(
            child: Container(
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      controller.selectedConsultation.value?.doctorAvatar ??
                          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    controller.selectedConsultation.value?.doctorName ??
                        'Dr. Name',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top bar
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
                        '12:34',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.info, color: kWhiteColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      isCameraOn ? Icons.videocam : Icons.videocam_off,
                      isCameraOn ? kWhiteColor : Colors.red,
                      () {
                        setState(() => isCameraOn = !isCameraOn);
                      },
                    ),
                    _buildControlButton(
                      isMicOn ? Icons.mic : Icons.mic_off,
                      isMicOn ? kWhiteColor : Colors.red,
                      () {
                        setState(() => isMicOn = !isMicOn);
                      },
                    ),
                    _buildControlButton(
                      isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      isSpeakerOn ? kWhiteColor : Colors.red,
                      () {
                        setState(() => isSpeakerOn = !isSpeakerOn);
                      },
                    ),
                    _buildControlButton(
                      Icons.call_end,
                      Colors.red,
                      () {
                        controller.endConsultation(
                          controller.selectedConsultation.value?.id ?? '',
                          'Consultation completed',
                        );
                        Get.back();
                      },
                      isEndCall: true,
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

  Widget _buildControlButton(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isEndCall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEndCall ? Colors.red : Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
