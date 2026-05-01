import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/data/repositories/chat_repository.dart';
import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/call_preview_service.dart';
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
  final callPreviewService = CallPreviewService();
  final _chatRepository = ChatRepository();
  final _authService = AuthService();
  final _chatInputController = TextEditingController();

  // Call state
  late String channelId;
  late String userId;
  late String appointmentId;
  late String doctorName;
  late String doctorAvatar;
  late String patientName;
  Map<String, dynamic> _callArgs = {};

  bool isCameraOn = true;
  bool isMicOn = true;
  bool isRemoteUserJoined = false;
  bool isConnecting = true;
  String? _chatId;
  List<MessageModel> _callMessages = [];
  bool _isChatLoading = false;

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
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};
    _callArgs = args;

    channelId = args['channelId'] ?? 'consultation_room';
    userId = args['userId'] ?? '';
    appointmentId = args['appointmentId'] ?? '';
    _chatId = args['chatId']?.toString();
    doctorName = args['doctorName'] ?? 'Doctor';
    doctorAvatar = args['doctorAvatar'] ?? '';
    patientName = args['patientName'] ?? 'You';
    isCameraOn = args['isVideoCall'] ?? true;

    _prepareCallChat(args);

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

  Future<void> _prepareCallChat(Map<String, dynamic> args) async {
    if (_chatId != null && _chatId!.isNotEmpty) {
      await _loadCallMessages();
      return;
    }

    final patientId = (args['patientId'] ?? '').toString();
    final doctorId = (args['doctorId'] ?? '').toString();
    if (appointmentId.isEmpty || patientId.isEmpty || doctorId.isEmpty) {
      return;
    }

    final chat = await _chatRepository.ensureChatForAppointment(
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      patientName: (args['patientFullName'] ?? patientName).toString(),
      patientAvatar: (args['patientAvatar'] ?? '').toString(),
      doctorName: (args['doctorFullName'] ?? doctorName).toString(),
      doctorAvatar: doctorAvatar,
    );
    if (!mounted || chat == null) return;
    setState(() => _chatId = chat.id);
    await _loadCallMessages();
  }

  Future<void> _loadCallMessages() async {
    final chatId = _chatId;
    if (chatId == null || chatId.isEmpty) return;
    setState(() => _isChatLoading = true);
    final messages = await _chatRepository.fetchMessages(chatId);
    await _chatRepository.markMessagesAsRead(chatId);
    if (!mounted) return;
    setState(() {
      _callMessages = messages;
      _isChatLoading = false;
    });
  }

  Future<void> _sendCallMessage() async {
    final text = _chatInputController.text.trim();
    final chatId = _chatId;
    final user = _authService.currentUser;
    if (text.isEmpty || chatId == null || chatId.isEmpty || user == null) {
      return;
    }
    _chatInputController.clear();
    await _chatRepository.sendMessage(chatId, {
      'senderId': user.id,
      'senderName': user.fullName,
      'senderAvatar': user.profileImage,
      'message': text,
    });
    await _loadCallMessages();
  }

  void _openInCallChat() {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.68,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: kBlueColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: kBlueColor.withOpacity(0.12),
                        child:
                            Icon(Icons.chat_bubble_outline, color: kBlueColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'In-call chat',
                          style: TextStyle(
                            color: kTitleTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _loadCallMessages();
                          setModalState(() {});
                        },
                        icon: Icon(Icons.refresh_rounded, color: kBlueColor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isChatLoading
                      ? Center(
                          child: CircularProgressIndicator(color: kBlueColor))
                      : _chatId == null
                          ? _CallChatEmpty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _callMessages.length,
                              itemBuilder: (context, index) {
                                final message = _callMessages[index];
                                final isMine = message.senderId ==
                                    _authService.currentUser?.id;
                                return Align(
                                  alignment: isMine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.72,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? kBlueColor
                                          : kBackgroundColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      message.message,
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white
                                            : kTitleTextColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatInputController,
                          enabled: _chatId != null,
                          decoration: InputDecoration(
                            hintText: _chatId == null
                                ? 'Chat opens from an appointment'
                                : 'Message during the call',
                            filled: true,
                            fillColor: kBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: kBlueColor,
                        child: IconButton(
                          onPressed: _chatId == null
                              ? null
                              : () async {
                                  await _sendCallMessage();
                                  setModalState(() {});
                                },
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
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
      isScrollControlled: true,
    );
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
    callTimer?.cancel();

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

    await callPreviewService.endConsultation(
      appointmentId: appointmentId,
      durationSeconds: callDurationSeconds,
    );
  }

  @override
  void dispose() {
    callTimer?.cancel();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const doctorAvatarProvider =
        AssetImage('assets/images/doctor1.png') as ImageProvider<Object>;

    return WillPopScope(
      onWillPop: () async {
        _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (isRemoteUserJoined && !isConnecting)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: doctorAvatarProvider,
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
                      backgroundImage: doctorAvatarProvider,
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
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                                if (_authService.currentUser?.isDoctor == true)
                                  ListTile(
                                    leading: Icon(Icons.medication_outlined,
                                        color: kBlueColor),
                                    title: Text('Send Prescription'),
                                    onTap: () {
                                      Get.back();
                                      Get.toNamed(
                                        '/doctor-write-prescription',
                                        arguments: _callArgs,
                                      );
                                    },
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

                      // In-call chat
                      GestureDetector(
                        onTap: _openInCallChat,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: kBlueColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
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

class _CallChatEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: kBlueColor.withOpacity(0.12),
              child: Icon(Icons.lock_outline_rounded, color: kBlueColor),
            ),
            const SizedBox(height: 14),
            Text(
              'Chat is tied to a booked consultation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTitleTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start the call from an appointment so messages are saved to the patient record.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTitleTextColor.withOpacity(0.58)),
            ),
          ],
        ),
      ),
    );
  }
}
