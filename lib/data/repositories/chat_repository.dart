import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/chat_service.dart';

class ChatRepository {
  final ChatService _local = ChatService();

  Future<List<ChatModel>> fetchConversations(String userId) async {
    return await _local.getChats(userId);
  }

  Future<List<MessageModel>> fetchMessages(String chatId) async {
    return await _local.getMessages(chatId);
  }

  Future<bool> sendMessage(String chatId, Map<String, dynamic> message) async {
    return await _local.sendMessage(
      chatId,
      message['senderId'] ?? '',
      message['senderName'] ?? '',
      message['senderAvatar'] ?? '',
      message['message'] ?? '',
    );
  }

  Future<void> setTypingStatus(
      String chatId, String userId, bool isTyping) async {
    return await _local.setTypingStatus(chatId, userId, isTyping);
  }

  Future<bool> getPeerTypingStatus(String chatId, String currentUserId) async {
    return await _local.getPeerTypingStatus(chatId, currentUserId);
  }

  Future<void> clearTypingStatus(String chatId, String userId) async {
    return await _local.clearTypingStatus(chatId, userId);
  }

  Future<bool> markMessagesAsRead(String chatId) async {
    return await _local.markMessagesAsRead(chatId);
  }

  Future<ChatModel?> startChat(
      String doctorId, String doctorName, String doctorAvatar) async {
    return await _local.startChat(doctorId, doctorName, doctorAvatar);
  }

  Future<List<ChatModel>> getChatsForDoctor(String doctorId) async {
    return await _local.getChatsForDoctor(doctorId);
  }

  Future<List<ChatModel>> searchChats(String query) async {
    // UI-only: Not implemented, return empty or filter local if needed
    return [];
  }
}
