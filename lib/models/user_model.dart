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
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'] ?? json['profileImage'] ?? '',
      bio: json['bio'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      specialty: json['specialty'],
      experience: json['experience'],
      consultationFee:
          (json['consultation_fee'] ?? json['consultationFee'])?.toDouble(),
      licenseDocumentPath:
          json['license_document_path'] ?? json['licenseDocumentPath'],
      approvalStatus: (json['approval_status'] ?? json['approvalStatus']) !=
              null
          ? DoctorApprovalStatus.values.firstWhere(
              (e) =>
                  e.name == (json['approval_status'] ?? json['approvalStatus']),
              orElse: () => DoctorApprovalStatus.pending,
            )
          : null,
      approvalNote: json['approval_note'] ?? json['approvalNote'],
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
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
    );
  }
}
