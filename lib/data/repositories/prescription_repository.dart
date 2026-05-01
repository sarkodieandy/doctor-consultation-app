import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/services/prescription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionRepository {
  final PrescriptionService _local = PrescriptionService();
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<PrescriptionModel>> fetchPrescriptions(String userId) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final prescriptions = await client
            .from('prescriptions')
            .select()
            .or('patient_id.eq.$userId,doctor_id.eq.$userId')
            .isFilter('deleted_at', null)
            .order('prescribed_date', ascending: false);

        final ids = prescriptions
            .map<String>((item) => (item['id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();
        final medicinesByPrescription = await _fetchMedicines(ids);

        return prescriptions.map<PrescriptionModel>((item) {
          final id = (item['id'] ?? '').toString();
          return PrescriptionModel.fromJson(
            Map<String, dynamic>.from(item),
            medicines: medicinesByPrescription[id] ?? const [],
          );
        }).toList();
      } catch (_) {
        // Keep local preview usable if Supabase tables are not migrated yet.
      }
    }
    return await _local.getPrescriptions(userId);
  }

  Future<PrescriptionModel?> getPrescriptionDetails(
      String prescriptionId) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final item = await client
            .from('prescriptions')
            .select()
            .eq('id', prescriptionId)
            .maybeSingle();
        if (item == null) return null;
        final medicines = await _fetchMedicines([prescriptionId]);
        return PrescriptionModel.fromJson(
          Map<String, dynamic>.from(item),
          medicines: medicines[prescriptionId] ?? const [],
        );
      } catch (_) {}
    }
    return await _local.getPrescriptionDetails(prescriptionId);
  }

  Future<PrescriptionModel?> getPrescriptionByAppointment(
      String appointmentId) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final item = await client
            .from('prescriptions')
            .select()
            .eq('appointment_id', appointmentId)
            .isFilter('deleted_at', null)
            .order('prescribed_date', ascending: false)
            .limit(1)
            .maybeSingle();
        if (item == null) return null;
        final id = (item['id'] ?? '').toString();
        final medicines = await _fetchMedicines([id]);
        return PrescriptionModel.fromJson(
          Map<String, dynamic>.from(item),
          medicines: medicines[id] ?? const [],
        );
      } catch (_) {}
    }
    return await _local.getPrescriptionByAppointment(appointmentId);
  }

  Future<bool> createPrescription(PrescriptionModel prescription) async {
    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final payload = prescription.toJson()..remove('id');
        final inserted = await client
            .from('prescriptions')
            .insert(payload)
            .select('id')
            .single();
        final prescriptionId = (inserted['id'] ?? '').toString();
        if (prescriptionId.isEmpty) return false;
        if (prescription.medicines.isNotEmpty) {
          await client.from('prescription_medicines').insert(
                prescription.medicines.map((medicine) {
                  final json = medicine.toJson()
                    ..remove('id')
                    ..['prescription_id'] = prescriptionId;
                  return json;
                }).toList(),
              );
        }
        return true;
      } catch (_) {}
    }
    return await _local.addPrescription(prescription);
  }

  Future<bool> downloadPrescriptionPDF(String prescriptionId) async {
    return await _local.downloadPrescriptionPDF(prescriptionId);
  }

  Future<bool> sharePrescription(
      String prescriptionId, List<String> recipients) async {
    return await _local.sharePrescription(prescriptionId, recipients);
  }

  Future<Map<String, List<Medicine>>> _fetchMedicines(
    List<String> prescriptionIds,
  ) async {
    final client = _client;
    if (client == null || prescriptionIds.isEmpty) return {};

    final rows = await client
        .from('prescription_medicines')
        .select()
        .inFilter('prescription_id', prescriptionIds)
        .order('created_at');
    final mapped = <String, List<Medicine>>{};
    for (final row in rows) {
      final json = Map<String, dynamic>.from(row);
      final prescriptionId = (json['prescription_id'] ?? '').toString();
      mapped.putIfAbsent(prescriptionId, () => []).add(Medicine.fromJson(json));
    }
    return mapped;
  }
}
