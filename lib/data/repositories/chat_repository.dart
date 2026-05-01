import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final ChatService _local = ChatService();
  final AuthService _authService = AuthService();
  static final Map<String, Map<String, bool>> _typingStateByChat = {};

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatModel>> fetchConversations(String userId) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final rows = await client
            .from('care_chats')
            .select()
            .eq('patient_id', userId)
            .eq('is_active', true)
            .order('last_message_time', ascending: false);
        return rows.map<ChatModel>((row) {
          final json = Map<String, dynamic>.from(row);
          return ChatModel(
            id: (json['id'] ?? '').toString(),
            doctorId: (json['doctor_id'] ?? '').toString(),
            doctorName: (json['doctor_name'] ?? 'Doctor').toString(),
            doctorAvatar: (json['doctor_avatar'] ?? '').toString(),
            lastMessage: (json['last_message'] ?? '').toString(),
            lastMessageTime: DateTime.parse(
              (json['last_message_time'] ?? DateTime.now().toIso8601String())
                  .toString(),
            ),
            unreadCount:
                int.tryParse((json['patient_unread_count'] ?? 0).toString()) ??
                    0,
            isActive: json['is_active'] != false,
          );
        }).toList();
      } catch (_) {}
    }
    return await _local.getChats(userId);
  }

  Future<List<MessageModel>> fetchMessages(String chatId) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final rows = await client
            .from('care_messages')
            .select()
            .eq('chat_id', chatId)
            .order('created_at');
        return rows.map<MessageModel>((row) {
          final json = Map<String, dynamic>.from(row);
          json['timestamp'] = json['created_at'];
          return MessageModel.fromJson(json);
        }).toList();
      } catch (_) {}
    }
    return await _local.getMessages(chatId);
  }

  Future<bool> sendMessage(String chatId, Map<String, dynamic> message) async {
    final client = _client;
    final currentUser = _authService.currentUser;
    if (client != null && client.auth.currentUser != null) {
      try {
        final text = (message['message'] ?? '').toString().trim();
        if (text.isEmpty) return false;
        await client.from('care_messages').insert({
          'chat_id': chatId,
          'sender_id': message['senderId'] ?? currentUser?.id,
          'sender_name':
              message['senderName'] ?? currentUser?.fullName ?? 'You',
          'sender_avatar': message['senderAvatar'] ?? currentUser?.profileImage,
          'message': text,
          'is_doctor': currentUser?.isDoctor ?? false,
          'is_read': false,
        });
        await client.from('care_chats').update({
          'last_message': text,
          'last_message_time': DateTime.now().toIso8601String(),
          if (currentUser?.isDoctor == true) 'patient_unread_count': 1,
          if (currentUser?.isDoctor != true) 'doctor_unread_count': 1,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', chatId);
        return true;
      } catch (_) {}
    }
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
    final chatTyping = _typingStateByChat.putIfAbsent(chatId, () => {});
    chatTyping[userId] = isTyping;
    return await _local.setTypingStatus(chatId, userId, isTyping);
  }

  Future<bool> getPeerTypingStatus(String chatId, String currentUserId) async {
    final chatTyping = _typingStateByChat[chatId];
    if (chatTyping != null) {
      return chatTyping.entries
          .any((entry) => entry.key != currentUserId && entry.value);
    }
    return await _local.getPeerTypingStatus(chatId, currentUserId);
  }

  Future<void> clearTypingStatus(String chatId, String userId) async {
    _typingStateByChat[chatId]?[userId] = false;
    return await _local.clearTypingStatus(chatId, userId);
  }

  Future<bool> markMessagesAsRead(String chatId) async {
    final client = _client;
    final currentUser = _authService.currentUser;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client
            .from('care_messages')
            .update({'is_read': true})
            .eq('chat_id', chatId)
            .neq('sender_id', currentUser?.id ?? '');
        await client.from('care_chats').update({
          if (currentUser?.isDoctor == true) 'doctor_unread_count': 0,
          if (currentUser?.isDoctor != true) 'patient_unread_count': 0,
        }).eq('id', chatId);
        return true;
      } catch (_) {}
    }
    return await _local.markMessagesAsRead(chatId);
  }

  Future<ChatModel?> startChat(
      String doctorId, String doctorName, String doctorAvatar) async {
    return await _local.startChat(doctorId, doctorName, doctorAvatar);
  }

  Future<List<ChatModel>> getChatsForDoctor(String doctorId) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final rows = await client
            .from('care_chats')
            .select()
            .eq('doctor_id', doctorId)
            .eq('is_active', true)
            .order('last_message_time', ascending: false);
        return rows.map<ChatModel>((row) {
          final json = Map<String, dynamic>.from(row);
          return ChatModel(
            id: (json['id'] ?? '').toString(),
            doctorId: (json['doctor_id'] ?? '').toString(),
            doctorName: (json['patient_name'] ?? 'Patient').toString(),
            doctorAvatar: (json['patient_avatar'] ?? '').toString(),
            lastMessage: (json['last_message'] ?? '').toString(),
            lastMessageTime: DateTime.parse(
              (json['last_message_time'] ?? DateTime.now().toIso8601String())
                  .toString(),
            ),
            unreadCount:
                int.tryParse((json['doctor_unread_count'] ?? 0).toString()) ??
                    0,
            isActive: json['is_active'] != false,
          );
        }).toList();
      } catch (_) {}
    }
    return await _local.getChatsForDoctor(doctorId);
  }

  Future<ChatModel?> ensureChatForAppointment({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String patientName,
    required String patientAvatar,
    required String doctorName,
    required String doctorAvatar,
  }) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final existing = await client
            .from('care_chats')
            .select()
            .eq('appointment_id', appointmentId)
            .maybeSingle();
        final row = existing ??
            await client
                .from('care_chats')
                .insert({
                  'appointment_id': appointmentId,
                  'patient_id': patientId,
                  'doctor_id': doctorId,
                  'patient_name': patientName,
                  'patient_avatar': patientAvatar,
                  'doctor_name': doctorName,
                  'doctor_avatar': doctorAvatar,
                  'last_message': 'Consultation chat is ready.',
                  'last_message_time': DateTime.now().toIso8601String(),
                })
                .select()
                .single();
        final json = Map<String, dynamic>.from(row);
        final isDoctor = _authService.currentUser?.isDoctor ?? false;
        return ChatModel(
          id: (json['id'] ?? '').toString(),
          doctorId: (json['doctor_id'] ?? '').toString(),
          doctorName:
              (isDoctor ? json['patient_name'] : json['doctor_name'] ?? '')
                  .toString(),
          doctorAvatar:
              (isDoctor ? json['patient_avatar'] : json['doctor_avatar'] ?? '')
                  .toString(),
          lastMessage: (json['last_message'] ?? '').toString(),
          lastMessageTime: DateTime.parse(
            (json['last_message_time'] ?? DateTime.now().toIso8601String())
                .toString(),
          ),
          unreadCount: int.tryParse((isDoctor
                      ? json['doctor_unread_count']
                      : json['patient_unread_count'] ?? 0)
                  .toString()) ??
              0,
          isActive: json['is_active'] != false,
        );
      } catch (_) {}
    }
    return null;
  }

  Future<List<ChatModel>> searchChats(String query) async {
    // UI-only: Not implemented, return empty or filter local if needed
    return [];
  }
}
