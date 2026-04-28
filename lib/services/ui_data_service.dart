import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';

class UiDataService {
  final _store = UiMockStore.instance;

  Future<List<DoctorModel>> getDoctors({Map<String, dynamic>? params}) async {
    final doctors = List<DoctorModel>.from(_store.doctors);
    final specialty = params?['specialty']?.toString().trim().toLowerCase();
    final query = params?['query']?.toString().trim().toLowerCase();

    if (specialty != null && specialty.isNotEmpty) {
      doctors.retainWhere(
        (doctor) => doctor.specialty.toLowerCase() == specialty,
      );
    }

    if (query != null && query.isNotEmpty) {
      doctors.retainWhere(
        (doctor) =>
            doctor.name.toLowerCase().contains(query) ||
            doctor.specialty.toLowerCase().contains(query) ||
            doctor.hospital.toLowerCase().contains(query),
      );
    }

    return doctors;
  }

  Future<DoctorModel?> getDoctorById(String id) async {
    return _store.findDoctorById(id);
  }

  Future<List<DoctorModel>> getDoctorsBySpecialty(String specialty) async {
    return getDoctors(params: {'specialty': specialty});
  }

  Future<List<DoctorModel>> searchDoctors(String query) async {
    return getDoctors(params: {'query': query});
  }

  Future<void> bookAppointment(String userId, String doctorId,
      DateTime appointmentDate, String timeSlot) async {
    final doctor = _store.doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => DoctorModel(
        id: doctorId,
        name: 'Dr. Mock',
        specialty: 'General',
        description: '',
        imageUrl: DoctorModel.fallbackImagePath,
        consultationFee: 0.0,
        experience: '',
        hospital: '',
      ),
    );
    final user = _store.users.firstWhere(
      (u) => u.id == userId,
      orElse: () => UserModel(
        id: userId,
        email: '',
        firstName: 'Patient',
        lastName: 'Mock',
        phone: '',
        createdAt: DateTime.now(),
      ),
    );
    final newAppointment = AppointmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      doctorId: doctorId,
      doctorName: doctor.name,
      doctorImage: doctor.imageUrl,
      patientName: user.fullName,
      patientAvatar: user.profileImage,
      speciality: doctor.specialty,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      consultationFee: doctor.consultationFee,
      status: 'confirmed',
      createdAt: DateTime.now(),
    );
    _store.appointments.add(newAppointment);
  }

  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    final appointments = _store.appointments
        .where((appointment) => appointment.userId == userId)
        .toList();
    appointments.sort(
        (left, right) => right.appointmentDate.compareTo(left.appointmentDate));
    return appointments;
  }

  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final appointments = _store.appointments
        .where((appointment) => appointment.doctorId == doctorId)
        .toList();
    appointments.sort(
        (left, right) => right.appointmentDate.compareTo(left.appointmentDate));
    return appointments;
  }

  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    final now = DateTime.now();
    final appointments = _store.appointments
        .where((appointment) =>
            appointment.userId == userId &&
            appointment.status == 'confirmed' &&
            appointment.appointmentDate.isAfter(now))
        .toList();
    appointments.sort(
        (left, right) => left.appointmentDate.compareTo(right.appointmentDate));
    return appointments;
  }

  Future<AppointmentModel?> getAppointmentById(String id) async {
    try {
      return _store.appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

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

  Future<bool> addReview(
      String appointmentId, String userId, double rating, String review) async {
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

  Future<bool> approveAppointment(String appointmentId, String doctorId) async {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.doctorId == doctorId,
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(status: 'confirmed');
    return true;
  }

  Future<bool> rejectAppointment(String appointmentId, String doctorId) async {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.doctorId == doctorId,
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(status: 'cancelled');
    return true;
  }

  Future<bool> completeAppointment(
      String appointmentId, String doctorId) async {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.doctorId == doctorId,
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(status: 'completed');
    return true;
  }

  Future<List<PrescriptionModel>> getPrescriptions(String userId) async {
    return _store.prescriptions
        .where((prescription) => prescription.patientId == userId)
        .toList();
  }

  Future<PrescriptionModel?> getPrescriptionById(String id) async {
    try {
      return _store.prescriptions.firstWhere(
        (prescription) => prescription.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatModel>> getChats(String userId) async {
    return _store.chats
        .where((chat) => chat.id == userId || chat.doctorId == userId)
        .toList();
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    return _store.messages
        .where((message) => message.chatId == chatId)
        .toList();
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    return _store.notifications
        .where((notification) => notification.userId == userId)
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _store.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) return;
    _store.notifications[index] = _store.notifications[index].copyWith(
      isRead: true,
    );
  }
}
