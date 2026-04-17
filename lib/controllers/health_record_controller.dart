import 'package:doctor_consultation_app/models/health_record_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/health_record_service.dart';
import 'package:get/get.dart';

class HealthRecordController extends GetxController {
  final _authService = AuthService();
  final _healthService = HealthRecordService();

  final allRecords = <HealthRecordModel>[].obs;
  final vitalSigns = <HealthRecordModel>[].obs;
  final labReports = <HealthRecordModel>[].obs;
  final allergies = <HealthRecordModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();
  final latestVitals = <String, String>{}.obs;

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    fetchAllRecords();
  }

  /// Fetch all health records
  Future<void> fetchAllRecords() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _healthService.getHealthRecords(_userId ?? '');
      allRecords.assignAll(result);

      // Separate by type
      vitalSigns.assignAll(result.where((r) => r.type == 'vital').toList());
      labReports.assignAll(result.where((r) => r.type == 'lab').toList());
      allergies.assignAll(result.where((r) => r.type == 'allergy').toList());

      await fetchLatestVitals();
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch latest vital signs
  Future<void> fetchLatestVitals() async {
    try {
      final vitals = await _healthService.getLatestVitals(_userId ?? '');
      latestVitals.assignAll(vitals);
    } catch (e) {
      errorMessage(e.toString());
    }
  }

  /// Fetch vital signs only
  Future<void> fetchVitalSigns() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _healthService.getVitalSigns(_userId ?? '');
      vitalSigns.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch lab reports only
  Future<void> fetchLabReports() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _healthService.getLabReports(_userId ?? '');
      labReports.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch allergies
  Future<void> fetchAllergies() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _healthService.getAllergies(_userId ?? '');
      allergies.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Add new health record
  Future<bool> addRecord(
    String type,
    String title,
    String value,
    String unit,
    String? notes,
  ) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _healthService.addRecord(
        _userId ?? '',
        type,
        title,
        value,
        unit,
        notes,
      );

      if (success) {
        await fetchAllRecords();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Update record
  Future<bool> updateRecord(HealthRecordModel record) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _healthService.updateRecord(record);

      if (success) {
        await fetchAllRecords();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Delete record
  Future<bool> deleteRecord(String recordId) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _healthService.deleteRecord(recordId);

      if (success) {
        await fetchAllRecords();
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }
}
