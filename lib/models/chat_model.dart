class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String message;
  final bool isDoctor;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.message,
    required this.isDoctor,
    required this.timestamp,
    required this.isRead,
  });

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? message,
    bool? isDoctor,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      message: message ?? this.message,
      isDoctor: isDoctor ?? this.isDoctor,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ChatModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isActive;

  ChatModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isActive,
  });

  ChatModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
  }) {
    return ChatModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorAvatar: doctorAvatar ?? this.doctorAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
