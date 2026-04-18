/// Agora Real-time Communication Service
/// Handles video/audio calls between doctors and patients
///
/// Features:
/// - Video/audio call management
/// - Token generation via backend
/// - Real-time audio/video toggling
/// - Connection quality monitoring

import 'package:supabase_flutter/supabase_flutter.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();

  factory AgoraService() {
    return _instance;
  }

  AgoraService._internal();

  // Get Agora App ID from: https://console.agora.io
  // Replace with your actual App ID
  static const String agoraAppId = ''; // TODO: Set your Agora App ID

  final _supabase = Supabase.instance.client;

  /// Generate Agora token from backend
  ///
  /// The token is generated via Supabase Edge Function
  /// Token expires in 3600 seconds (1 hour)
  Future<String> getToken({
    required String channelId,
    required String userId,
  }) async {
    try {
      print('🔑 Requesting Agora token for channel: $channelId, user: $userId');

      final response = await _supabase.functions.invoke(
        'generate-agora-token',
        body: {
          'channelId': channelId,
          'uid': userId,
        },
      );

      final token = (response.data as Map<String, dynamic>?)?['token'] ?? '';
      if (token.isEmpty) {
        print('❌ Empty token received');
        return '';
      }

      print('✅ Agora token generated successfully');
      return token;
    } catch (e) {
      print('❌ Error getting Agora token: $e');
      return '';
    }
  }

  /// Save consultation session to database
  Future<bool> startConsultation({
    required String appointmentId,
    required String doctorId,
    required String patientId,
    required String channelId,
  }) async {
    try {
      print('📝 Starting consultation session...');

      final data = await _supabase
          .from('consultations')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (data != null) {
        // Update existing consultation
        await _supabase.from('consultations').update({
          'status': 'ongoing',
          'room_id': channelId,
          'started_at': DateTime.now().toIso8601String(),
        }).eq('id', data['id']);
      } else {
        // Create new consultation
        await _supabase.from('consultations').insert({
          'appointment_id': appointmentId,
          'doctor_id': doctorId,
          'user_id': patientId,
          'room_id': channelId,
          'status': 'ongoing',
          'consultation_type': 'video',
          'duration_minutes': 30,
          'scheduled_time': DateTime.now().toIso8601String(),
          'started_at': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Consultation session started');
      return true;
    } catch (e) {
      print('❌ Error starting consultation: $e');
      return false;
    }
  }

  /// End consultation and save duration
  Future<bool> endConsultation({
    required String appointmentId,
    required int durationSeconds,
  }) async {
    try {
      print('⏹ Ending consultation...');

      final durationMinutes = (durationSeconds / 60).round();

      await _supabase.from('consultations').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
        'actual_duration_minutes': durationMinutes,
      }).eq('appointment_id', appointmentId);

      // Update appointment status to completed
      await _supabase
          .from('appointments')
          .update({'status': 'completed'}).eq('id', appointmentId);

      print('✅ Consultation ended. Duration: ${durationMinutes}m');
      return true;
    } catch (e) {
      print('❌ Error ending consultation: $e');
      return false;
    }
  }

  /// Check if user is eligible for video consultation
  /// (Must have confirmed appointment)
  Future<bool> canStartVideoCall(String patientId, String doctorId) async {
    try {
      final approved = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', patientId)
          .eq('doctor_id', doctorId)
          .eq('status', 'confirmed')
          .count(CountOption.exact);

      return approved.count > 0;
    } catch (e) {
      print('Error checking video call eligibility: $e');
      return false;
    }
  }

  /// Get appointment details for video call context
  Future<Map<String, dynamic>?> getAppointmentDetails(
      String appointmentId) async {
    try {
      return await _supabase
          .from('appointments')
          .select()
          .eq('id', appointmentId)
          .single();
    } catch (e) {
      print('Error fetching appointment details: $e');
      return null;
    }
  }

  /// Log call quality metrics for monitoring
  Future<bool> logCallMetrics({
    required String consultationId,
    required double latency,
    required double packetLoss,
    required String audioQuality,
    required String videoQuality,
  }) async {
    try {
      // This could be extended to store call metrics for analytics
      print(
          '📊 Call Metrics - Latency: ${latency}ms, Packet Loss: ${packetLoss}%');
      return true;
    } catch (e) {
      print('Error logging call metrics: $e');
      return false;
    }
  }
}
