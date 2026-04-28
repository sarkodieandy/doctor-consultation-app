import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();

  factory PrescriptionService() {
    return _instance;
  }

  PrescriptionService._internal();
  final _store = UiMockStore.instance;

  /// Get all prescriptions
  Future<List<PrescriptionModel>> getPrescriptions(String userId) async {
    final prescriptions = _store.prescriptions
        .where((prescription) => prescription.patientId == userId)
        .toList();
    prescriptions.sort(
      (left, right) => right.prescribedDate.compareTo(left.prescribedDate),
    );
    return prescriptions;
  }

  /// Get active prescriptions
  Future<List<PrescriptionModel>> getActivePrescriptions(String userId) async {
    return _store.prescriptions
        .where((prescription) =>
            prescription.patientId == userId && prescription.status == 'active')
        .toList();
  }

  /// Get completed prescriptions
  Future<List<PrescriptionModel>> getCompletedPrescriptions(
      String userId) async {
    return _store.prescriptions
        .where((prescription) =>
            prescription.patientId == userId &&
            prescription.status == 'completed')
        .toList();
  }

  /// Get prescription details
  Future<PrescriptionModel?> getPrescriptionDetails(
      String prescriptionId) async {
    try {
      return _store.prescriptions.firstWhere(
        (prescription) => prescription.id == prescriptionId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Add prescription
  Future<bool> addPrescription(PrescriptionModel prescription) async {
    final normalized = prescription.id.isEmpty
        ? prescription.copyWith(
            id: _store.nextId('prescription'),
            medicines: prescription.medicines
                .map(
                  (medicine) => medicine.copyWith(
                    id: medicine.id.isEmpty
                        ? _store.nextId('medicine')
                        : medicine.id,
                  ),
                )
                .toList(),
          )
        : prescription;
    _store.prescriptions.add(normalized);
    return true;
  }

  /// Update prescription
  Future<bool> updatePrescription(PrescriptionModel prescription) async {
    final index = _store.prescriptions.indexWhere(
      (item) => item.id == prescription.id,
    );
    if (index == -1) return false;
    _store.prescriptions[index] = prescription;
    return true;
  }

  /// Delete prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    _store.prescriptions
        .removeWhere((prescription) => prescription.id == prescriptionId);
    return true;
  }

  /// Download prescription as PDF
  Future<bool> downloadPrescriptionPDF(String prescriptionId) async {
    // Placeholder – actual PDF generation depends on setup
    return true;
  }

  /// Share prescription
  Future<bool> sharePrescription(
      String prescriptionId, List<String> recipients) async {
    // Placeholder – actual sharing depends on messaging setup
    return true;
  }

  /// Get prescription by appointment
  Future<PrescriptionModel?> getPrescriptionByAppointment(
      String appointmentId) async {
    try {
      return _store.prescriptions.firstWhere(
        (prescription) => prescription.appointmentId == appointmentId,
      );
    } catch (_) {
      return null;
    }
  }
}
