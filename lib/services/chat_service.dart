import 'package:doctor_consultation_app/models/chat_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();

  final List<ChatModel> _mockChats = [
    ChatModel(
      id: 'chat_1',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      doctorAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      lastMessage: 'Take the medicine as prescribed. See you soon!',
      lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
      unreadCount: 0,
      isActive: true,
    ),
    ChatModel(
      id: 'chat_2',
      doctorId: 'doc_2',
      doctorName: 'Dr. Joseph Cart',
      doctorAvatar:
          'https://images.unsplash.com/photo-1622902046580-2b47f47f5471?w=400',
      lastMessage: 'Please schedule a follow-up appointment',
      lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
      unreadCount: 1,
      isActive: true,
    ),
  ];

  final List<MessageModel> _mockMessages = [
    MessageModel(
      id: 'msg_1',
      chatId: 'chat_1',
      senderId: 'user_123',
      senderName: 'You',
      senderAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      message: 'Hi Dr. Stella, I have a question about my symptoms',
      isDoctor: false,
      timestamp: DateTime.now().subtract(Duration(hours: 3)),
      isRead: true,
    ),
    MessageModel(
      id: 'msg_2',
      chatId: 'chat_1',
      senderId: 'doc_1',
      senderName: 'Dr. Stella Kane',
      senderAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      message: 'Hi! Please describe your symptoms in detail',
      isDoctor: true,
      timestamp: DateTime.now().subtract(Duration(hours: 3)),
      isRead: true,
    ),
    MessageModel(
      id: 'msg_3',
      chatId: 'chat_1',
      senderId: 'user_123',
      senderName: 'You',
      senderAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      message: 'I have been experiencing mild headaches for 3 days',
      isDoctor: false,
      timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 45)),
      isRead: true,
    ),
    MessageModel(
      id: 'msg_4',
      chatId: 'chat_1',
      senderId: 'doc_1',
      senderName: 'Dr. Stella Kane',
      senderAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      message: 'Take the medicine as prescribed. See you soon!',
      isDoctor: true,
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      isRead: true,
    ),
  ];

  /// Get all chats
  Future<List<ChatModel>> getChats(String userId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _mockChats;
  }

  /// Get messages for a specific chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _mockMessages.where((m) => m.chatId == chatId).toList();
  }

  /// Send message
  Future<bool> sendMessage(
    String chatId,
    String userId,
    String userName,
    String userAvatar,
    String message,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));

      final newMessage = MessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: userId,
        senderName: userName,
        senderAvatar: userAvatar,
        message: message,
        isDoctor: false,
        timestamp: DateTime.now(),
        isRead: false,
      );

      _mockMessages.add(newMessage);

      // Update last message in chat
      final chatIndex = _mockChats.indexWhere((c) => c.id == chatId);
      if (chatIndex != -1) {
        _mockChats[chatIndex] = _mockChats[chatIndex].copyWith(
          lastMessage: message,
          lastMessageTime: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead(String chatId) async {
    try {
      await Future.delayed(Duration(milliseconds: 200));
      for (var msg in _mockMessages) {
        if (msg.chatId == chatId && !msg.isRead) {
          msg = msg.copyWith(isRead: true);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start new chat with doctor
  Future<ChatModel?> startChat(
    String doctorId,
    String doctorName,
    String doctorAvatar,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      final newChat = ChatModel(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        doctorId: doctorId,
        doctorName: doctorName,
        doctorAvatar: doctorAvatar,
        lastMessage: 'Chat started',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isActive: true,
      );

      _mockChats.add(newChat);
      return newChat;
    } catch (e) {
      return null;
    }
  }

  /// Search chats
  Future<List<ChatModel>> searchChats(String query) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockChats
        .where((chat) =>
            chat.doctorName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get unread count
  int getUnreadCount() {
    return _mockChats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
  }
}
