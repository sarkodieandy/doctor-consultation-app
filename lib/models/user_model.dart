enum UserRole { patient, doctor, admin }

enum DoctorApprovalStatus { pending, approved, rejected }

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String profileImage;
  final String bio;
  final DateTime createdAt;
  final UserRole role;
  // Doctor-specific fields
  final String? specialty;
  final String? experience;
  final double? consultationFee;
  final String? licenseDocumentPath;
  final DoctorApprovalStatus? approvalStatus;
  final String? approvalNote;
  final bool isOnline;
  final String? mobileMoneyNumber;
  final String? mobileMoneyProvider;
  final String? payoutRecipientCode;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profileImage = '',
    this.bio = '',
    required this.createdAt,
    this.role = UserRole.patient,
    this.specialty,
    this.experience,
    this.consultationFee,
    this.licenseDocumentPath,
    this.approvalStatus,
    this.approvalNote,
    this.isOnline = false,
    this.mobileMoneyNumber,
    this.mobileMoneyProvider,
    this.payoutRecipientCode,
  });

  String get fullName => '$firstName $lastName';

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;
  bool get isAdmin => role == UserRole.admin;
  bool get isDoctorApproved => approvalStatus == DoctorApprovalStatus.approved;
  bool get isDoctorPending => approvalStatus == DoctorApprovalStatus.pending;
  bool get isDoctorRejected => approvalStatus == DoctorApprovalStatus.rejected;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'profile_image': profileImage,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'role': role.name,
      'specialty': specialty,
      'experience': experience,
      'consultation_fee': consultationFee,
      'license_document_path': licenseDocumentPath,
      'approval_status': approvalStatus?.name,
      'approval_note': approvalNote,
      'is_online': isOnline,
      'mobile_money_number': mobileMoneyNumber,
      'mobile_money_provider': mobileMoneyProvider,
      'payout_recipient_code': payoutRecipientCode,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    final roleValue = json['role']?.toString();
    final specialtyValue = json['specialty'];
    final experienceValue = json['experience'];
    final consultationFeeValue =
        json['consultation_fee'] ?? json['consultationFee'];
    final licenseDocumentValue =
        json['license_document_path'] ?? json['licenseDocumentPath'];
    final approvalStatusValue =
        json['approval_status'] ?? json['approvalStatus'];
    final approvalNoteValue = json['approval_note'] ?? json['approvalNote'];
    final isOnlineValue = json['is_online'] ?? json['isOnline'];
    final mobileMoneyNumberValue =
        json['mobile_money_number'] ?? json['mobileMoneyNumber'];
    final mobileMoneyProviderValue =
        json['mobile_money_provider'] ?? json['mobileMoneyProvider'];
    final payoutRecipientCodeValue =
        json['payout_recipient_code'] ?? json['payoutRecipientCode'];

    return UserModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? json['firstName'] ?? '').toString(),
      lastName: (json['last_name'] ?? json['lastName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      profileImage:
          (json['profile_image'] ?? json['profileImage'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      createdAt: createdAtValue != null
          ? DateTime.parse(createdAtValue.toString())
          : DateTime.now(),
      role: UserRole.values.firstWhere(
        (e) => e.name == roleValue,
        orElse: () => UserRole.patient,
      ),
      specialty: specialtyValue?.toString(),
      experience: experienceValue?.toString(),
      consultationFee: consultationFeeValue != null
          ? double.tryParse(consultationFeeValue.toString())
          : null,
      licenseDocumentPath: licenseDocumentValue?.toString(),
      approvalStatus: approvalStatusValue != null
          ? DoctorApprovalStatus.values.firstWhere(
              (e) => e.name == approvalStatusValue.toString(),
              orElse: () => DoctorApprovalStatus.pending,
            )
          : null,
      approvalNote: approvalNoteValue?.toString(),
      isOnline: isOnlineValue == true ||
          isOnlineValue?.toString().toLowerCase() == 'true' ||
          isOnlineValue?.toString() == '1',
      mobileMoneyNumber: mobileMoneyNumberValue?.toString(),
      mobileMoneyProvider: mobileMoneyProviderValue?.toString(),
      payoutRecipientCode: payoutRecipientCodeValue?.toString(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    String? bio,
    DateTime? createdAt,
    UserRole? role,
    String? specialty,
    String? experience,
    double? consultationFee,
    String? licenseDocumentPath,
    DoctorApprovalStatus? approvalStatus,
    String? approvalNote,
    bool? isOnline,
    String? mobileMoneyNumber,
    String? mobileMoneyProvider,
    String? payoutRecipientCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
      consultationFee: consultationFee ?? this.consultationFee,
      licenseDocumentPath: licenseDocumentPath ?? this.licenseDocumentPath,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvalNote: approvalNote ?? this.approvalNote,
      isOnline: isOnline ?? this.isOnline,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      mobileMoneyProvider: mobileMoneyProvider ?? this.mobileMoneyProvider,
      payoutRecipientCode: payoutRecipientCode ?? this.payoutRecipientCode,
    );
  }
}
