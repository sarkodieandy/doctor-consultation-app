import 'dart:async';

import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
// local ChatService removed; using ChatRepository instead
import 'package:doctor_consultation_app/data/repositories/chat_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final _authService = AuthService();
  final _chatRepo = ChatRepository();

  final chats = <ChatModel>[].obs;
  final messages = <MessageModel>[].obs;
  final selectedChat = Rxn<ChatModel>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();
  final unreadCount = 0.obs;
  final isCurrentUserTyping = false.obs;
  final isPeerTyping = false.obs;

  String? _userId;
  Timer? _typingDebounceTimer;
  Timer? _peerTypingPollTimer;

  String? get currentUserId => _userId;
  String get currentUserName =>
      _authService.currentUser?.fullName.trim().isNotEmpty == true
          ? _authService.currentUser!.fullName
          : 'You';
  bool get isDoctorUser => _authService.currentUser?.isDoctor ?? false;
  String get peerRoleLabel => isDoctorUser ? 'Patient' : 'Doctor';

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        return;
      }
      fetchChats();
    });
  }

  /// Fetch all chats
  Future<void> fetchChats() async {
    try {
      isLoading(true);
      errorMessage(null);
      List<ChatModel> result;
      if (isDoctorUser) {
        result = await _chatRepo.getChatsForDoctor(_userId ?? '');
      } else {
        result = await _chatRepo.fetchConversations(_userId ?? '');
      }

      chats.assignAll(result);
      unreadCount(result.fold<int>(0, (sum, chat) => sum + chat.unreadCount));
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Open chat
  Future<void> openChat(ChatModel chat) async {
    try {
      selectedChat(chat);
      isLoading(true);
      errorMessage(null);
      var result = await _chatRepo.fetchMessages(chat.id);
      messages.assignAll(result);
      await _chatRepo.markMessagesAsRead(chat.id);
      await _refreshPeerTypingStatus();
      _startPeerTypingPolling();
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> onMessageInputChanged(String input) async {
    final activeChat = selectedChat.value;
    final userId = _userId;
    if (activeChat == null || userId == null) {
      return;
    }

    final shouldShowTyping = input.trim().isNotEmpty;
    if (isCurrentUserTyping.value != shouldShowTyping) {
      isCurrentUserTyping(shouldShowTyping);
      await _chatRepo.setTypingStatus(activeChat.id, userId, shouldShowTyping);
    }

    _typingDebounceTimer?.cancel();
    if (shouldShowTyping) {
      _typingDebounceTimer = Timer(const Duration(milliseconds: 1300), () {
        stopTyping();
      });
    }
  }

  Future<void> stopTyping() async {
    final activeChat = selectedChat.value;
    final userId = _userId;
    if (activeChat == null || userId == null) {
      return;
    }
    if (!isCurrentUserTyping.value) {
      return;
    }

    isCurrentUserTyping(false);
    await _chatRepo.clearTypingStatus(activeChat.id, userId);
  }

  void _startPeerTypingPolling() {
    _peerTypingPollTimer?.cancel();
    _peerTypingPollTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      _refreshPeerTypingStatus();
    });
  }

  Future<void> _refreshPeerTypingStatus() async {
    final activeChat = selectedChat.value;
    final userId = _userId;
    if (activeChat == null || userId == null) {
      isPeerTyping(false);
      return;
    }
    final peerTyping =
        await _chatRepo.getPeerTypingStatus(activeChat.id, userId);
    isPeerTyping(peerTyping);
  }

  /// Send message
  Future<bool> sendMessage(String messageText) async {
    try {
      if (selectedChat.value == null) return false;

      await stopTyping();

      final success = await _chatRepo.sendMessage(
        selectedChat.value!.id,
        {
          'senderId': _userId ?? '',
          'senderName': 'You',
          'senderAvatar': 'assets/images/doctor1.png',
          'message': messageText,
        },
      );

      if (success) {
        await openChat(selectedChat.value!);
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    }
  }

  /// Start new chat with doctor
  Future<bool> startChatWithDoctor(
    String doctorId,
    String doctorName,
    String doctorAvatar,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final newChat = await _chatRepo.startChat(
        doctorId,
        doctorName,
        doctorAvatar,
      );

      if (newChat != null) {
        chats.add(newChat);
        selectedChat(newChat);
        messages.clear();
        return true;
      }
      return false;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Search chats
  Future<void> searchChats(String query) async {
    try {
      isLoading(true);
      errorMessage(null);

      if (query.isEmpty) {
        await fetchChats();
      } else {
        final result = await _chatRepo.searchChats(query);
        chats.assignAll(result);
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Get unread count
  int getUnreadCount() => unreadCount.value;

  bool isMyMessage(MessageModel message) {
    return message.senderId == _userId;
  }

  @override
  void onClose() {
    stopTyping();
    _typingDebounceTimer?.cancel();
    _peerTypingPollTimer?.cancel();
    super.onClose();
  }
}
