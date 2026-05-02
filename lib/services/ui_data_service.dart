import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UiDataService {
  final _store = UiMockStore.instance;

  supabase.SupabaseClient? get _client {
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<DoctorModel>> getDoctors({Map<String, dynamic>? params}) async {
    final remoteDoctors = await _getRemoteDoctors(params: params);
    if (remoteDoctors.isNotEmpty) return remoteDoctors;

    return _filterDoctors(List<DoctorModel>.from(_store.doctors), params);
  }

  Future<DoctorModel?> getDoctorById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final data =
            await client.from('doctors').select().eq('id', id).maybeSingle();
        if (data != null) {
          return DoctorModel.fromJson(Map<String, dynamic>.from(data));
        }
      } catch (_) {
        try {
          final data =
              await client.from('profiles').select().eq('id', id).maybeSingle();
          if (data != null) {
            return _doctorFromProfile(Map<String, dynamic>.from(data));
          }
        } catch (_) {}
      }
    }

    return _store.findDoctorById(id);
  }

  Future<List<DoctorModel>> getDoctorsBySpecialty(String specialty) async {
    return getDoctors(params: {'specialty': specialty});
  }

  Future<List<DoctorModel>> searchDoctors(String query) async {
    return getDoctors(params: {'query': query});
  }

  Future<String> bookAppointment(
    String userId,
    String doctorId,
    DateTime appointmentDate,
    String timeSlot,
  ) async {
    final doctor = await getDoctorById(doctorId) ??
        DoctorModel(
          id: doctorId,
          name: 'Doctor',
          specialty: 'General',
          description: '',
          imageUrl: DoctorModel.fallbackImagePath,
          consultationFee: 0,
          experience: '',
          hospital: '',
        );
    final user = _store.users.firstWhere(
      (item) => item.id == userId,
      orElse: () => UserModel(
        id: userId,
        email: '',
        firstName: 'Patient',
        lastName: '',
        phone: '',
        createdAt: DateTime.now(),
      ),
    );
    final appointment = AppointmentModel(
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

    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('appointments')
            .insert(appointment.toJson())
            .select()
            .single();
        final remoteAppointment = AppointmentModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        _saveLocalAppointment(remoteAppointment);
        return remoteAppointment.id;
      } catch (_) {
        // Fall back to the in-memory store until the Supabase table exists.
      }
    }

    _saveLocalAppointment(appointment);
    return appointment.id;
  }

  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    final remoteAppointments = await _getRemoteAppointments('user_id', userId);
    if (remoteAppointments.isNotEmpty) return remoteAppointments;

    final appointments = _store.appointments
        .where((appointment) => appointment.userId == userId)
        .toList();
    appointments.sort(
        (left, right) => right.appointmentDate.compareTo(left.appointmentDate));
    return appointments;
  }

  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final remoteAppointments =
        await _getRemoteAppointments('doctor_id', doctorId);
    if (remoteAppointments.isNotEmpty) return remoteAppointments;

    final appointments = _store.appointments
        .where((appointment) => appointment.doctorId == doctorId)
        .toList();
    appointments.sort(
        (left, right) => right.appointmentDate.compareTo(left.appointmentDate));
    return appointments;
  }

  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    final now = DateTime.now();
    final appointments = await getUserAppointments(userId);
    final upcoming = appointments
        .where((appointment) =>
            appointment.userId == userId &&
            appointment.status == 'confirmed' &&
            appointment.appointmentDate.isAfter(now))
        .toList();
    upcoming.sort(
        (left, right) => left.appointmentDate.compareTo(right.appointmentDate));
    return upcoming;
  }

  Future<AppointmentModel?> getAppointmentById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('appointments')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (data != null) {
          return AppointmentModel.fromJson(Map<String, dynamic>.from(data));
        }
      } catch (_) {}
    }

    try {
      return _store.appointments.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String userId) async {
    final remoteUpdated = await _updateRemoteAppointmentStatus(
      appointmentId,
      'cancelled',
      userIdField: 'user_id',
      userId: userId,
    );
    if (remoteUpdated) return true;
    return _updateLocalAppointmentStatus(appointmentId, 'cancelled',
        userId: userId);
  }

  Future<bool> addReview(
      String appointmentId, String userId, double rating, String review) async {
    final client = _client;
    if (client != null) {
      try {
        await client
            .from('appointments')
            .update({'rating': rating, 'review': review})
            .eq('id', appointmentId)
            .eq('user_id', userId);
        return true;
      } catch (_) {}
    }

    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId && appointment.userId == userId,
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(rating: rating, review: review);
    return true;
  }

  Future<bool> approveAppointment(String appointmentId, String doctorId) async {
    final remoteUpdated = await _updateRemoteAppointmentStatus(
      appointmentId,
      'confirmed',
      userIdField: 'doctor_id',
      userId: doctorId,
    );
    if (remoteUpdated) return true;
    return _updateLocalAppointmentStatus(appointmentId, 'confirmed',
        doctorId: doctorId);
  }

  Future<bool> rejectAppointment(String appointmentId, String doctorId) async {
    final remoteUpdated = await _updateRemoteAppointmentStatus(
      appointmentId,
      'cancelled',
      userIdField: 'doctor_id',
      userId: doctorId,
    );
    if (remoteUpdated) return true;
    return _updateLocalAppointmentStatus(appointmentId, 'cancelled',
        doctorId: doctorId);
  }

  Future<bool> completeAppointment(
      String appointmentId, String doctorId) async {
    final remoteUpdated = await _updateRemoteAppointmentStatus(
      appointmentId,
      'completed',
      userIdField: 'doctor_id',
      userId: doctorId,
    );
    if (remoteUpdated) return true;
    return _updateLocalAppointmentStatus(appointmentId, 'completed',
        doctorId: doctorId);
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
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('notifications')
            .select()
            .or('user_id.eq.$userId,target_role.eq.all')
            .order('created_at', ascending: false);
        return (data as List)
            .map((item) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (_) {}
    }
    return _store.notifications
        .where((notification) => notification.userId == userId)
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('notifications').update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('id', notificationId);
      } catch (_) {}
    }
    final index = _store.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index != -1) {
      _store.notifications[index] = _store.notifications[index].copyWith(
        isRead: true,
      );
    }
  }

  Future<List<DoctorModel>> _getRemoteDoctors({
    Map<String, dynamic>? params,
  }) async {
    final client = _client;
    if (client == null) return const [];

    try {
      // Query approved, active doctors from profiles and join doctors for rating
      final data = await client
          .from('profiles')
          .select('*, doctors(rating, review_count)')
          .eq('role', 'doctor')
          .eq('approval_status', 'approved')
          .eq('is_active', true);
      final doctors = (data as List).map((item) {
        final map = Map<String, dynamic>.from(item);
        // Flatten nested doctors sub-object (rating, review_count) into map
        final doctorData = map['doctors'];
        if (doctorData is Map) {
          map['rating'] ??= doctorData['rating'];
          map['review_count'] ??= doctorData['review_count'];
        }
        return _doctorFromProfile(map);
      }).toList();
      return _filterDoctors(doctors, params);
    } catch (_) {
      return const [];
    }
  }

  List<DoctorModel> _filterDoctors(
    List<DoctorModel> doctors,
    Map<String, dynamic>? params,
  ) {
    final specialty = (params?['specialty'] ?? params?['specialization'])
        ?.toString()
        .trim()
        .toLowerCase();
    final query = params?['query']?.toString().trim().toLowerCase();
    final filtered = List<DoctorModel>.from(doctors);

    if (specialty != null && specialty.isNotEmpty) {
      filtered.retainWhere(
        (doctor) => doctor.specialty.toLowerCase() == specialty,
      );
    }

    if (query != null && query.isNotEmpty) {
      filtered.retainWhere(
        (doctor) =>
            doctor.name.toLowerCase().contains(query) ||
            doctor.specialty.toLowerCase().contains(query) ||
            doctor.hospital.toLowerCase().contains(query),
      );
    }

    return filtered;
  }

  DoctorModel _doctorFromProfile(Map<String, dynamic> json) {
    final firstName =
        (json['first_name'] ?? json['firstName'] ?? '').toString();
    final lastName = (json['last_name'] ?? json['lastName'] ?? '').toString();
    return DoctorModel.fromJson({
      ...json,
      'name': '$firstName $lastName'.trim(),
      'description': json['bio'] ?? '',
      'image_url': json['profile_image'] ?? '',
      'hospital': json['hospital'] ?? 'DocConsult Clinic',
    });
  }

  Future<List<AppointmentModel>> _getRemoteAppointments(
    String field,
    String id,
  ) async {
    final client = _client;
    if (client == null || id.isEmpty) return const [];

    try {
      final data = await client
          .from('appointments')
          .select()
          .eq(field, id)
          .order('appointment_date', ascending: false);
      return (data as List)
          .map((item) =>
              AppointmentModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> _updateRemoteAppointmentStatus(
    String appointmentId,
    String status, {
    required String userIdField,
    required String userId,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId)
          .eq(userIdField, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _updateLocalAppointmentStatus(
    String appointmentId,
    String status, {
    String? userId,
    String? doctorId,
  }) {
    final index = _store.appointments.indexWhere(
      (appointment) =>
          appointment.id == appointmentId &&
          (userId == null || appointment.userId == userId) &&
          (doctorId == null || appointment.doctorId == doctorId),
    );
    if (index == -1) return false;
    _store.appointments[index] =
        _store.appointments[index].copyWith(status: status);
    return true;
  }

  void _saveLocalAppointment(AppointmentModel appointment) {
    _store.appointments.removeWhere((item) => item.id == appointment.id);
    _store.appointments.add(appointment);
  }
}
