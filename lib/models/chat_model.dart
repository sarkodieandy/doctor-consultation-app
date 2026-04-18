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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'message': message,
      'is_doctor': isDoctor,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? '').toString(),
      chatId: (json['chat_id'] ?? json['chatId'] ?? '').toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      senderName: json['sender_name'] ?? json['senderName'] ?? '',
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'] ?? '',
      message: json['message'] ?? '',
      isDoctor: json['is_doctor'] ?? json['isDoctor'] ?? false,
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_avatar': doctorAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'is_active': isActive,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: (json['id'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      doctorName: json['doctor_name'] ?? json['doctorName'] ?? '',
      doctorAvatar: json['doctor_avatar'] ?? json['doctorAvatar'] ?? '',
      lastMessage: json['last_message'] ?? json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['last_message_time'] ??
          json['lastMessageTime'] ??
          DateTime.now().toIso8601String()),
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

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
