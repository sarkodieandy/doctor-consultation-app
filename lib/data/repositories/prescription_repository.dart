import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/services/prescription_service.dart';

class PrescriptionRepository {
  final PrescriptionService _local = PrescriptionService();

  Future<List<PrescriptionModel>> fetchPrescriptions(String userId) async {
    return await _local.getPrescriptions(userId);
  }

  Future<PrescriptionModel?> getPrescriptionDetails(
      String prescriptionId) async {
    return await _local.getPrescriptionDetails(prescriptionId);
  }

  Future<PrescriptionModel?> getPrescriptionByAppointment(
      String appointmentId) async {
    return await _local.getPrescriptionByAppointment(appointmentId);
  }

  Future<bool> downloadPrescriptionPDF(String prescriptionId) async {
    return await _local.downloadPrescriptionPDF(prescriptionId);
  }

  Future<bool> sharePrescription(
      String prescriptionId, List<String> recipients) async {
    return await _local.sharePrescription(prescriptionId, recipients);
  }
}
