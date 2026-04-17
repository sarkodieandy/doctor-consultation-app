import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Mock data storage - Replace with real API calls
  final List<DoctorModel> _doctors = [
    DoctorModel(
      id: '1',
      name: 'Dr. Stella Kane',
      specialty: 'Heart Surgeon',
      description: 'Experienced heart surgeon with 12 years of practice',
      imageUrl: 'assets/images/doctor1.png',
      rating: 4.8,
      reviewCount: 150,
      consultationFee: 50.0,
      experience: '12 years',
      hospital: 'Flower Hospitals',
      available: true,
      availableTimes: ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM'],
    ),
    DoctorModel(
      id: '2',
      name: 'Dr. Joseph Cart',
      specialty: 'Dental Surgeon',
      description: 'Expert in dental surgery and oral care',
      imageUrl: 'assets/images/doctor2.png',
      rating: 4.6,
      reviewCount: 89,
      consultationFee: 40.0,
      experience: '8 years',
      hospital: 'Flower Hospitals',
      available: true,
      availableTimes: ['08:00 AM', '09:30 AM', '01:00 PM', '02:30 PM', '04:00 PM'],
    ),
    DoctorModel(
      id: '3',
      name: 'Dr. Stephanie',
      specialty: 'Eye Specialist',
      description: 'Specialized in eye care and vision correction',
      imageUrl: 'assets/images/doctor3.png',
      rating: 4.7,
      reviewCount: 120,
      consultationFee: 45.0,
      experience: '10 years',
      hospital: 'Flower Hospitals',
      available: true,
      availableTimes: ['10:00 AM', '11:30 AM', '01:00 PM', '03:00 PM', '04:30 PM'],
    ),
  ];

  final Map<String, List<AppointmentModel>> _appointments = {};

  /// Get all doctors
  Future<List<DoctorModel>> getDoctors() async {
    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      return _doctors;
    } catch (e) {
      print('Error fetching doctors: $e');
      throw e;
    }
  }

  /// Get doctor by ID
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      return _doctors.firstWhere((doc) => doc.id == id);
    } catch (e) {
      print('Error fetching doctor: $e');
      return null;
    }
  }

  /// Get doctors by specialty
  Future<List<DoctorModel>> getDoctorsBySpecialty(String specialty) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      return _doctors.where((doc) => doc.specialty.toLowerCase().contains(specialty.toLowerCase())).toList();
    } catch (e) {
      print('Error fetching doctors by specialty: $e');
      throw e;
    }
  }

  /// Search doctors
  Future<List<DoctorModel>> searchDoctors(String query) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final lowerQuery = query.toLowerCase();
      return _doctors.where((doc) =>
          doc.name.toLowerCase().contains(lowerQuery) ||
          doc.specialty.toLowerCase().contains(lowerQuery) ||
          doc.hospital.toLowerCase().contains(lowerQuery)).toList();
    } catch (e) {
      print('Error searching doctors: $e');
      throw e;
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
      await Future.delayed(Duration(seconds: 1));

      final doctor = await getDoctorById(doctorId);
      if (doctor == null) {
        throw 'Doctor not found';
      }

      final appointment = AppointmentModel(
        id: 'APT_${DateTime.now().millisecondsSinceEpoch}',
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

      if (!_appointments.containsKey(userId)) {
        _appointments[userId] = [];
      }
      _appointments[userId]!.add(appointment);

      return true;
    } catch (e) {
      print('Error booking appointment: $e');
      rethrow;
    }
  }

  /// Get user appointments
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      return _appointments[userId] ?? [];
    } catch (e) {
      print('Error fetching appointments: $e');
      throw e;
    }
  }

  /// Get upcoming appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final appointments = _appointments[userId] ?? [];
      return appointments
          .where((apt) => apt.isUpcoming)
          .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
      throw e;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String userId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      final appointments = _appointments[userId];
      if (appointments != null) {
        final index = appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          appointments[index] = appointments[index].copyWith(status: 'cancelled');
          return true;
        }
      }

      return false;
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
      await Future.delayed(Duration(milliseconds: 500));

      final appointments = _appointments[userId];
      if (appointments != null) {
        final index = appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          appointments[index] = appointments[index].copyWith(
            rating: rating,
            review: review,
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }
}
