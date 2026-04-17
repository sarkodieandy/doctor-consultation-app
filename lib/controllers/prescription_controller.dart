import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/services/prescription_service.dart';
import 'package:get/get.dart';

class PrescriptionController extends GetxController {
  final _prescriptionService = PrescriptionService();

  final allPrescriptions = <PrescriptionModel>[].obs;
  final activePrescriptions = <PrescriptionModel>[].obs;
  final completedPrescriptions = <PrescriptionModel>[].obs;
  final selectedPrescription = Rxn<PrescriptionModel>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _userId = Get.arguments ?? 'user_123';
    fetchAllPrescriptions();
  }

  /// Fetch all prescriptions
  Future<void> fetchAllPrescriptions() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _prescriptionService.getPrescriptions(_userId ?? '');
      allPrescriptions.assignAll(result);

      // Separate by status
      activePrescriptions.assignAll(result.where((p) => p.isActive).toList());
      completedPrescriptions
          .assignAll(result.where((p) => !p.isActive).toList());
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch active prescriptions
  Future<void> fetchActivePrescriptions() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result =
          await _prescriptionService.getActivePrescriptions(_userId ?? '');
      activePrescriptions.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch completed prescriptions
  Future<void> fetchCompletedPrescriptions() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result =
          await _prescriptionService.getCompletedPrescriptions(_userId ?? '');
      completedPrescriptions.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Get prescription details
  Future<void> getPrescriptionDetails(String prescriptionId) async {
    try {
      isLoading(true);
      errorMessage(null);
      final result =
          await _prescriptionService.getPrescriptionDetails(prescriptionId);
      selectedPrescription(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Download prescription PDF
  Future<bool> downloadPrescription(String prescriptionId) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success =
          await _prescriptionService.downloadPrescriptionPDF(prescriptionId);

      if (success) {
        errorMessage(null);
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Share prescription
  Future<bool> sharePrescription(
    String prescriptionId,
    List<String> recipients,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _prescriptionService.sharePrescription(
        prescriptionId,
        recipients,
      );

      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Get prescription by appointment
  Future<PrescriptionModel?> getPrescriptionByAppointment(
    String appointmentId,
  ) async {
    try {
      return await _prescriptionService
          .getPrescriptionByAppointment(appointmentId);
    } catch (e) {
      errorMessage(e.toString());
      return null;
    }
  }
}
