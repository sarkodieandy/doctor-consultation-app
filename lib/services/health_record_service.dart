import 'package:doctor_consultation_app/models/health_record_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthRecordService {
  static final HealthRecordService _instance = HealthRecordService._internal();

  factory HealthRecordService() {
    return _instance;
  }

  HealthRecordService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all health records
  Future<List<HealthRecordModel>> getHealthRecords(String userId) async {
    try {
      final data = await _supabase
          .from('health_records')
          .select()
          .eq('user_id', userId)
          .order('record_date', ascending: false);

      return (data as List)
          .map((json) => HealthRecordModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching health records: $e');
      return [];
    }
  }

  /// Get records by type
  Future<List<HealthRecordModel>> getRecordsByType(
    String userId,
    String type,
  ) async {
    try {
      final data = await _supabase
          .from('health_records')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .order('record_date', ascending: false);

      return (data as List)
          .map((json) => HealthRecordModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching records by type: $e');
      return [];
    }
  }

  /// Get vital signs
  Future<List<HealthRecordModel>> getVitalSigns(String userId) async {
    return getRecordsByType(userId, 'vital');
  }

  /// Get lab reports
  Future<List<HealthRecordModel>> getLabReports(String userId) async {
    return getRecordsByType(userId, 'lab');
  }

  /// Get allergies
  Future<List<HealthRecordModel>> getAllergies(String userId) async {
    return getRecordsByType(userId, 'allergy');
  }

  /// Add new health record
  Future<bool> addRecord(
    String userId,
    String type,
    String title,
    String value,
    String unit,
    String? notes,
  ) async {
    try {
      await _supabase.from('health_records').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'value': value,
        'unit': unit,
        'status': 'normal',
        'record_date': DateTime.now().toIso8601String(),
        'notes': notes,
      });
      return true;
    } catch (e) {
      print('Error adding health record: $e');
      return false;
    }
  }

  /// Update record
  Future<bool> updateRecord(HealthRecordModel record) async {
    try {
      final json = record.toJson();
      json.remove('id');
      await _supabase.from('health_records').update(json).eq('id', record.id);
      return true;
    } catch (e) {
      print('Error updating health record: $e');
      return false;
    }
  }

  /// Delete record
  Future<bool> deleteRecord(String recordId) async {
    try {
      await _supabase.from('health_records').delete().eq('id', recordId);
      return true;
    } catch (e) {
      print('Error deleting health record: $e');
      return false;
    }
  }

  /// Get latest vital signs
  Future<Map<String, String>> getLatestVitals(String userId) async {
    try {
      final data = await _supabase
          .from('health_records')
          .select()
          .eq('user_id', userId)
          .eq('type', 'vital')
          .order('record_date', ascending: false);

      final vitals = (data as List)
          .map((json) => HealthRecordModel.fromJson(json))
          .toList();

      String findValue(String title) {
        try {
          return vitals.firstWhere((v) => v.title == title).value;
        } catch (_) {
          return '--';
        }
      }

      return {
        'heart_rate': findValue('Heart Rate'),
        'blood_pressure': findValue('Blood Pressure'),
        'temperature': findValue('Temperature'),
        'weight': findValue('Weight'),
      };
    } catch (e) {
      print('Error fetching latest vitals: $e');
      return {
        'heart_rate': '--',
        'blood_pressure': '--',
        'temperature': '--',
        'weight': '--',
      };
    }
  }
}
