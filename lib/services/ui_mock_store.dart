import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/chat_model.dart';
import 'package:doctor_consultation_app/models/consultation_model.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/models/health_record_model.dart';
import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/models/review_model.dart';
import 'package:doctor_consultation_app/models/user_model.dart';

class UiMockStore {
  UiMockStore._internal() {
    _seed();
  }

  static final UiMockStore instance = UiMockStore._internal();

  final Map<String, String> passwordsByEmail = {};
  final Map<String, String> loginAliases = {};
  final Map<String, Map<String, String>> payoutProfiles = {};
  final Map<String, Map<String, dynamic>> verifications = {};
  final Map<String, String> chatPatientsById = {};

  final List<UserModel> users = [];
  final List<DoctorModel> doctors = [];
  final List<AppointmentModel> appointments = [];
  final List<PaymentModel> payments = [];
  final List<ConsultationModel> consultations = [];
  final List<ChatModel> chats = [];
  final List<MessageModel> messages = [];
  final List<HealthRecordModel> healthRecords = [];
  final List<PrescriptionModel> prescriptions = [];
  final List<ReviewModel> reviews = [];
  final List<NotificationModel> notifications = [];

  String? currentUserId;

  int _idCounter = 1000;

  String nextId(String prefix) {
    _idCounter += 1;
    return '${prefix}_${_idCounter}';
  }

  UserModel? get currentUser {
    if (currentUserId == null) return null;
    return findUserById(currentUserId!);
  }

