import 'package:doctor_consultation_app/models/consultation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  static final ConsultationService _instance = ConsultationService._internal();

  factory ConsultationService() {
    return _instance;
  }

  ConsultationService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all consultations
  Future<List<ConsultationModel>> getConsultations(String userId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('user_id', userId)
          .order('scheduled_time', ascending: false);

      return (data as List)
          .map((json) => ConsultationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching consultations: $e');
      return [];
    }
  }

  /// Get upcoming consultations
  Future<List<ConsultationModel>> getUpcomingConsultations(
      String userId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('user_id', userId)
          .eq('status', 'scheduled')
          .gte('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time', ascending: true);

      return (data as List)
          .map((json) => ConsultationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching upcoming consultations: $e');
      return [];
    }
  }

  /// Get completed consultations
  Future<List<ConsultationModel>> getCompletedConsultations(
      String userId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('ended_at', ascending: false);

      return (data as List)
          .map((json) => ConsultationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching completed consultations: $e');
      return [];
    }
  }

  /// Get consultation details
  Future<ConsultationModel?> getConsultationDetails(
      String consultationId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('id', consultationId)
          .maybeSingle();

      if (data != null) {
        return ConsultationModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching consultation details: $e');
      return null;
    }
  }

  /// Start consultation
  Future<bool> startConsultation(String consultationId) async {
    try {
      await _supabase.from('consultations').update({
        'status': 'ongoing',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', consultationId);
      return true;
    } catch (e) {
      print('Error starting consultation: $e');
      return false;
    }
  }

  /// End consultation
  Future<bool> endConsultation(String consultationId, String? summary) async {
    try {
      await _supabase.from('consultations').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
        'summary': summary,
      }).eq('id', consultationId);
      return true;
    } catch (e) {
      print('Error ending consultation: $e');
      return false;
    }
  }

  /// Cancel consultation
  Future<bool> cancelConsultation(String consultationId) async {
    try {
      await _supabase
          .from('consultations')
          .update({'status': 'cancelled'}).eq('id', consultationId);
      return true;
    } catch (e) {
      print('Error cancelling consultation: $e');
      return false;
    }
  }

  /// Reschedule consultation
  Future<bool> rescheduleConsultation(
      String consultationId, DateTime newTime) async {
    try {
      await _supabase
          .from('consultations')
          .update({'scheduled_time': newTime.toIso8601String()}).eq(
              'id', consultationId);
      return true;
    } catch (e) {
      print('Error rescheduling consultation: $e');
      return false;
    }
  }

  /// Get recording URL
  Future<String?> getRecordingUrl(String consultationId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select('recording_url')
          .eq('id', consultationId)
          .maybeSingle();

      return data?['recording_url'];
    } catch (e) {
      return null;
    }
  }

  /// Download consultation recording
  Future<bool> downloadRecording(String consultationId) async {
    // Placeholder – actual download logic depends on storage setup
    return true;
  }

  /// Share consultation recording
  Future<bool> shareRecording(
      String consultationId, List<String> recipients) async {
    // Placeholder – actual share logic depends on messaging setup
    return true;
  }

  /// Generate meeting link
  Future<String?> generateMeetingLink(String consultationId) async {
    return 'https://videocall.example.com/room/$consultationId';
  }

  /// Get consultation by appointment
  Future<ConsultationModel?> getConsultationByAppointment(
      String appointmentId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (data != null) {
        return ConsultationModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching consultation by appointment: $e');
      return null;
    }
  }
}
