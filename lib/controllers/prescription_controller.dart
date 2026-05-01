import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:doctor_consultation_app/data/repositories/prescription_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class PrescriptionController extends GetxController {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  final _prescriptionRepo = PrescriptionRepository();

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
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        return;
      }
      fetchAllPrescriptions();
    });
  }

  /// Fetch all prescriptions
  Future<void> fetchAllPrescriptions() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _prescriptionRepo.fetchPrescriptions(_userId ?? '');
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
      final all = await _prescriptionRepo.fetchPrescriptions(_userId ?? '');
      final result = all.where((p) => p.isActive).toList();
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
      final all = await _prescriptionRepo.fetchPrescriptions(_userId ?? '');
      final result = all.where((p) => !p.isActive).toList();
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
          await _prescriptionRepo.getPrescriptionDetails(prescriptionId);
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
          await _prescriptionRepo.downloadPrescriptionPDF(prescriptionId);

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

      final success = await _prescriptionRepo.sharePrescription(
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
      return await _prescriptionRepo
          .getPrescriptionByAppointment(appointmentId);
    } catch (e) {
      errorMessage(e.toString());
      return null;
    }
  }

  Future<bool> createPrescription(PrescriptionModel prescription) async {
    try {
      isLoading(true);
      errorMessage(null);
      final success = await _prescriptionRepo.createPrescription(prescription);
      if (success) {
        await fetchAllPrescriptions();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> sendMedicineReminder(
    PrescriptionModel prescription,
    Medicine medicine,
  ) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      errorMessage('User ID not found');
      return false;
    }

    try {
      await _notificationService.sendMedicationReminder(
        prescriptionId: prescription.id,
        medicineId: medicine.id,
        medicineName: medicine.name,
        dosage: medicine.dosage,
        frequency: medicine.frequency,
        userId: userId,
      );
      return true;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    }
  }
}
