import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/chat_service.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final _chatService = ChatService();

  final chats = <ChatModel>[].obs;
  final messages = <MessageModel>[].obs;
  final selectedChat = Rxn<ChatModel>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();
  final unreadCount = 0.obs;

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _userId = Get.arguments ?? 'user_123';
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
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Send message
  Future<bool> sendMessage(String messageText) async {
    try {
      if (selectedChat.value == null) return false;

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
}