  UserModel? findUserById(String id) {
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  UserModel? findUserByEmail(String email) {
    try {
      return users.firstWhere(
          (user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  String? resolveEmailFromLogin(String login) {
    final normalized = login.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    if (normalized.contains('@')) {
      return normalized;
    }

    final aliasEmail = loginAliases[normalized];
    if (aliasEmail != null) {
      return aliasEmail.toLowerCase();
    }

    for (final user in users) {
      final userEmail = user.email.toLowerCase();
      final localPart = userEmail.split('@').first;
      if (localPart == normalized) {
        return userEmail;
      }
    }

    return null;
  }

  DoctorModel? findDoctorById(String id) {
    try {
      return doctors.firstWhere((doctor) => doctor.id == id);
    } catch (_) {
      return null;
    }
  }

  void saveUser(UserModel user) {
    users.removeWhere((item) => item.id == user.id);
    users.add(user);
    if (currentUserId == user.id) {
      currentUserId = user.id;
    }
    syncDoctorListing(user);
  }

  void deleteUser(String userId) {
    users.removeWhere((user) => user.id == userId);
    doctors.removeWhere((doctor) => doctor.id == userId);
    appointments.removeWhere(
        (item) => item.userId == userId || item.doctorId == userId);
    payments.removeWhere(
        (item) => item.userId == userId || item.doctorId == userId);
    consultations.removeWhere(
        (item) => item.userId == userId || item.doctorId == userId);
    chats.removeWhere((item) => item.id == userId || item.doctorId == userId);
    messages.removeWhere((item) => item.senderId == userId);
    healthRecords.removeWhere((item) => item.userId == userId);
    prescriptions.removeWhere(
        (item) => item.patientId == userId || item.doctorId == userId);
    reviews.removeWhere(
        (item) => item.patientId == userId || item.doctorId == userId);
    notifications.removeWhere((item) => item.userId == userId);
    verifications.remove(userId);
    payoutProfiles.remove(userId);
    if (currentUserId == userId) {
      currentUserId = null;
    }
  }

  void syncDoctorListing(UserModel user) {
    if (!user.isDoctor || !user.isDoctorApproved) {
      doctors.removeWhere((doctor) => doctor.id == user.id);
      return;
    }

    final doctor = DoctorModel(
      id: user.id,
      name: user.fullName,
      specialty: user.specialty ?? 'General Practice',
      description: user.bio,
      imageUrl: user.profileImage,
      consultationFee: user.consultationFee ?? 0,
      experience: user.experience ?? '',
      hospital: 'DocConsult Clinic',
      available: user.isOnline,
      availableTimes: const [
        '09:00 AM',
        '10:00 AM',
        '11:00 AM',
        '02:00 PM',
        '03:00 PM'
      ],
      rating: doctorRating(user.id),
      reviewCount: reviews.where((review) => review.doctorId == user.id).length,
    );

    doctors.removeWhere((item) => item.id == user.id);
    doctors.add(doctor);
  }

  double doctorRating(String doctorId) {
    final doctorReviews =
        reviews.where((review) => review.doctorId == doctorId).toList();
    if (doctorReviews.isEmpty) return 4.8;
    final total =
        doctorReviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / doctorReviews.length;
  }

  void _seed() {
    final patient = UserModel(
      id: 'user_patient_1',
      email: 'patient@test.com',
      firstName: 'Test',
      lastName: 'Patient',
      phone: '+233501234567',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      role: UserRole.patient,
      bio: 'Patient profile for UI preview.',
    );

    final doctor = UserModel(
      id: 'user_doctor_1',
      email: 'doctor@test.com',
      firstName: 'Dr. Ama',
      lastName: 'Mensah',
      phone: '+233509876543',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      role: UserRole.doctor,
      specialty: 'Cardiologist',
      experience: '8 years',
      consultationFee: 180,
      approvalStatus: DoctorApprovalStatus.approved,
      bio: 'Experienced cardiologist focused on preventive care.',
      isOnline: true,
    );

    final admin = UserModel(
      id: 'user_admin_1',
      email: 'admin@test.com',
      firstName: 'Platform',
      lastName: 'Admin',
      phone: '+233500000000',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      role: UserRole.admin,
      bio: 'Local admin preview account.',
      isOnline: true,
    );

    users.addAll([patient, doctor, admin]);
    passwordsByEmail['patient@test.com'] = 'Test1234!';
    passwordsByEmail['doctor@test.com'] = 'Test1234!';
    passwordsByEmail['admin@test.com'] = 'Password@123';

    loginAliases['testadmin'] = 'admin@test.com';
    loginAliases['admin'] = 'admin@test.com';
    loginAliases['patient'] = 'patient@test.com';
    loginAliases['doctor'] = 'doctor@test.com';

    reviews.add(
      ReviewModel(
        id: 'review_1',
        appointmentId: 'appointment_2',
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        doctorAvatar: '',
        patientId: patient.id,
        patientName: patient.fullName,
        patientAvatar: '',
        rating: 5,
        title: 'Excellent consultation',
        reviewText: 'Very clear, reassuring, and practical advice.',
        tags: const ['communication', 'expertise'],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        helpfulCount: 3,
        isVerifiedAppointment: true,
      ),
    );

    syncDoctorListing(doctor);

    appointments.addAll([
      AppointmentModel(
        id: 'appointment_1',
        userId: patient.id,
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        doctorImage: '',
        speciality: doctor.specialty ?? '',
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '10:00 AM',
        consultationFee: doctor.consultationFee ?? 0,
        status: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppointmentModel(
        id: 'appointment_2',
        userId: patient.id,
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        doctorImage: '',
        speciality: doctor.specialty ?? '',
        appointmentDate: DateTime.now().subtract(const Duration(days: 5)),
        timeSlot: '02:00 PM',
        consultationFee: doctor.consultationFee ?? 0,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        rating: 5,
        review: 'Excellent consultation',
      ),
    ]);

    payments.add(
      PaymentModel(
        id: 'payment_1',
        appointmentId: 'appointment_2',
        doctorId: doctor.id,
        userId: patient.id,
        amount: doctor.consultationFee ?? 0,
        status: 'completed',
        paymentMethod: 'card',
        transactionId: 'txn_local_1',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        completedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    );

    consultations.addAll([
      ConsultationModel(
        id: 'consultation_1',
        appointmentId: 'appointment_1',
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        doctorAvatar: '',
        userId: patient.id,
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        duration: const Duration(minutes: 30),
        status: 'scheduled',
        consultationType: 'video',
      ),
      ConsultationModel(
        id: 'consultation_2',
        appointmentId: 'appointment_2',
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        doctorAvatar: '',
        userId: patient.id,
        scheduledTime: DateTime.now().subtract(const Duration(days: 5)),
        duration: const Duration(minutes: 28),
        status: 'completed',
        consultationType: 'video',
        summary: 'Follow-up in two weeks and continue current medication.',
      ),
    ]);

    chats.add(
      ChatModel(
        id: 'chat_1',
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        doctorAvatar: '',
        lastMessage: 'See you tomorrow for the consultation.',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 1,
        isActive: true,
      ),
    );
    chatPatientsById['chat_1'] = patient.id;

    messages.addAll([
      MessageModel(
        id: 'message_1',
        chatId: 'chat_1',
        senderId: doctor.id,
        senderName: doctor.fullName,
        senderAvatar: '',
        message:
            'Please remember to upload your latest blood pressure reading.',
        isDoctor: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      MessageModel(
        id: 'message_2',
        chatId: 'chat_1',
        senderId: patient.id,
        senderName: patient.fullName,
        senderAvatar: '',
        message: 'Done. I will also bring my previous lab report.',
        isDoctor: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      MessageModel(
        id: 'message_3',
        chatId: 'chat_1',
        senderId: doctor.id,
        senderName: doctor.fullName,
        senderAvatar: '',
        message: 'See you tomorrow for the consultation.',
        isDoctor: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
    ]);

    healthRecords.addAll([
      HealthRecordModel(
        id: 'record_1',
        userId: patient.id,
        type: 'vital',
        title: 'Heart Rate',
        value: '74',
        unit: 'bpm',
        status: 'normal',
        recordDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      HealthRecordModel(
        id: 'record_2',
        userId: patient.id,
        type: 'vital',
        title: 'Blood Pressure',
        value: '120/80',
        unit: 'mmHg',
        status: 'normal',
        recordDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      HealthRecordModel(
        id: 'record_3',
        userId: patient.id,
        type: 'allergy',
        title: 'Peanut Allergy',
        value: 'Severe',
        unit: '',
        status: 'high',
        recordDate: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ]);

    prescriptions.add(
      PrescriptionModel(
        id: 'prescription_1',
        doctorId: doctor.id,
        doctorName: doctor.fullName,
        appointmentId: 'appointment_2',
        patientId: patient.id,
        prescribedDate: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 25)),
        medicines: [
          Medicine(
            id: 'medicine_1',
            prescriptionId: 'prescription_1',
            name: 'Amlodipine',
            dosage: '5mg',
            frequency: 'Once daily',
            duration: 30,
            instructions: 'Take after breakfast.',
            sideEffects: const ['dizziness'],
          ),
        ],
        notes: 'Monitor blood pressure every morning.',
        status: 'active',
      ),
    );

    notifications.addAll([
      NotificationModel(
        id: 'notification_1',
        userId: patient.id,
        title: 'Appointment Reminder',
        message:
            'Your consultation with ${doctor.fullName} is tomorrow at 10:00 AM.',
        type: 'appointment',
        isRead: false,
        relatedId: 'appointment_1',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'notification_2',
        userId: doctor.id,
        title: 'New Review',
        message: 'A patient left feedback on your last consultation.',
        type: 'review',
        isRead: true,
        relatedId: 'review_1',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);

    verifications[doctor.id] = {
      'doctor_id': doctor.id,
      'license_verified': true,
      'ghana_card_verified': true,
      'overall_status': 'approved',
      'confidence_score': 1.0,
      'verification_notes': 'Local UI-only seeded approval.',
      'verification_method': 'local',
      'verified_at':
          DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    };
  }
}
