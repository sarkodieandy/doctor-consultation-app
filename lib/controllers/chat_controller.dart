import 'dart:async';

import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/chat_service.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final _authService = AuthService();
  final _chatService = ChatService();

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
    fetchChats();
  }

  /// Fetch all chats
  Future<void> fetchChats() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _chatService.getChats(_userId ?? '');
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
      final result = await _chatService.getMessages(chat.id);
      messages.assignAll(result);
      await _chatService.markMessagesAsRead(chat.id);
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
      await _chatService.setTypingStatus(
          activeChat.id, userId, shouldShowTyping);
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
    await _chatService.clearTypingStatus(activeChat.id, userId);
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
        await _chatService.getPeerTypingStatus(activeChat.id, userId);
    isPeerTyping(peerTyping);
  }

  /// Send message
  Future<bool> sendMessage(String messageText) async {
    try {
      if (selectedChat.value == null) return false;

      await stopTyping();

      final success = await _chatService.sendMessage(
        selectedChat.value!.id,
        _userId ?? '',
        'You',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        messageText,
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

      final newChat = await _chatService.startChat(
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
        final result = await _chatService.searchChats(query);
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
