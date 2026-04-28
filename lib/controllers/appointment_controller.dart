import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:doctor_consultation_app/data/repositories/appointment_repository.dart';
import 'package:doctor_consultation_app/data/repositories/doctor_repository.dart';
import 'package:doctor_consultation_app/data/repositories/chat_repository.dart';
import 'package:get/get.dart';

class AppointmentController extends GetxController {
  final _authService = AuthService();
  final _notificationService = NotificationService();

  final _doctorRepo = DoctorRepository();
  final _appointmentRepo = AppointmentRepository();
  final _chatRepo = ChatRepository();

  final doctors = <DoctorModel>[].obs;
  final appointments = <AppointmentModel>[].obs;
  final upcomingAppointments = <AppointmentModel>[].obs;
  final doctorAppointments = <AppointmentModel>[].obs;
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
      final result = await _doctorRepo.fetchDoctors();
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
      final result =
          await _doctorRepo.fetchDoctors(params: {'specialization': specialty});
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
        final result = await _doctorRepo.searchDoctors(query);
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
      final result = await _doctorRepo.getDoctorById(doctorId);
      selectedDoctor(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Book appointment
  Future<String?> bookAppointment(
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

      final appointmentId = await _appointmentRepo.bookAppointment(
        doctorId: doctorId,
        userId: _userId!,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
      );

      if (appointmentId != null) {
        await fetchUserAppointments();
        await fetchUpcomingAppointments();
      }

      return appointmentId;
    } catch (e) {
      errorMessage(e.toString());
      return null;
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
      final result = await _appointmentRepo.fetchUserAppointments(_userId!);
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
      final result = await _appointmentRepo.fetchUpcomingAppointments(_userId!);
      upcomingAppointments.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch doctor appointments
  Future<void> fetchDoctorAppointments() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _appointmentRepo.fetchDoctorAppointments();
      doctorAppointments.assignAll(result);
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
          await _appointmentRepo.cancelAppointment(appointmentId, _userId!);

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

      final success = await _appointmentRepo.addReview(
          appointmentId, _userId!, rating, review);

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

  /// Send appointment reminder notification
  Future<void> sendAppointmentReminder(
    String appointmentId,
    String doctorName,
    DateTime appointmentTime,
  ) async {
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      await _notificationService.sendAppointmentReminder(
        appointmentId: appointmentId,
        doctorName: doctorName,
        appointmentTime: appointmentTime,
        userId: userId,
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
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      await _notificationService.sendAppointmentConfirmed(
        appointmentId: appointmentId,
        doctorName: doctorName,
        appointmentTime: appointmentTime,
        userId: userId,
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
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      await _notificationService.sendPaymentSuccess(
        paymentId: paymentId,
        amount: amount,
        appointmentId: appointmentId,
        userId: userId,
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
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      await _notificationService.sendReviewRequest(
        appointmentId: appointmentId,
        doctorName: doctorName,
        userId: userId,
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

      final apptUpdated =
          await _appointmentRepo.approveAppointment(appointmentId, doctorId);

      if (apptUpdated) {
        await _chatRepo.startChat(doctorId, doctorName, doctorAvatar);
        await fetchDoctorAppointments();

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

  /// Reject appointment (Doctor side)
  Future<bool> rejectAppointment(
    String appointmentId,
    String doctorId,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final rejected =
          await _appointmentRepo.rejectAppointment(appointmentId, doctorId);
      if (rejected) {
        await fetchDoctorAppointments();
      }
      return rejected;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Complete appointment (Doctor side)
  Future<bool> completeAppointment(
    String appointmentId,
    String doctorId,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final completed =
          await _appointmentRepo.completeAppointment(appointmentId, doctorId);
      if (completed) {
        await fetchDoctorAppointments();
      }
      return completed;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }
}
