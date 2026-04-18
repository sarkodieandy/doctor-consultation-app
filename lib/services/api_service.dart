import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all doctors
  Future<List<DoctorModel>> getDoctors() async {
    try {
      final data = await _supabase
          .from('doctors')
          .select()
          .eq('available', true)
          .order('rating', ascending: false);

      return (data as List).map((json) => DoctorModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching doctors: $e');
      rethrow;
    }
  }

  /// Get doctor by ID
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      final data =
          await _supabase.from('doctors').select().eq('id', id).maybeSingle();

      if (data != null) {
        return DoctorModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching doctor: $e');
      return null;
    }
  }

  /// Get doctors by specialty
  Future<List<DoctorModel>> getDoctorsBySpecialty(String specialty) async {
    try {
      final data = await _supabase
          .from('doctors')
          .select()
          .ilike('specialty', '%$specialty%');

      return (data as List).map((json) => DoctorModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching doctors by specialty: $e');
      rethrow;
    }
  }

  /// Search doctors
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      final data = await _supabase.from('doctors').select().or(
          'name.ilike.%$query%,specialty.ilike.%$query%,hospital.ilike.%$query%');

      return (data as List).map((json) => DoctorModel.fromJson(json)).toList();
    } catch (e) {
      print('Error searching doctors: $e');
      rethrow;
    }
  }

  /// Book appointment
  Future<bool> bookAppointment(
    String userId,
    String doctorId,
    DateTime appointmentDate,
    String timeSlot,
  ) async {
    try {
      final doctor = await getDoctorById(doctorId);
      if (doctor == null) {
        throw 'Doctor not found';
      }

      final appointment = AppointmentModel(
        id: '',
        userId: userId,
        doctorId: doctorId,
        doctorName: doctor.name,
        doctorImage: doctor.imageUrl,
        speciality: doctor.specialty,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        consultationFee: doctor.consultationFee,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      final json = appointment.toJson();
      json.remove('id'); // Let Supabase generate UUID

      await _supabase.from('appointments').insert(json);
      return true;
    } catch (e) {
      print('Error booking appointment: $e');
      rethrow;
    }
  }

  /// Get user appointments
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('appointment_date', ascending: false);

      return (data as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow;
    }
  }

  /// Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('appointment_date', DateTime.now().toIso8601String())
          .order('appointment_date', ascending: true);

      return (data as List)
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
      rethrow;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String userId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  /// Add review to appointment
  Future<bool> addReview(
    String appointmentId,
    String userId,
    double rating,
    String review,
  ) async {
    try {
      await _supabase
          .from('appointments')
          .update({'rating': rating, 'review': review})
          .eq('id', appointmentId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }
}
