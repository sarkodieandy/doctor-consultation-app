import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/chat_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ChatController>()) {
      controller = Get.find<ChatController>();
    } else {
      controller = Get.put<ChatController>(ChatController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: kOrangeColor),
            );
          }

          if (controller.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 60, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.chats.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildIntroCard()
                        .animate()
                        .fadeIn(duration: 260.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 12),
                    _buildNewChatCard()
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 260.ms)
                        .slideY(begin: 0.08, end: 0),
                  ],
                );
              }

              final chat = controller.chats[index - 1];
              return GestureDetector(
                onTap: () {
                  Get.toNamed('/chat-detail', arguments: chat);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _avatarProvider(chat.doctorAvatar),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.doctorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: kTitleTextColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kOrangeColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: TextStyle(
                              color: kWhiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (index * 45).ms, duration: 260.ms)
                  .slideY(begin: 0.06, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messaging Guidelines',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use chat for follow-ups, dosage questions, and appointment prep. Urgent symptoms should go to emergency care.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: kTitleTextColor.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Connect',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Send a message before your next visit if symptoms or your schedule has changed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
    if (avatar.toLowerCase().contains('.svg')) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    return const AssetImage(DoctorModel.fallbackImagePath);
  }
}

class ChatDetailScreen extends StatefulWidget {
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ChatController controller;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  void _openConsultationCall({required bool isVideo}) {
    final selected = controller.selectedChat.value;
    final argumentChat = Get.arguments;
    final activeChat =
        selected ?? (argumentChat is ChatModel ? argumentChat : null);

    if (activeChat == null) {
      Get.snackbar(
        'Unable to Start Call',
        'Open a chat thread first, then try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final currentUserId = controller.currentUserId ?? 'user_123';
    final currentUserName = controller.currentUserName;

    Get.toNamed(
      '/video-consultation',
      arguments: {
        'channelId': 'chat_${activeChat.id}_${isVideo ? 'video' : 'audio'}',
        'userId': currentUserId,
        'appointmentId': activeChat.id,
        'doctorName': activeChat.doctorName,
        'doctorAvatar': activeChat.doctorAvatar,
        'patientName': currentUserName,
        'isVideoCall': isVideo,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ChatController>()) {
      controller = Get.find<ChatController>();
    } else {
      controller = Get.put<ChatController>(ChatController());
    }

    final chat = Get.arguments;
    if (chat is ChatModel) {
      controller.openChat(chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedChat.value?.doctorName ?? 'Chat',
                style: TextStyle(
                  color: kTitleTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    controller.isPeerTyping.value
                        ? '${controller.peerRoleLabel} is typing...'
                        : 'Online',
                    style: TextStyle(
                      color: controller.isPeerTyping.value
                          ? kBlueColor
                          : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                  if (controller.isPeerTyping.value) ...[
                    SizedBox(width: 6),
                    _TypingDots(color: kBlueColor),
                  ],
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: kBlueColor),
            onPressed: () => _openConsultationCall(isVideo: false),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: kBlueColor),
            onPressed: () => _openConsultationCall(isVideo: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Keep messages concise and include medication names, test dates, or symptom duration when relevant.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: kTitleTextColor.withOpacity(0.68),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: patientQuickReplies.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final reply = patientQuickReplies[index];
                return ActionChip(
                  label:
                      Text(reply, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () {
                    messageController.text = reply;
                  },
                );
              },
            ),
          ),
          Obx(
            () {
              if (!controller.isPeerTyping.value) {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xffEAF1FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBlueColor.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypingDots(color: kBlueColor),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.peerRoleLabel} is typing',
                      style: TextStyle(
                        color: kBlueColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 180.ms);
            },
          ),
          Expanded(
            child: Obx(
              () {
                if (controller.messages.isEmpty) {
                  return Center(
                    child: Text('Start a conversation'),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = controller.isMyMessage(message);

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? kBlueColor : kWhiteColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isMe ? kWhiteColor : kTitleTextColor,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(message.timestamp),
                              style: TextStyle(
                                color: isMe
                                    ? kWhiteColor.withOpacity(0.7)
                                    : Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: 0.05, end: 0);
                  },
                );
              },
            ),
          ),
          Obx(
            () {
              if (!controller.isCurrentUserTyping.value) {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'You are typing...',
                  style: TextStyle(
                    color: kBlueColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: controller.onMessageInputChanged,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: kSearchBackgroundColor),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: kSearchBackgroundColor,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: kBlueColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: kWhiteColor, size: 20),
                    onPressed: () async {
                      if (messageController.text.isNotEmpty) {
                        await controller.sendMessage(messageController.text);
                        messageController.clear();
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.stopTyping();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

class _TypingDots extends StatelessWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildDot(0),
        const SizedBox(width: 3),
        _buildDot(120),
        const SizedBox(width: 3),
        _buildDot(240),
      ],
    );
  }

  Widget _buildDot(int delayMs) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(delay: delayMs.ms, duration: 360.ms)
        .fadeOut(duration: 360.ms);
  }
}
