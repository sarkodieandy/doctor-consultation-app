import 'package:doctor_consultation_app/models/prescription_model.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();

  factory PrescriptionService() {
    return _instance;
  }

  PrescriptionService._internal();

  final List<PrescriptionModel> _mockPrescriptions = [
    PrescriptionModel(
      id: 'presc_1',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      appointmentId: 'apt_1',
      prescribedDate: DateTime.now().subtract(Duration(days: 5)),
      expiryDate: DateTime.now().add(Duration(days: 25)),
      medicines: [
        Medicine(
          id: 'med_1',
          name: 'Aspirin',
          dosage: '500mg',
          frequency: 'Twice daily',
          duration: 7,
          instructions: 'Take with food. Do not crush tablet.',
          sideEffects: ['Nausea', 'Headache'],
        ),
        Medicine(
          id: 'med_2',
          name: 'Paracetamol',
          dosage: '650mg',
          frequency: 'Three times daily',
          duration: 5,
          instructions: 'Can be taken with or without food.',
          sideEffects: ['Rare'],
        ),
      ],
      notes: 'Take medications as per the schedule. Avoid alcohol.',
      status: 'active',
    ),
    PrescriptionModel(
      id: 'presc_2',
      doctorId: 'doc_2',
      doctorName: 'Dr. Joseph Cart',
      appointmentId: 'apt_2',
      prescribedDate: DateTime.now().subtract(Duration(days: 15)),
      expiryDate: DateTime.now().subtract(Duration(days: 5)),
      medicines: [
        Medicine(
          id: 'med_3',
          name: 'Amoxicillin',
          dosage: '250mg',
          frequency: 'Three times daily',
          duration: 7,
          instructions: 'Complete the full course. Take with or without food.',
          sideEffects: ['Allergic reactions', 'Diarrhea'],
        ),
      ],
      notes: 'Antibiotic course. Complete it fully.',
      status: 'completed',
    ),
  ];

  /// Get all prescriptions
  Future<List<PrescriptionModel>> getPrescriptions(String userId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _mockPrescriptions;
  }

  /// Get active prescriptions
  Future<List<PrescriptionModel>> getActivePrescriptions(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockPrescriptions.where((p) => p.isActive).toList();
  }

  /// Get completed prescriptions
  Future<List<PrescriptionModel>> getCompletedPrescriptions(
      String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockPrescriptions.where((p) => !p.isActive).toList();
  }

  /// Get prescription details
  Future<PrescriptionModel?> getPrescriptionDetails(
      String prescriptionId) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _mockPrescriptions.firstWhere((p) => p.id == prescriptionId);
    } catch (e) {
      return null;
    }
  }

  /// Add prescription
  Future<bool> addPrescription(PrescriptionModel prescription) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      _mockPrescriptions.add(prescription);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update prescription
  Future<bool> updatePrescription(PrescriptionModel prescription) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      final index =
          _mockPrescriptions.indexWhere((p) => p.id == prescription.id);
      if (index != -1) {
        _mockPrescriptions[index] = prescription;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      _mockPrescriptions.removeWhere((p) => p.id == prescriptionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Download prescription as PDF
  Future<bool> downloadPrescriptionPDF(String prescriptionId) async {
    try {
      await Future.delayed(Duration(seconds: 1));
      // Mock download
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Share prescription
  Future<bool> sharePrescription(
    String prescriptionId,
    List<String> recipients,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      // Mock share
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get prescription by appointment
  Future<PrescriptionModel?> getPrescriptionByAppointment(
    String appointmentId,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _mockPrescriptions
          .firstWhere((p) => p.appointmentId == appointmentId);
    } catch (e) {
      return null;
    }
  }
}
