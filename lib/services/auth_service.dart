import 'package:doctor_consultation_app/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isDoctorApproved => _currentUser?.isDoctorApproved ?? false;

  // Simulated doctor database for demo
  final List<UserModel> _registeredDoctors = [];

  List<UserModel> get pendingDoctors =>
      _registeredDoctors.where((d) => d.isDoctorPending).toList();

  List<UserModel> get approvedDoctors =>
      _registeredDoctors.where((d) => d.isDoctorApproved).toList();

  String resolveUserId({
    Object? fallback,
    String defaultValue = 'user_123',
  }) {
    final currentUserId = _normalizeUserId(_currentUser?.id);
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

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      await Future.delayed(Duration(seconds: 1));

      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password cannot be empty';
      }

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      if (password.length < 3) {
        throw 'Password must be at least 3 characters';
      }

      // Check if this is a registered doctor
      final doctorMatch = _registeredDoctors.where((d) => d.email == email);
      if (doctorMatch.isNotEmpty) {
        _currentUser = doctorMatch.first;
        return true;
      }

      // Default: create patient user
      _currentUser = UserModel(
        id: email.split('@')[0],
        email: email,
        firstName: email.split('@')[0],
        lastName: 'User',
        phone: '+233000000000',
        profileImage: '',
        bio: '',
        createdAt: DateTime.now(),
        role: UserRole.patient,
      );

      return true;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Sign up as patient
  Future<bool> signup(String email, String firstName, String lastName,
      String phone, String password) async {
    try {
      await Future.delayed(Duration(seconds: 1));

      if (email.isEmpty ||
          password.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          phone.isEmpty) {
        throw 'All fields are required';
      }

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      if (password.length < 3) {
        throw 'Password must be at least 3 characters';
      }

      _currentUser = UserModel(
        id: email.split('@')[0],
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: '',
        bio: '',
        createdAt: DateTime.now(),
        role: UserRole.patient,
      );

      return true;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  /// Sign up as doctor (requires admin approval)
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
    String bio = '',
  }) async {
    try {
      await Future.delayed(Duration(seconds: 1));

      if (email.isEmpty ||
          password.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          phone.isEmpty ||
          specialty.isEmpty ||
          experience.isEmpty) {
        throw 'All fields are required';
      }

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      if (password.length < 3) {
        throw 'Password must be at least 3 characters';
      }

      if (licenseDocumentPath.isEmpty) {
        throw 'Medical license document is required';
      }

      final doctor = UserModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: '',
        bio: bio,
        createdAt: DateTime.now(),
        role: UserRole.doctor,
        specialty: specialty,
        experience: experience,
        consultationFee: consultationFee,
        licenseDocumentPath: licenseDocumentPath,
        approvalStatus: DoctorApprovalStatus.pending,
        isOnline: false,
      );

      _registeredDoctors.add(doctor);
      _currentUser = doctor;

      return true;
    } catch (e) {
      print('Doctor signup error: $e');
      rethrow;
    }
  }

  /// Admin approves doctor
  void approveDoctor(String doctorId) {
    final index = _registeredDoctors.indexWhere((d) => d.id == doctorId);
    if (index != -1) {
      _registeredDoctors[index] = _registeredDoctors[index].copyWith(
        approvalStatus: DoctorApprovalStatus.approved,
      );
      if (_currentUser?.id == doctorId) {
        _currentUser = _registeredDoctors[index];
      }
    }
  }

  /// Admin rejects doctor
  void rejectDoctor(String doctorId, String reason) {
    final index = _registeredDoctors.indexWhere((d) => d.id == doctorId);
    if (index != -1) {
      _registeredDoctors[index] = _registeredDoctors[index].copyWith(
        approvalStatus: DoctorApprovalStatus.rejected,
        approvalNote: reason,
      );
      if (_currentUser?.id == doctorId) {
        _currentUser = _registeredDoctors[index];
      }
    }
  }

  /// Toggle doctor online status
  void toggleDoctorOnline(bool isOnline) {
    if (_currentUser?.isDoctor ?? false) {
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      final index =
          _registeredDoctors.indexWhere((d) => d.id == _currentUser!.id);
      if (index != -1) {
        _registeredDoctors[index] = _currentUser!;
      }
    }
  }

  void logout() {
    _currentUser = null;
  }

  Future<bool> resetPassword(String email) async {
    try {
      await Future.delayed(Duration(seconds: 1));

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      return true;
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  String? _normalizeUserId(String? userId) {
    final normalized = userId?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
