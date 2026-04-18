import 'dart:async';
import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final _supabase = Supabase.instance.client;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _supabase.auth.currentUser != null;

  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isDoctorApproved => _currentUser?.isDoctorApproved ?? false;

  List<UserModel> get pendingDoctors => [];
  List<UserModel> get approvedDoctors => [];

  String resolveUserId({
    Object? fallback,
    String defaultValue = 'user_123',
  }) {
    final currentUserId = _normalizeUserId(_currentUser?.id);
    if (currentUserId != null) {
      return currentUserId;
    }

    final authUser = _supabase.auth.currentUser;
    if (authUser != null) {
      return authUser.id;
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

  /// Fetch user profile from Supabase 'profiles' table
  Future<UserModel?> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(
            Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Profile fetch timeout'),
          );

      if (data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  /// Create or update user profile in Supabase
  Future<void> _upsertProfile(UserModel user) async {
    try {
      await _supabase.from('profiles').upsert(user.toJson());
    } catch (e) {
      print('Error upserting profile: \$e');
    }
  }

  /// Initialize current user from existing Supabase session
  Future<void> initSession() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        _currentUser = await _fetchProfile(authUser.id).timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ Profile fetch timeout for user: ${authUser.id}');
            return null;
          },
        );
      }
    } catch (e) {
      print('❌ Error initializing session: $e');
      // Don't rethrow - allow app to continue even if profile fetch fails
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password cannot be empty';
      }

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      if (password.length < 3) {
        throw 'Password must be at least 3 characters';
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = await _fetchProfile(response.user!.id);

        // If no profile exists yet, create a basic patient profile
        if (_currentUser == null) {
          _currentUser = UserModel(
            id: response.user!.id,
            email: email,
            firstName: email.split('@')[0],
            lastName: '',
            phone: '',
            createdAt: DateTime.now(),
            role: UserRole.patient,
          );
          await _upsertProfile(_currentUser!);
        }

        return true;
      }

      return false;
    } catch (e) {
      if (e is AuthException) {
        throw e.message;
      }
      rethrow;
    }
  }

  /// Sign up as patient
  Future<bool> signup(String email, String firstName, String lastName,
      String phone, String password) async {
    try {
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

      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = UserModel(
          id: response.user!.id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          createdAt: DateTime.now(),
          role: UserRole.patient,
        );

        await _upsertProfile(_currentUser!);
        return true;
      }

      return false;
    } catch (e) {
      if (e is AuthException) {
        throw e.message;
      }
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

      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      if (licenseDocumentPath.isEmpty) {
        throw 'Medical license document is required';
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = UserModel(
          id: response.user!.id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
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

        await _upsertProfile(_currentUser!);
        return true;
      }

      return false;
    } catch (e) {
      if (e is AuthException) {
        throw e.message;
      }
      rethrow;
    }
  }

  /// Admin approves doctor
  Future<void> approveDoctor(String doctorId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'approval_status': 'approved'}).eq('id', doctorId);

      if (_currentUser?.id == doctorId) {
        _currentUser = _currentUser!.copyWith(
          approvalStatus: DoctorApprovalStatus.approved,
        );
      }
    } catch (e) {
      print('Error approving doctor: \$e');
    }
  }

  /// Admin rejects doctor
  Future<void> rejectDoctor(String doctorId, String reason) async {
    try {
      await _supabase.from('profiles').update({
        'approval_status': 'rejected',
        'approval_note': reason,
      }).eq('id', doctorId);

      if (_currentUser?.id == doctorId) {
        _currentUser = _currentUser!.copyWith(
          approvalStatus: DoctorApprovalStatus.rejected,
          approvalNote: reason,
        );
      }
    } catch (e) {
      print('Error rejecting doctor: \$e');
    }
  }

  /// Toggle doctor online status
  Future<void> toggleDoctorOnline(bool isOnline) async {
    if (_currentUser?.isDoctor ?? false) {
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      try {
        await _supabase
            .from('profiles')
            .update({'is_online': isOnline}).eq('id', _currentUser!.id);
      } catch (e) {
        print('Error toggling online status: \$e');
      }
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
  }

  Future<bool> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      if (e is AuthException) {
        throw e.message;
      }
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
