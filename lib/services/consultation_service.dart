import 'package:doctor_consultation_app/models/consultation_model.dart';

class ConsultationService {
  static final ConsultationService _instance = ConsultationService._internal();

  factory ConsultationService() {
    return _instance;
  }

  ConsultationService._internal();

  final List<ConsultationModel> _mockConsultations = [
    ConsultationModel(
      id: 'cons_1',
      appointmentId: 'apt_1',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      doctorAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      userId: 'user_123',
      scheduledTime: DateTime.now().add(Duration(hours: 2)),
      duration: Duration(minutes: 30),
      status: 'scheduled',
      consultationType: 'video',
      roomId: 'room_001',
    ),
    ConsultationModel(
      id: 'cons_2',
      appointmentId: 'apt_2',
      doctorId: 'doc_2',
      doctorName: 'Dr. Joseph Cart',
      doctorAvatar:
          'https://images.unsplash.com/photo-1622902046580-2b47f47f5471?w=400',
      userId: 'user_123',
      scheduledTime: DateTime.now().subtract(Duration(days: 2)),
      duration: Duration(minutes: 20),
      status: 'completed',
      consultationType: 'video',
      roomId: 'room_002',
      startedAt: DateTime.now().subtract(Duration(days: 2, hours: 1)),
      endedAt:
          DateTime.now().subtract(Duration(days: 2, hours: 1, minutes: 20)),
      recordingUrl: 'https://example.com/recordings/cons_2.mp4',
      summary: 'Discussed dental hygiene and scheduled follow-up',
    ),
  ];

  /// Get all consultations
  Future<List<ConsultationModel>> getConsultations(String userId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _mockConsultations;
  }

  /// Get upcoming consultations
  Future<List<ConsultationModel>> getUpcomingConsultations(
    String userId,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockConsultations
        .where((c) => c.status == 'scheduled' && c.isUpcoming)
        .toList();
  }

  /// Get completed consultations
  Future<List<ConsultationModel>> getCompletedConsultations(
    String userId,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockConsultations.where((c) => c.isCompleted).toList();
  }

  /// Get consultation details
  Future<ConsultationModel?> getConsultationDetails(
    String consultationId,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _mockConsultations.firstWhere((c) => c.id == consultationId);
    } catch (e) {
      return null;
    }
  }

  /// Start consultation
  Future<bool> startConsultation(String consultationId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final index =
          _mockConsultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        final consultation = _mockConsultations[index];
        _mockConsultations[index] = consultation.copyWith(
          status: 'ongoing',
          startedAt: DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// End consultation
  Future<bool> endConsultation(
    String consultationId,
    String? summary,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final index =
          _mockConsultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        final consultation = _mockConsultations[index];
        _mockConsultations[index] = consultation.copyWith(
          status: 'completed',
          endedAt: DateTime.now(),
          summary: summary,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cancel consultation
  Future<bool> cancelConsultation(String consultationId) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      final index =
          _mockConsultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        final consultation = _mockConsultations[index];
        _mockConsultations[index] = consultation.copyWith(status: 'cancelled');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Reschedule consultation
  Future<bool> rescheduleConsultation(
    String consultationId,
    DateTime newTime,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final index =
          _mockConsultations.indexWhere((c) => c.id == consultationId);
      if (index != -1) {
        final consultation = _mockConsultations[index];
        _mockConsultations[index] = consultation.copyWith(
          scheduledTime: newTime,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get recording URL
  Future<String?> getRecordingUrl(String consultationId) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      final consultation =
          _mockConsultations.firstWhere((c) => c.id == consultationId);
      return consultation.recordingUrl;
    } catch (e) {
      return null;
    }
  }

  /// Download consultation recording
  Future<bool> downloadRecording(String consultationId) async {
    try {
      await Future.delayed(Duration(seconds: 1));
      // Mock download
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Share consultation recording
  Future<bool> shareRecording(
    String consultationId,
    List<String> recipients,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      // Mock share
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate meeting link
  Future<String?> generateMeetingLink(String consultationId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return 'https://videocall.example.com/room/${consultationId}';
  }

  /// Get consultation by appointment
  Future<ConsultationModel?> getConsultationByAppointment(
    String appointmentId,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _mockConsultations
          .firstWhere((c) => c.appointmentId == appointmentId);
    } catch (e) {
      return null;
    }
  }
}
