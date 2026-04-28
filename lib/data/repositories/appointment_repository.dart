import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/services/ui_data_service.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';

class AppointmentRepository {
  final UiDataService _local = UiDataService();
  final AuthService _authService = AuthService();

  Future<String?> bookAppointment({
    required String doctorId,
    required String userId,
    required DateTime appointmentDate,
    required String timeSlot,
  }) async {
    // UI-only: Use local/mock data
    await _local.bookAppointment(userId, doctorId, appointmentDate, timeSlot);
    return null;
  }

  Future<List<AppointmentModel>> fetchUserAppointments(String userId) async {
    // UI-only: Use local/mock data
    return await _local.getUserAppointments(userId);
  }

  Future<List<AppointmentModel>> fetchUpcomingAppointments(
      String userId) async {
    // UI-only: Use local/mock data
    return await _local.getUpcomingAppointments(userId);
  }

  Future<List<AppointmentModel>> fetchDoctorAppointments() async {
    // UI-only: Use local/mock data
    final doctorId = _authService.currentUser?.id ?? '';
    return _local.getDoctorAppointments(doctorId);
  }

  Future<bool> cancelAppointment(String appointmentId, String userId) async {
    // UI-only: Use local/mock data
    return await _local.cancelAppointment(appointmentId, userId);
  }

  Future<bool> addReview(
      String appointmentId, String userId, double rating, String review) async {
    // UI-only: Use local/mock data
    return await _local.addReview(appointmentId, userId, rating, review);
  }

  Future<bool> approveAppointment(String appointmentId, String doctorId) async {
    // UI-only: Use local/mock data
    return await _local.approveAppointment(appointmentId, doctorId);
  }

  Future<bool> rejectAppointment(String appointmentId, String doctorId) async {
    // UI-only: Use local/mock data
    return await _local.rejectAppointment(appointmentId, doctorId);
  }

  Future<bool> completeAppointment(
      String appointmentId, String doctorId) async {
    // UI-only: Use local/mock data
    return await _local.completeAppointment(appointmentId, doctorId);
  }
}
