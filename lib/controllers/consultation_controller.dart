import 'package:doctor_consultation_app/models/consultation_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/consultation_service.dart';
import 'package:get/get.dart';

class ConsultationController extends GetxController {
  final _authService = AuthService();
  final _consultationService = ConsultationService();

  final consultations = <ConsultationModel>[].obs;
  final upcomingConsultations = <ConsultationModel>[].obs;
  final completedConsultations = <ConsultationModel>[].obs;
  final selectedConsultation = Rxn<ConsultationModel>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    fetchConsultations();
  }

  /// Fetch all consultations
  Future<void> fetchConsultations() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _consultationService.getConsultations(_userId ?? '');
      consultations.assignAll(result);

      // Separate by status
      upcomingConsultations.assignAll(result
          .where((c) => c.status == 'scheduled' && c.isUpcoming)
          .toList());
      completedConsultations
          .assignAll(result.where((c) => c.isCompleted).toList());
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch upcoming consultations
  Future<void> fetchUpcomingConsultations() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result =
          await _consultationService.getUpcomingConsultations(_userId ?? '');
      upcomingConsultations.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch completed consultations
  Future<void> fetchCompletedConsultations() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result =
          await _consultationService.getCompletedConsultations(_userId ?? '');
      completedConsultations.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Get consultation details
  Future<void> getConsultationDetails(String consultationId) async {
    try {
      isLoading(true);
      errorMessage(null);
      final result =
          await _consultationService.getConsultationDetails(consultationId);
      selectedConsultation(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Start consultation
  Future<bool> startConsultation(String consultationId) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success =
          await _consultationService.startConsultation(consultationId);

      if (success) {
        await getConsultationDetails(consultationId);
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// End consultation
  Future<bool> endConsultation(
    String consultationId,
    String? summary,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _consultationService.endConsultation(
        consultationId,
        summary,
      );

      if (success) {
        await fetchConsultations();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Cancel consultation
  Future<bool> cancelConsultation(String consultationId) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success =
          await _consultationService.cancelConsultation(consultationId);

      if (success) {
        await fetchConsultations();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Reschedule consultation
  Future<bool> rescheduleConsultation(
    String consultationId,
    DateTime newTime,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _consultationService.rescheduleConsultation(
        consultationId,
        newTime,
      );

      if (success) {
        await fetchConsultations();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Get recording URL
  Future<String?> getRecordingUrl(String consultationId) async {
    try {
      return await _consultationService.getRecordingUrl(consultationId);
    } catch (e) {
      errorMessage(e.toString());
      return null;
    }
  }

  /// Download recording
  Future<bool> downloadRecording(String consultationId) async {
    try {
      isLoading(true);
      errorMessage(null);

      return await _consultationService.downloadRecording(consultationId);
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Share recording
  Future<bool> shareRecording(
    String consultationId,
    List<String> recipients,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      return await _consultationService.shareRecording(
        consultationId,
        recipients,
      );
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Generate meeting link
  Future<String?> generateMeetingLink(String consultationId) async {
    try {
      return await _consultationService.generateMeetingLink(consultationId);
    } catch (e) {
      errorMessage(e.toString());
      return null;
    }
  }
}
