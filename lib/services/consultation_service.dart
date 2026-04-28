import 'package:doctor_consultation_app/models/consultation_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';

class ConsultationService {
  static final ConsultationService _instance = ConsultationService._internal();

  factory ConsultationService() {
    return _instance;
  }

  ConsultationService._internal();
  final _store = UiMockStore.instance;

  /// Get all consultations
  Future<List<ConsultationModel>> getConsultations(String userId) async {
    final consultations = _store.consultations
        .where((consultation) => consultation.userId == userId)
        .toList();
    consultations.sort(
      (left, right) => right.scheduledTime.compareTo(left.scheduledTime),
    );
    return consultations;
  }

  /// Get upcoming consultations
  Future<List<ConsultationModel>> getUpcomingConsultations(
      String userId) async {
    final now = DateTime.now();
    final consultations = _store.consultations
        .where(
          (consultation) =>
              consultation.userId == userId &&
              consultation.status == 'scheduled' &&
              consultation.scheduledTime.isAfter(now),
        )
        .toList();
    consultations.sort(
      (left, right) => left.scheduledTime.compareTo(right.scheduledTime),
    );
    return consultations;
  }

  /// Get completed consultations
  Future<List<ConsultationModel>> getCompletedConsultations(
      String userId) async {
    final consultations = _store.consultations
        .where((consultation) =>
            consultation.userId == userId && consultation.status == 'completed')
        .toList();
    consultations.sort(
      (left, right) => (right.endedAt ?? right.scheduledTime)
          .compareTo(left.endedAt ?? left.scheduledTime),
    );
    return consultations;
  }

  /// Get consultation details
  Future<ConsultationModel?> getConsultationDetails(
      String consultationId) async {
    try {
      return _store.consultations.firstWhere(
        (consultation) => consultation.id == consultationId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Start consultation
  Future<bool> startConsultation(String consultationId) async {
    final index = _store.consultations.indexWhere(
      (consultation) => consultation.id == consultationId,
    );
    if (index == -1) return false;
    _store.consultations[index] = _store.consultations[index].copyWith(
      status: 'ongoing',
      startedAt: DateTime.now(),
    );
    return true;
  }

  /// End consultation
  Future<bool> endConsultation(String consultationId, String? summary) async {
    final index = _store.consultations.indexWhere(
      (consultation) => consultation.id == consultationId,
    );
    if (index == -1) return false;
    _store.consultations[index] = _store.consultations[index].copyWith(
      status: 'completed',
      endedAt: DateTime.now(),
      summary: summary,
    );
    return true;
  }

  /// Cancel consultation
  Future<bool> cancelConsultation(String consultationId) async {
    final index = _store.consultations.indexWhere(
      (consultation) => consultation.id == consultationId,
    );
    if (index == -1) return false;
    _store.consultations[index] =
        _store.consultations[index].copyWith(status: 'cancelled');
    return true;
  }

  /// Reschedule consultation
  Future<bool> rescheduleConsultation(
      String consultationId, DateTime newTime) async {
    final index = _store.consultations.indexWhere(
      (consultation) => consultation.id == consultationId,
    );
    if (index == -1) return false;
    _store.consultations[index] =
        _store.consultations[index].copyWith(scheduledTime: newTime);
    return true;
  }

  /// Get recording URL
  Future<String?> getRecordingUrl(String consultationId) async {
    return 'local-recording://$consultationId';
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
    return 'preview-room://$consultationId';
  }

  /// Get consultation by appointment
  Future<ConsultationModel?> getConsultationByAppointment(
      String appointmentId) async {
    try {
      return _store.consultations.firstWhere(
        (consultation) => consultation.appointmentId == appointmentId,
      );
    } catch (_) {
      return null;
    }
  }
}
