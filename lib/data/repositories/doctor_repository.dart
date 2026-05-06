import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/ui_data_service.dart';

class DoctorRepository {
  final UiDataService _local = UiDataService();

  Future<List<DoctorModel>> fetchDoctors({Map<String, dynamic>? params}) async {
    return await _local.getDoctors(params: params);
  }

  Future<DoctorModel?> getDoctorById(String id) async {
    return await _local.getDoctorById(id);
  }

  Future<List<DoctorModel>> searchDoctors(String query) async {
    return await _local.searchDoctors(query);
  }

  Future<List<String>> getAvailability(String doctorId) async {
    final doctor = await _local.getDoctorById(doctorId);
    return doctor?.availableTimes ?? [];
  }
}
