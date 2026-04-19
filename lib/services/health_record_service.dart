import 'package:doctor_consultation_app/models/health_record_model.dart';
import 'package:doctor_consultation_app/services/local_backend_store.dart';

class HealthRecordService {
  static final HealthRecordService _instance = HealthRecordService._internal();

  factory HealthRecordService() {
    return _instance;
  }

  HealthRecordService._internal();
  final _store = LocalBackendStore.instance;

  /// Get all health records
  Future<List<HealthRecordModel>> getHealthRecords(String userId) async {
    final records = _store.healthRecords
        .where((record) => record.userId == userId)
        .toList();
    records.sort((left, right) => right.recordDate.compareTo(left.recordDate));
    return records;
  }

  /// Get records by type
  Future<List<HealthRecordModel>> getRecordsByType(
    String userId,
    String type,
  ) async {
    final records = _store.healthRecords
        .where((record) => record.userId == userId && record.type == type)
        .toList();
    records.sort((left, right) => right.recordDate.compareTo(left.recordDate));
    return records;
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
    _store.healthRecords.add(
      HealthRecordModel(
        id: _store.nextId('record'),
        userId: userId,
        type: type,
        title: title,
        value: value,
        unit: unit,
        status: 'normal',
        recordDate: DateTime.now(),
        notes: notes,
      ),
    );
    return true;
  }

  /// Update record
  Future<bool> updateRecord(HealthRecordModel record) async {
    final index =
        _store.healthRecords.indexWhere((item) => item.id == record.id);
    if (index == -1) return false;
    _store.healthRecords[index] = record;
    return true;
  }

  /// Delete record
  Future<bool> deleteRecord(String recordId) async {
    _store.healthRecords.removeWhere((record) => record.id == recordId);
    return true;
  }

  /// Get latest vital signs
  Future<Map<String, String>> getLatestVitals(String userId) async {
    final vitals = await getVitalSigns(userId);

    String findValue(String title) {
      try {
        return vitals.firstWhere((record) => record.title == title).value;
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
  }
}
