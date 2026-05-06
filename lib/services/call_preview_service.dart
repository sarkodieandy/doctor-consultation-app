import 'package:doctor_consultation_app/models/consultation_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';

class CallPreviewService {
  static final CallPreviewService _instance = CallPreviewService._internal();

  factory CallPreviewService() {
    return _instance;
  }

  CallPreviewService._internal();

  final _store = UiMockStore.instance;

  Future<String> getToken({
    required String channelId,
    required String userId,
  }) async {
    return 'preview-session-$channelId-$userId';
  }

  Future<bool> startConsultation({
    required String appointmentId,
    required String doctorId,
    required String patientId,
    required String channelId,
  }) async {
    final index = _store.consultations.indexWhere(
      (consultation) => consultation.appointmentId == appointmentId,
    );

    if (index != -1) {
      _store.consultations[index] = _store.consultations[index].copyWith(
        status: 'ongoing',
        startedAt: DateTime.now(),
      );
      return true;
    }

    _store.consultations.add(
      ConsultationModel(
        id: _store.nextId('consultation'),
        appointmentId: appointmentId,
        doctorId: doctorId,
        doctorName: _store.findUserById(doctorId)?.fullName ?? 'Doctor',
        doctorAvatar: '',
        userId: patientId,
        scheduledTime: DateTime.now(),
        startedAt: DateTime.now(),
        duration: const Duration(minutes: 30),
        status: 'ongoing',
        consultationType: 'video',
      ),
    );
    return true;
  }

  Future<bool> endConsultation({
    required String appointmentId,
    required int durationSeconds,
  }) async {
    final index = _store.consultations.indexWhere(
      (consultation) => consultation.appointmentId == appointmentId,
    );
    if (index == -1) return false;

    _store.consultations[index] = _store.consultations[index].copyWith(
      status: 'completed',
      endedAt: DateTime.now(),
      duration: Duration(seconds: durationSeconds),
    );
    return true;
  }

  Future<bool> canStartVideoCall(String patientId, String doctorId) async {
    return _store.appointments.any(
      (appointment) =>
          appointment.userId == patientId &&
          appointment.doctorId == doctorId &&
          appointment.status == 'confirmed',
    );
  }

  Future<Map<String, dynamic>?> getAppointmentDetails(
      String appointmentId) async {
    try {
      final appointment = _store.appointments.firstWhere(
        (item) => item.id == appointmentId,
      );
      return appointment.toJson();
    } catch (_) {
      return null;
    }
  }

  Future<bool> logCallMetrics({
    required String consultationId,
    required double latency,
    required double packetLoss,
    required String audioQuality,
    required String videoQuality,
  }) async {
    return true;
  }
}
