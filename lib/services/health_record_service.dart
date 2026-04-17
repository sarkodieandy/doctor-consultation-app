import 'package:doctor_consultation_app/models/health_record_model.dart';

class HealthRecordService {
  static final HealthRecordService _instance = HealthRecordService._internal();

  factory HealthRecordService() {
    return _instance;
  }

  HealthRecordService._internal();

  final List<HealthRecordModel> _mockRecords = [
    HealthRecordModel(
      id: 'hr_1',
      type: 'vital',
      title: 'Heart Rate',
      value: '72',
      unit: 'bpm',
      normalRange: '60-100',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 2)),
      notes: 'Measured in morning',
    ),
    HealthRecordModel(
      id: 'hr_2',
      type: 'vital',
      title: 'Blood Pressure',
      value: '120/80',
      unit: 'mmHg',
      normalRange: '<120/80',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 2)),
      notes: 'Morning reading',
    ),
    HealthRecordModel(
      id: 'hr_3',
      type: 'vital',
      title: 'Temperature',
      value: '98.6',
      unit: '°F',
      normalRange: '98.6',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 1)),
      notes: 'Normal body temperature',
    ),
    HealthRecordModel(
      id: 'hr_4',
      type: 'vital',
      title: 'Weight',
      value: '72',
      unit: 'kg',
      normalRange: '60-75',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 1)),
      notes: 'Morning weight',
    ),
    HealthRecordModel(
      id: 'hr_5',
      type: 'lab',
      title: 'Blood Sugar (Fasting)',
      value: '98',
      unit: 'mg/dL',
      normalRange: '70-100',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 5)),
      notes: 'Fasting blood glucose test',
    ),
    HealthRecordModel(
      id: 'hr_6',
      type: 'lab',
      title: 'Hemoglobin',
      value: '14.5',
      unit: 'g/dL',
      normalRange: '13.5-17.5',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 10)),
      notes: 'CBC test result',
    ),
    HealthRecordModel(
      id: 'hr_7',
      type: 'allergy',
      title: 'Allergies',
      value: 'Penicillin, Shellfish',
      unit: '',
      status: 'normal',
      recordDate: DateTime.now().subtract(Duration(days: 30)),
      notes: 'Known drug and food allergies',
    ),
  ];

  /// Get all health records
  Future<List<HealthRecordModel>> getHealthRecords(String userId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return _mockRecords;
  }

  /// Get records by type
  Future<List<HealthRecordModel>> getRecordsByType(
    String userId,
    String type,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockRecords.where((r) => r.type == type).toList();
  }

  /// Get vital signs
  Future<List<HealthRecordModel>> getVitalSigns(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockRecords.where((r) => r.type == 'vital').toList();
  }

  /// Get lab reports
  Future<List<HealthRecordModel>> getLabReports(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockRecords.where((r) => r.type == 'lab').toList();
  }

  /// Get allergies
  Future<List<HealthRecordModel>> getAllergies(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockRecords.where((r) => r.type == 'allergy').toList();
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
      await Future.delayed(Duration(milliseconds: 500));

      final newRecord = HealthRecordModel(
        id: 'hr_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: title,
        value: value,
        unit: unit,
        status: 'normal',
        recordDate: DateTime.now(),
        notes: notes,
      );

      _mockRecords.add(newRecord);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update record
  Future<bool> updateRecord(HealthRecordModel record) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));

      final index = _mockRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _mockRecords[index] = record;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete record
  Future<bool> deleteRecord(String recordId) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      _mockRecords.removeWhere((r) => r.id == recordId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get latest vital signs
  Future<Map<String, String>> getLatestVitals(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    final vitals = _mockRecords.where((r) => r.type == 'vital').toList();

    return {
      'heart_rate': vitals
          .firstWhere((v) => v.title == 'Heart Rate',
              orElse: () => HealthRecordModel(
                  id: '',
                  type: '',
                  title: '',
                  value: '--',
                  unit: '',
                  recordDate: DateTime.now()))
          .value,
      'blood_pressure': vitals
          .firstWhere((v) => v.title == 'Blood Pressure',
              orElse: () => HealthRecordModel(
                  id: '',
                  type: '',
                  title: '',
                  value: '--',
                  unit: '',
                  recordDate: DateTime.now()))
          .value,
      'temperature': vitals
          .firstWhere((v) => v.title == 'Temperature',
              orElse: () => HealthRecordModel(
                  id: '',
                  type: '',
                  title: '',
                  value: '--',
                  unit: '',
                  recordDate: DateTime.now()))
          .value,
      'weight': vitals
          .firstWhere((v) => v.title == 'Weight',
              orElse: () => HealthRecordModel(
                  id: '',
                  type: '',
                  title: '',
                  value: '--',
                  unit: '',
                  recordDate: DateTime.now()))
          .value,
    };
  }
}
