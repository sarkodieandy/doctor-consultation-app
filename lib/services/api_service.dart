import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/local_backend_store.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final _store = LocalBackendStore.instance;

  /// Get all doctors
  Future<List<DoctorModel>> getDoctors() async {
    final doctors = _store.doctors.where((doctor) => doctor.available).toList();
    doctors.sort((left, right) => right.rating.compareTo(left.rating));
    return doctors;
  }

  /// Get doctor by ID
  Future<DoctorModel?> getDoctorById(String id) async {
    return _store.findDoctorById(id);
  }

  /// Get doctors by specialty
  Future<List<DoctorModel>> getDoctorsBySpecialty(String specialty) async {
    final query = specialty.toLowerCase();
    return _store.doctors
        .where((doctor) => doctor.specialty.toLowerCase().contains(query))
        .toList();
  }

  /// Search doctors
  Future<List<DoctorModel>> searchDoctors(String query) async {
    final queryLower = query.toLowerCase();
    return _store.doctors.where((doctor) {
      return doctor.available &&
          (doctor.name.toLowerCase().contains(queryLower) ||
              doctor.specialty.toLowerCase().contains(queryLower) ||
              doctor.hospital.toLowerCase().contains(queryLower));
    }).toList();
  }

  /// Book appointment
  Future<bool> bookAppointment(
    String userId,
    String doctorId,
    DateTime appointmentDate,
    String timeSlot,
  ) async {
    final doctor = await getDoctorById(doctorId);
    if (doctor == null) {
      throw 'Doctor not found';
    }

    _store.appointments.add(
      AppointmentModel(
        id: _store.nextId('appointment'),
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
      ),
    );
    return true;
  }

  /// Get user appointments
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    final appointments = _store.appointments
        .where((appointment) => appointment.userId == userId)
        .toList();
    appointments.sort(
      (left, right) => right.appointmentDate.compareTo(left.appointmentDate),
    );
    return appointments;
  }

  /// Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    final now = DateTime.now();
    final appointments = _store.appointments
        .where(
          (appointment) =>
              appointment.userId == userId &&
              appointment.status == 'confirmed' &&
              appointment.appointmentDate.isAfter(now),
        )
        .toList();
    appointments.sort(
      (left, right) => left.appointmentDate.compareTo(right.appointmentDate),
    );
    return appointments;
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String userId) async {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.userId == userId,
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(status: 'cancelled');
    return true;
  }

  /// Add review to appointment
  Future<bool> addReview(
    String appointmentId,
    String userId,
    double rating,
    String review,
  ) async {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.userId == userId,
    );
    if (index == -1) return false;
    final current = _store.appointments[index];
    _store.appointments[index] =
        current.copyWith(rating: rating, review: review);
    return true;
  }

  /// Approve appointment (by doctor)
  Future<bool> approveAppointment(
    String appointmentId,
    String doctorId,
  ) async {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.doctorId == doctorId,
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(status: 'confirmed');
    return true;
  }
}
