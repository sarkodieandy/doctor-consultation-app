import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/document_verification_service.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';
import 'package:doctor_consultation_app/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class DoctorRegistrationService {
  static final DoctorRegistrationService _instance =
      DoctorRegistrationService._internal();

  factory DoctorRegistrationService() {
    return _instance;
  }

  DoctorRegistrationService._internal();

  final _store = UiMockStore.instance;
  final _storageService = StorageService();
  final _authService = AuthService();
  final _verificationService = DocumentVerificationService();

  Future<bool> registerDoctor({
    required String firstName,
    required String lastName,
    required String phone,
    required String specialty,
    required String experience,
    required double consultationFee,
    required String bio,
    PlatformFile? licenseFile,
    PlatformFile? ghanaCardFile,
    XFile? profileImageFile,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return false;
    }

    String? licensePath;
    if (licenseFile != null) {
      licensePath = await _storageService.uploadDoctorLicense(
        currentUser.id,
        licenseFile,
        'license_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    }

    String? ghanaCardPath;
    if (ghanaCardFile != null) {
      ghanaCardPath = await _storageService.uploadDoctorLicense(
        currentUser.id,
        ghanaCardFile,
        'ghana_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final updatedDoctor = currentUser.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      role: UserRole.doctor,
      specialty: specialty,
      experience: experience,
      consultationFee: consultationFee,
      bio: bio,
      profileImage: profileImageFile?.path ?? currentUser.profileImage,
      licenseDocumentPath: licensePath ?? currentUser.licenseDocumentPath,
      approvalStatus: DoctorApprovalStatus.pending,
      approvalNote: 'Awaiting local review',
      isOnline: false,
    );

    await _authService.updateCurrentUser(updatedDoctor);
    await _verificationService.verifyDoctorDocuments(
      doctorId: updatedDoctor.id,
      licensePath:
          licensePath ?? updatedDoctor.licenseDocumentPath ?? 'local-license',
      ghanaCardPath: ghanaCardPath,
      doctorName: updatedDoctor.fullName,
      specialty: specialty,
    );
    return true;
  }

  Future<DoctorApprovalStatus?> getDoctorApprovalStatus(String doctorId) async {
    return _store.findUserById(doctorId)?.approvalStatus;
  }

  Future<String?> getDoctorLicensePath(String doctorId) async {
    return _store.findUserById(doctorId)?.licenseDocumentPath;
  }

  Future<bool> updateDoctorProfile({
    required String doctorId,
    String? firstName,
    String? lastName,
    String? phone,
    String? specialty,
    String? experience,
    double? consultationFee,
    String? bio,
  }) async {
    final doctor = _store.findUserById(doctorId);
    if (doctor == null) return false;

    _store.saveUser(
      doctor.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        specialty: specialty,
        experience: experience,
        consultationFee: consultationFee,
        bio: bio,
      ),
    );
    return true;
  }

  Future<List<UserModel>> getPendingDoctorRegistrations() async {
    return _store.users
        .where((user) =>
            user.isDoctor &&
            user.approvalStatus == DoctorApprovalStatus.pending)
        .toList();
  }

  Future<List<UserModel>> getApprovedDoctors() async {
    return _store.users.where((user) => user.isDoctorApproved).toList();
  }

  Future<List<UserModel>> getAllDoctors() async {
    return _store.users.where((user) => user.isDoctor).toList();
  }

  Future<UserModel?> getDoctorById(String doctorId) async {
    final doctor = _store.findUserById(doctorId);
    if (doctor == null || !doctor.isDoctor) {
      return null;
    }
    return doctor;
  }
}
