import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final _store = UiMockStore.instance;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser ?? _store.currentUser;

  bool get isLoggedIn => currentUser != null;
  bool get isDoctor => currentUser?.isDoctor ?? false;
  bool get isPatient => currentUser?.isPatient ?? false;
  bool get isDoctorApproved => currentUser?.isDoctorApproved ?? false;

  List<UserModel> get pendingDoctors => _store.users
      .where((user) =>
          user.isDoctor && user.approvalStatus == DoctorApprovalStatus.pending)
      .toList();

  List<UserModel> get approvedDoctors => _store.users
      .where((user) => user.isDoctor && user.isDoctorApproved)
      .toList();

  String resolveUserId({
    Object? fallback,
    String defaultValue = 'user_123',
  }) {
    final currentUserId = _normalizeUserId(currentUser?.id);
    if (currentUserId != null) {
      return currentUserId;
    }

    if (fallback is String) {
      return _normalizeUserId(fallback) ?? defaultValue;
    }

    if (fallback is Map) {
      final fallbackUserId = fallback['userId'];
      if (fallbackUserId is String) {
        return _normalizeUserId(fallbackUserId) ?? defaultValue;
      }

      if (fallbackUserId != null) {
        return _normalizeUserId(fallbackUserId.toString()) ?? defaultValue;
      }
    }

    return defaultValue;
  }

  Future<void> initSession() async {
    final userId = _store.currentUserId;
    if (userId == null) {
      _currentUser = null;
      return;
    }
    _currentUser = _store.findUserById(userId);
  }

  Future<bool> login(String login, String password) async {
    final normalizedLogin = login.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (normalizedLogin.isEmpty) {
      throw 'Please enter your email or username.';
    }
    if (trimmedPassword.isEmpty) throw 'Please enter your password.';

    final resolvedEmail = _store.resolveEmailFromLogin(normalizedLogin);
    if (resolvedEmail == null) {
      throw 'No account found with this email/username. Please sign up first.';
    }

    final user = _store.findUserByEmail(resolvedEmail);
    if (user == null) {
      throw 'No account found with this email/username. Please sign up first.';
    }

    final storedPassword = _store.passwordsByEmail[resolvedEmail];
    if (storedPassword == null || storedPassword != trimmedPassword) {
      throw 'Incorrect password. Please try again.';
    }

    _currentUser = user;
    _store.currentUserId = user.id;
    return true;
  }

  Future<bool> signup(
    String email,
    String firstName,
    String lastName,
    String phone,
    String password, {
    XFile? profilePictureFile,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty) {
      throw 'All fields are required';
    }
    if (!_isValidEmail(normalizedEmail)) {
      throw 'Invalid email format';
    }
    if (password.length < 6) {
      throw 'Password must be at least 6 characters';
    }
    if (_store.findUserByEmail(normalizedEmail) != null) {
      throw 'An account with this email already exists';
    }

    final user = UserModel(
      id: _store.nextId('user'),
      email: normalizedEmail,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      profileImage: profilePictureFile?.path ?? '',
      createdAt: DateTime.now(),
      role: UserRole.patient,
    );

    _store.passwordsByEmail[normalizedEmail] = password;
    _store.saveUser(user);
    _store.currentUserId = user.id;
    _currentUser = user;
    return true;
  }

  Future<bool> signupDoctor({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required String specialty,
    required String experience,
    required double consultationFee,
    required String licenseDocumentPath,
    PlatformFile? licenseDocumentFile,
    String bio = '',
    XFile? profilePictureFile,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        specialty.isEmpty ||
        experience.isEmpty) {
      throw 'All fields are required';
    }
    if (!_isValidEmail(normalizedEmail)) {
      throw 'Invalid email format';
    }
    if (password.length < 6) {
      throw 'Password must be at least 6 characters';
    }
    if (licenseDocumentPath.isEmpty) {
      throw 'Medical license document is required';
    }
    if (_store.findUserByEmail(normalizedEmail) != null) {
      throw 'An account with this email already exists';
    }

    final user = UserModel(
      id: _store.nextId('user'),
      email: normalizedEmail,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      bio: bio,
      profileImage: profilePictureFile?.path ?? '',
      createdAt: DateTime.now(),
      role: UserRole.doctor,
      specialty: specialty,
      experience: experience,
      consultationFee: consultationFee,
      licenseDocumentPath: licenseDocumentPath,
      approvalStatus: DoctorApprovalStatus.pending,
      isOnline: false,
    );

    _store.passwordsByEmail[normalizedEmail] = password;
    _store.saveUser(user);
    _store.currentUserId = user.id;
    _currentUser = user;
    return true;
  }

  Future<void> approveDoctor(String doctorId) async {
    final doctor = _store.findUserById(doctorId);
    if (doctor == null) return;
    final updated = doctor.copyWith(
      approvalStatus: DoctorApprovalStatus.approved,
      approvalNote: 'Approved in local UI-only mode.',
    );
    _store.saveUser(updated);
    if (_currentUser?.id == doctorId) {
      _currentUser = updated;
    }
  }

  Future<void> rejectDoctor(String doctorId, String reason) async {
    final doctor = _store.findUserById(doctorId);
    if (doctor == null) return;
    final updated = doctor.copyWith(
      approvalStatus: DoctorApprovalStatus.rejected,
      approvalNote: reason,
    );
    _store.saveUser(updated);
    if (_currentUser?.id == doctorId) {
      _currentUser = updated;
    }
  }

  Future<void> toggleDoctorOnline(bool isOnline) async {
    final user = currentUser;
    if (user == null || !user.isDoctor) return;
    final updated = user.copyWith(isOnline: isOnline);
    _store.saveUser(updated);
    _currentUser = updated;
  }

  Future<void> logout() async {
    _store.currentUserId = null;
    _currentUser = null;
  }

  Future<bool> resetPassword(String email) async {
    if (!_isValidEmail(email.trim().toLowerCase())) {
      throw 'Invalid email format';
    }
    return _store.findUserByEmail(email.trim().toLowerCase()) != null;
  }

  Future<String> uploadProfilePicture(String userId, XFile imageFile) async {
    return imageFile.path;
  }

  Future<void> updateCurrentUser(
    UserModel user, {
    XFile? profilePictureFile,
  }) async {
    _store.saveUser(user);
    _currentUser = user;
    _store.currentUserId = user.id;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  String? _normalizeUserId(String? userId) {
    final normalized = userId?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
