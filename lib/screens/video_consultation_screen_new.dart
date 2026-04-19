import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/agora_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Enhanced Video Consultation Screen
///
/// Features:
/// - Video/audio toggle
/// - Call timer
/// - Professional call controls
/// - Connection status monitoring
/// - End call with duration tracking

class VideoConsultationScreen extends StatefulWidget {
  @override
  State<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  final agoraService = AgoraService();

  // Call state
  late String channelId;
  late String userId;
  late String appointmentId;
  late String doctorName;
  late String doctorAvatar;
  late String patientName;

  bool isCameraOn = true;
  bool isMicOn = true;
  bool isRemoteUserJoined = false;
  bool isConnecting = true;

  // Timer
  Timer? callTimer;
  int callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() {
    final rawArgs = Get.arguments;
    final Map<String, dynamic> args = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs as Map)
        : <String, dynamic>{};

    channelId = args['channelId'] ?? 'consultation_room';
    userId = args['userId'] ?? '';
    appointmentId = args['appointmentId'] ?? '';
    doctorName = args['doctorName'] ?? 'Doctor';
    doctorAvatar = args['doctorAvatar'] ?? '';
    patientName = args['patientName'] ?? 'You';
    isCameraOn = args['isVideoCall'] ?? true;

    print('📞 Initializing video call...');
    print('Channel: $channelId, User: $userId, Doctor: $doctorName');

    // Simulate connection after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isConnecting = false;
          isRemoteUserJoined = true;
        });
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    callTimer?.cancel();
    callTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    // Stop timer
    callTimer?.cancel();

    // Show end call dialog
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: kOrangeColor.withOpacity(0.1),
                radius: 40,
                child: Icon(Icons.call_end, color: kOrangeColor, size: 28),
              ),
              SizedBox(height: 16),
              Text(
                'Call Ended',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Duration: ${_formatDuration(callDurationSeconds)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Close call screen
                  },
                  color: kBlueColor,
                  height: 48,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Save consultation to backend
    await agoraService.endConsultation(
      appointmentId: appointmentId,
      durationSeconds: callDurationSeconds,
    );
  }

  @override
  void dispose() {
    callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Remote user video (full screen)
            if (isRemoteUserJoined && !isConnecting)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: NetworkImage(doctorAvatar.isEmpty
                            ? 'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=600'
                            : doctorAvatar),
                      ),
                      SizedBox(height: 24),
                      Text(
                        doctorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Connected',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else if (isConnecting)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: NetworkImage(doctorAvatar.isEmpty
                          ? 'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=600'
                          : doctorAvatar),
                    ),
                    SizedBox(height: 24),
                    Text(
                      doctorName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kOrangeColor),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connecting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Local user video (top-right small window)
            if (!isConnecting)
              Positioned(
                top: 24,
                right: 16,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: kBlueColor,
                          child: Text(
                            patientName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top info bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      onPressed: _endCall,
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      iconSize: 20,
                    ),
                  ),
                  // Call timer
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDuration(callDurationSeconds),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // More options
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      onPressed: () {
                        // Show more options
                        Get.bottomSheet(
                          Container(
                            color: kWhiteColor,
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading:
                                      Icon(Icons.note_add, color: kBlueColor),
                                  title: Text('Add Note'),
                                  onTap: () => Get.back(),
                                ),
                                ListTile(
                                  leading: Icon(Icons.screenshot,
                                      color: kOrangeColor),
                                  title: Text('Take Screenshot'),
                                  onTap: () => Get.back(),
                                ),
                                ListTile(
                                  leading: Icon(Icons.help_outline,
                                      color: Colors.grey),
                                  title: Text('Help'),
                                  onTap: () => Get.back(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Control buttons (bottom)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Info text
                  if (isConnecting)
                    Text(
                      'Doctor is joining...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      'Tap video or mute to toggle',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  SizedBox(height: 24),
                  // Button controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mic toggle
                      GestureDetector(
                        onTap: () {
                          setState(() => isMicOn = !isMicOn);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isMicOn ? kBlueColor : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMicOn ? Icons.mic : Icons.mic_off,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 24),

                      // End call button
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 24),

                      // Camera toggle
                      GestureDetector(
                        onTap: () {
                          setState(() => isCameraOn = !isCameraOn);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isCameraOn ? kOrangeColor : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCameraOn ? Icons.videocam : Icons.videocam_off,
                            color: Colors.white,
                            size: 24,
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
