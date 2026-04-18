import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:doctor_consultation_app/services/api_service.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:doctor_consultation_app/services/payment_service.dart';
import 'package:get/get.dart';

class AppointmentController extends GetxController {
  final _apiService = ApiService();
  final _authService = AuthService();
  final _paymentService = PaymentService();
  final _notificationService = NotificationService();

  final doctors = <DoctorModel>[].obs;
  final appointments = <AppointmentModel>[].obs;
  final upcomingAppointments = <AppointmentModel>[].obs;
  final payments = <PaymentModel>[].obs;
  final isLoading = false.obs;
  final selectedDoctor = Rxn<DoctorModel>();
  final errorMessage = Rxn<String>();

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
  }

  /// Fetch all doctors
  Future<void> fetchDoctors() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _apiService.getDoctors();
      doctors.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch doctors by specialty
  Future<void> fetchDoctorsBySpecialty(String specialty) async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _apiService.getDoctorsBySpecialty(specialty);
      doctors.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Search doctors
  Future<void> searchDoctors(String query) async {
    try {
      isLoading(true);
      errorMessage(null);
      if (query.isEmpty) {
        await fetchDoctors();
      } else {
        final result = await _apiService.searchDoctors(query);
        doctors.assignAll(result);
      }
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Get doctor details
  Future<void> getDoctorDetails(String doctorId) async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _apiService.getDoctorById(doctorId);
      selectedDoctor(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Book appointment
  Future<bool> bookAppointment(
    String doctorId,
    DateTime appointmentDate,
    String timeSlot,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      if (_userId == null || _userId!.isEmpty) {
        throw 'User ID not found';
      }

      final success = await _apiService.bookAppointment(
        _userId!,
        doctorId,
        appointmentDate,
        timeSlot,
      );

      if (success) {
        await fetchUserAppointments();
        await fetchUpcomingAppointments();
      }

      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Fetch user appointments
  Future<void> fetchUserAppointments() async {
    try {
      if (_userId == null || _userId!.isEmpty) return;

      isLoading(true);
      errorMessage(null);
      final result = await _apiService.getUserAppointments(_userId!);
      appointments.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch upcoming appointments
  Future<void> fetchUpcomingAppointments() async {
    try {
      if (_userId == null || _userId!.isEmpty) return;

      isLoading(true);
      errorMessage(null);
      final result = await _apiService.getUpcomingAppointments(_userId!);
      upcomingAppointments.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      isLoading(true);
      errorMessage(null);

      if (_userId == null || _userId!.isEmpty) {
        throw 'User ID not found';
      }

      final success =
          await _apiService.cancelAppointment(appointmentId, _userId!);

      if (success) {
        await fetchUserAppointments();
        await fetchUpcomingAppointments();
      }

      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Add review to appointment
  Future<bool> addReview(
    String appointmentId,
    double rating,
    String review,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      if (_userId == null || _userId!.isEmpty) {
        throw 'User ID not found';
      }

      final success = await _apiService.addReview(
        appointmentId,
        _userId!,
        rating,
        review,
      );

      if (success) {
        await fetchUserAppointments();
      }

      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Get payment history
  Future<void> fetchPaymentHistory() async {
    try {
      if (_userId == null || _userId!.isEmpty) return;

      isLoading(true);
      errorMessage(null);
      final result = await _paymentService.getPaymentHistory(_userId!);
      payments.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Send appointment reminder notification
  Future<void> sendAppointmentReminder(
    String appointmentId,
    String doctorName,
    DateTime appointmentTime,
  ) async {
    try {
      await _notificationService.sendAppointmentReminder(
        appointmentId: appointmentId,
        doctorName: doctorName,
        appointmentTime: appointmentTime,
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// Send appointment confirmed notification
  Future<void> sendAppointmentConfirmed(
    String appointmentId,
    String doctorName,
    DateTime appointmentTime,
  ) async {
    try {
      await _notificationService.sendAppointmentConfirmed(
        appointmentId: appointmentId,
        doctorName: doctorName,
        appointmentTime: appointmentTime,
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// Send payment success notification
  Future<void> sendPaymentNotification(
    String paymentId,
    double amount,
    String appointmentId,
  ) async {
    try {
      await _notificationService.sendPaymentSuccess(
        paymentId: paymentId,
        amount: amount,
        appointmentId: appointmentId,
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// Send review request notification
  Future<void> sendReviewRequest(
    String appointmentId,
    String doctorName,
  ) async {
    try {
      await _notificationService.sendReviewRequest(
        appointmentId: appointmentId,
        doctorName: doctorName,
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// Approve appointment (Doctor side) - Also creates chat session
  Future<bool> approveAppointment(
    String appointmentId,
    String doctorId,
    String doctorName,
    String doctorAvatar,
    String patientId,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      // Import chat service
      final chatService = await _importChatService();

      // Update appointment status to confirmed
      final apptUpdated = await _apiService.approveAppointment(
        appointmentId,
        doctorId,
      );

      if (apptUpdated) {
        // Auto-create chat session for approved appointment
        await chatService.autoCreateChatForApprovedAppointment(
          patientId,
          doctorId,
          doctorName,
          doctorAvatar,
        );

        // Send notification
        await sendAppointmentConfirmed(
          appointmentId,
          doctorName,
          DateTime.now(),
        );

        print('✅ Appointment approved and chat created');
        return true;
      }

      return false;
    } catch (e) {
      errorMessage(e.toString());
      print('❌ Error approving appointment: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Helper to import ChatService (avoids circular imports)
  Future<dynamic> _importChatService() async {
    // Dynamic import to avoid circular dependency
    // In actual implementation, pass through constructor
    return null; // TODO: Properly inject ChatService via constructor
  }
}
