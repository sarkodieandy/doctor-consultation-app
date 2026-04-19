import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/local_backend_store.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  static final Map<String, Map<String, bool>> _typingStateByChat = {};

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();
  final _store = LocalBackendStore.instance;

  /// Get all chats for the current user
  Future<List<ChatModel>> getChats(String userId) async {
    final chats = _store.chats
        .where((chat) => _store.chatPatientsById[chat.id] == userId)
        .toList();
    chats.sort(
        (left, right) => right.lastMessageTime.compareTo(left.lastMessageTime));
    return chats;
  }

  /// Get messages for a specific chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    final messages =
        _store.messages.where((message) => message.chatId == chatId).toList();
    messages.sort((left, right) => left.timestamp.compareTo(right.timestamp));
    return messages;
  }

  ChatModel? _findChat(String chatId) {
    try {
      return _store.chats.firstWhere((chat) => chat.id == chatId);
    } catch (_) {
      return null;
    }
  }

  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    if (chatId.isEmpty || userId.isEmpty) {
      return;
    }
    final currentChatMap = _typingStateByChat.putIfAbsent(chatId, () => {});
    currentChatMap[userId] = isTyping;
  }

  Future<bool> getPeerTypingStatus(String chatId, String currentUserId) async {
    if (chatId.isEmpty || currentUserId.isEmpty) {
      return false;
    }

    final chat = _findChat(chatId);
    if (chat == null) {
      return false;
    }

    final patientId = _store.chatPatientsById[chatId];
    if (patientId == null) {
      return false;
    }

    final peerId = currentUserId == chat.doctorId ? patientId : chat.doctorId;
    return _typingStateByChat[chatId]?[peerId] ?? false;
  }

  Future<void> clearTypingStatus(String chatId, String userId) async {
    if (chatId.isEmpty || userId.isEmpty) {
      return;
    }
    _typingStateByChat[chatId]?[userId] = false;
  }

  /// Send message
  Future<bool> sendMessage(
    String chatId,
    String userId,
    String userName,
    String userAvatar,
    String message,
  ) async {
    final sender = _store.findUserById(userId);
    _store.messages.add(
      MessageModel(
        id: _store.nextId('message'),
        chatId: chatId,
        senderId: userId,
        senderName: userName,
        senderAvatar: userAvatar,
        message: message,
        isDoctor: sender?.isDoctor ?? false,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );

    final index = _store.chats.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      final chat = _store.chats[index];
      _store.chats[index] = chat.copyWith(
        lastMessage: message,
        lastMessageTime: DateTime.now(),
        unreadCount: (sender?.isDoctor ?? false)
            ? chat.unreadCount + 1
            : chat.unreadCount,
      );
    }

    return true;
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead(String chatId) async {
    for (var index = 0; index < _store.messages.length; index += 1) {
      final message = _store.messages[index];
      if (message.chatId == chatId && !message.isRead) {
        _store.messages[index] = message.copyWith(isRead: true);
      }
    }

    final chatIndex = _store.chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _store.chats[chatIndex] =
          _store.chats[chatIndex].copyWith(unreadCount: 0);
    }
    return true;
  }

  /// Check if appointment is approved (REQUIRED for chat)
  Future<bool> canInitiateChat(String patientId, String doctorId) async {
    return _store.appointments.any(
      (appointment) =>
          appointment.userId == patientId &&
          appointment.doctorId == doctorId &&
          appointment.status == 'confirmed',
    );
  }

  /// Start new chat with doctor (only after appointment approval)
  Future<ChatModel?> startChat(
    String doctorId,
    String doctorName,
    String doctorAvatar,
  ) async {
    final userId = _store.currentUserId;
    if (userId == null) return null;

    final canChat = await canInitiateChat(userId, doctorId);
    if (!canChat) {
      return null;
    }

    try {
      return _store.chats.firstWhere(
        (chat) =>
            _store.chatPatientsById[chat.id] == userId &&
            chat.doctorId == doctorId,
      );
    } catch (_) {
      final chat = ChatModel(
        id: _store.nextId('chat'),
        doctorId: doctorId,
        doctorName: doctorName,
        doctorAvatar: doctorAvatar,
        lastMessage: 'Chat started after appointment approval',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isActive: true,
      );
      _store.chats.add(chat);
      _store.chatPatientsById[chat.id] = userId;
      return chat;
    }
  }

  /// Auto-create chat session (called when appointment is approved)
  Future<ChatModel?> autoCreateChatForApprovedAppointment(
    String patientId,
    String doctorId,
    String doctorName,
    String doctorAvatar,
  ) async {
    try {
      return _store.chats.firstWhere(
        (chat) =>
            _store.chatPatientsById[chat.id] == patientId &&
            chat.doctorId == doctorId,
      );
    } catch (_) {
      final chat = ChatModel(
        id: _store.nextId('chat'),
        doctorId: doctorId,
        doctorName: doctorName,
        doctorAvatar: doctorAvatar,
        lastMessage: 'Appointment approved! Chat is now available.',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isActive: true,
      );
      _store.chats.add(chat);
      _store.chatPatientsById[chat.id] = patientId;
      return chat;
    }
  }

  /// Search chats
  Future<List<ChatModel>> searchChats(String query) async {
    final userId = _store.currentUserId;
    if (userId == null) return [];
    final normalizedQuery = query.toLowerCase();
    return _store.chats.where((chat) {
      return _store.chatPatientsById[chat.id] == userId &&
          chat.doctorName.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final userId = _store.currentUserId;
    if (userId == null) return 0;
    return _store.chats
        .where((chat) => _store.chatPatientsById[chat.id] == userId)
        .fold<int>(0, (sum, chat) => sum + chat.unreadCount);
  }

  /// Update user online status
  Future<bool> setUserPresence(String userId, bool isOnline) async {
    final user = _store.findUserById(userId);
    if (user == null) return false;
    _store.saveUser(user.copyWith(isOnline: isOnline));
    return true;
  }

  /// Get user online status
  Future<bool> getUserPresence(String userId) async {
    return _store.findUserById(userId)?.isOnline ?? false;
  }

  /// Get unread chat count for doctor side
  Future<int> getUnreadCountForDoctor(String doctorId) async {
    return _store.chats
        .where((chat) => chat.doctorId == doctorId)
        .fold<int>(0, (sum, chat) => sum + chat.unreadCount);
  }

  /// Get all chats for doctor
  Future<List<ChatModel>> getChatsForDoctor(String doctorId) async {
    final chats =
        _store.chats.where((chat) => chat.doctorId == doctorId).toList();
    chats.sort(
        (left, right) => right.lastMessageTime.compareTo(left.lastMessageTime));
    return chats;
  }
}
