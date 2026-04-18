import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all chats for the current user
  Future<List<ChatModel>> getChats(String userId) async {
    try {
      final data = await _supabase
          .from('chat_sessions')
          .select()
          .eq('patient_id', userId)
          .order('last_message_time', ascending: false);

      return (data as List).map((json) => ChatModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching chats: $e');
      return [];
    }
  }

  /// Get messages for a specific chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true);

      return (data as List).map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
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
      final msgJson = {
        'chat_id': chatId,
        'sender_id': userId,
        'sender_name': userName,
        'sender_avatar': userAvatar,
        'message': message,
        'is_doctor': false,
        'is_read': false,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _supabase.from('messages').insert(msgJson);

      // Update last message in chat session
      await _supabase.from('chat_sessions').update({
        'last_message': message,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead(String chatId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .eq('is_read', false);

      await _supabase
          .from('chat_sessions')
          .update({'unread_count': 0}).eq('id', chatId);

      return true;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  /// Check if appointment is approved (REQUIRED for chat)
  Future<bool> canInitiateChat(String patientId, String doctorId) async {
    try {
      final approvedCount = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', patientId)
          .eq('doctor_id', doctorId)
          .eq('status', 'confirmed')
          .count(CountOption.exact);

      print('Approved appointments: ${approvedCount.count}');
      return approvedCount.count > 0;
    } catch (e) {
      print('Error checking chat eligibility: $e');
      return false;
    }
  }

  /// Start new chat with doctor (only after appointment approval)
  Future<ChatModel?> startChat(
    String doctorId,
    String doctorName,
    String doctorAvatar,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // CRITICAL: Check if user has approved appointment with this doctor
      final canChat = await canInitiateChat(userId, doctorId);
      if (!canChat) {
        print('❌ Chat not allowed: No confirmed appointment found');
        return null;
      }

      // Check if chat already exists
      final existing = await _supabase
          .from('chat_sessions')
          .select()
          .eq('patient_id', userId)
          .eq('doctor_id', doctorId)
          .maybeSingle();

      if (existing != null) {
        return ChatModel.fromJson(existing);
      }

      final chatJson = {
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'doctor_avatar': doctorAvatar,
        'patient_id': userId,
        'last_message': 'Chat started after appointment approval',
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_count': 0,
        'is_active': true,
      };

      final data = await _supabase
          .from('chat_sessions')
          .insert(chatJson)
          .select()
          .single();

      return ChatModel.fromJson(data);
    } catch (e) {
      print('Error starting chat: $e');
      return null;
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
      // Check if chat already exists
      final existing = await _supabase
          .from('chat_sessions')
          .select()
          .eq('patient_id', patientId)
          .eq('doctor_id', doctorId)
          .maybeSingle();

      if (existing != null) {
        print('Chat already exists for this patient-doctor pair');
        return ChatModel.fromJson(existing);
      }

      final chatJson = {
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'doctor_avatar': doctorAvatar,
        'patient_id': patientId,
        'last_message': 'Appointment approved! Chat is now available.',
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_count': 0,
        'is_active': true,
      };

      final data = await _supabase
          .from('chat_sessions')
          .insert(chatJson)
          .select()
          .single();

      print('✅ Chat automatically created for approved appointment');
      return ChatModel.fromJson(data);
    } catch (e) {
      print('Error auto-creating chat: $e');
      return null;
    }
  }

  /// Search chats
  Future<List<ChatModel>> searchChats(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _supabase
          .from('chat_sessions')
          .select()
          .eq('patient_id', userId)
          .ilike('doctor_name', '%$query%');

      return (data as List).map((json) => ChatModel.fromJson(json)).toList();
    } catch (e) {
      print('Error searching chats: $e');
      return [];
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final data = await _supabase
          .from('chat_sessions')
          .select('unread_count')
          .eq('patient_id', userId);

      int total = 0;
      for (final row in data) {
        total += (row['unread_count'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Update user online status
  Future<bool> setUserPresence(String userId, bool isOnline) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_online': isOnline}).eq('id', userId);
      print('User online status updated: $isOnline');
      return true;
    } catch (e) {
      print('Error updating presence: $e');
      return false;
    }
  }

  /// Get user online status
  Future<bool> getUserPresence(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('is_online')
          .eq('id', userId)
          .single();
      return data['is_online'] ?? false;
    } catch (e) {
      print('Error getting user presence: $e');
      return false;
    }
  }

  /// Get unread chat count for doctor side
  Future<int> getUnreadCountForDoctor(String doctorId) async {
    try {
      final data = await _supabase
          .from('chat_sessions')
          .select('unread_count')
          .eq('doctor_id', doctorId);

      int total = 0;
      for (final row in data) {
        total += (row['unread_count'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Get all chats for doctor
  Future<List<ChatModel>> getChatsForDoctor(String doctorId) async {
    try {
      final data = await _supabase
          .from('chat_sessions')
          .select()
          .eq('doctor_id', doctorId)
          .order('last_message_time', ascending: false);

      return (data as List).map((json) {
        // Transform doctor-side chat format
        return ChatModel(
          id: json['id'] ?? '',
          doctorId: json['doctor_id'] ?? '',
          doctorName: json['doctor_name'] ?? '',
          doctorAvatar: json['doctor_avatar'] ?? '',
          lastMessage: json['last_message'] ?? '',
          lastMessageTime: DateTime.parse(
              json['last_message_time'] ?? DateTime.now().toIso8601String()),
          unreadCount: json['unread_count'] ?? 0,
          isActive: json['is_active'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error fetching doctor chats: $e');
      return [];
    }
  }
}
