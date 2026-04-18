import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();

  factory PrescriptionService() {
    return _instance;
  }

  PrescriptionService._internal();

  final _supabase = Supabase.instance.client;

  Future<PrescriptionModel> _loadWithMedicines(
      Map<String, dynamic> json) async {
    final prescriptionId = json['id'];
    final medsData = await _supabase
        .from('medicines')
        .select()
        .eq('prescription_id', prescriptionId);

    final medicines =
        (medsData as List).map((m) => Medicine.fromJson(m)).toList();
    return PrescriptionModel.fromJson(json, medicines: medicines);
  }

  /// Get all prescriptions
  Future<List<PrescriptionModel>> getPrescriptions(String userId) async {
    try {
      final data = await _supabase
          .from('prescriptions')
          .select()
          .eq('patient_id', userId)
          .order('prescribed_date', ascending: false);

      final List<PrescriptionModel> results = [];
      for (final json in data) {
        results.add(await _loadWithMedicines(json));
      }
      return results;
    } catch (e) {
      print('Error fetching prescriptions: $e');
      return [];
    }
  }

  /// Get active prescriptions
  Future<List<PrescriptionModel>> getActivePrescriptions(String userId) async {
    try {
      final data = await _supabase
          .from('prescriptions')
          .select()
          .eq('patient_id', userId)
          .eq('status', 'active')
          .order('prescribed_date', ascending: false);

      final List<PrescriptionModel> results = [];
      for (final json in data) {
        results.add(await _loadWithMedicines(json));
      }
      return results;
    } catch (e) {
      print('Error fetching active prescriptions: $e');
      return [];
    }
  }

  /// Get completed prescriptions
  Future<List<PrescriptionModel>> getCompletedPrescriptions(
      String userId) async {
    try {
      final data = await _supabase
          .from('prescriptions')
          .select()
          .eq('patient_id', userId)
          .eq('status', 'completed')
          .order('prescribed_date', ascending: false);

      final List<PrescriptionModel> results = [];
      for (final json in data) {
        results.add(await _loadWithMedicines(json));
      }
      return results;
    } catch (e) {
      print('Error fetching completed prescriptions: $e');
      return [];
    }
  }

  /// Get prescription details
  Future<PrescriptionModel?> getPrescriptionDetails(
      String prescriptionId) async {
    try {
      final data = await _supabase
          .from('prescriptions')
          .select()
          .eq('id', prescriptionId)
          .maybeSingle();

      if (data != null) {
        return await _loadWithMedicines(data);
      }
      return null;
    } catch (e) {
      print('Error fetching prescription details: $e');
      return null;
    }
  }

  /// Add prescription
  Future<bool> addPrescription(PrescriptionModel prescription) async {
    try {
      final json = prescription.toJson();
      json.remove('id');
      final medicines = json.remove('medicines') as List?;

      final inserted =
          await _supabase.from('prescriptions').insert(json).select().single();

      final prescriptionId = inserted['id'];

      if (medicines != null && medicines.isNotEmpty) {
        final medsToInsert = prescription.medicines.map((m) {
          final mJson = m.toJson();
          mJson.remove('id');
          mJson['prescription_id'] = prescriptionId;
          return mJson;
        }).toList();

        await _supabase.from('medicines').insert(medsToInsert);
      }

      return true;
    } catch (e) {
      print('Error adding prescription: $e');
      return false;
    }
  }

  /// Update prescription
  Future<bool> updatePrescription(PrescriptionModel prescription) async {
    try {
      final json = prescription.toJson();
      json.remove('id');
      json.remove('medicines');

      await _supabase
          .from('prescriptions')
          .update(json)
          .eq('id', prescription.id);
      return true;
    } catch (e) {
      print('Error updating prescription: $e');
      return false;
    }
  }

  /// Delete prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      // Medicines deleted by cascade
      await _supabase.from('prescriptions').delete().eq('id', prescriptionId);
      return true;
    } catch (e) {
      print('Error deleting prescription: $e');
      return false;
    }
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
      final data = await _supabase
          .from('prescriptions')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (data != null) {
        return await _loadWithMedicines(data);
      }
      return null;
    } catch (e) {
      print('Error fetching prescription by appointment: $e');
      return null;
    }
  }
}
