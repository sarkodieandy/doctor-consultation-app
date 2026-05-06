import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final _store = UiMockStore.instance;

  UserModel? _currentUser;
  supabase.SupabaseClient? get _client {
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

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
    final remoteUser = _client?.auth.currentUser;
    if (remoteUser != null) {
      _currentUser = await _loadRemoteUser(remoteUser);
      _store.currentUserId = _currentUser?.id;
      return;
    }

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

    if (_client != null && normalizedLogin.contains('@')) {
      try {
        final response = await _client!.auth.signInWithPassword(
          email: normalizedLogin,
          password: trimmedPassword,
        );
        final remoteUser = response.user ?? _client!.auth.currentUser;
        if (remoteUser == null) {
          throw 'Unable to start Supabase session.';
        }
        _currentUser = await _loadRemoteUser(remoteUser);
        _store.currentUserId = _currentUser?.id;
        if (_currentUser != null) {
          _store.saveUser(_currentUser!);
        }
        return true;
      } catch (_) {
        // Keep seeded local preview users usable while Supabase is being set up.
      }
    }

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
      id: _client?.auth.currentUser?.id ?? _store.nextId('user'),
      email: normalizedEmail,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      profileImage: profilePictureFile?.path ?? '',
      createdAt: DateTime.now(),
      role: UserRole.patient,
    );

    final remoteUser = await _createRemoteUser(
      user: user,
      password: password,
      role: UserRole.patient,
      profilePictureFile: profilePictureFile,
    );
    final savedUser = remoteUser ?? user;

    _store.passwordsByEmail[normalizedEmail] = password;
    _store.saveUser(savedUser);
    _store.currentUserId = savedUser.id;
    _currentUser = savedUser;
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
      id: _client?.auth.currentUser?.id ?? _store.nextId('user'),
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

    final remoteUser = await _createRemoteUser(
      user: user,
      password: password,
      role: UserRole.doctor,
      profilePictureFile: profilePictureFile,
      licenseDocumentFile: licenseDocumentFile,
    );
    final savedUser = remoteUser ?? user;

    _store.passwordsByEmail[normalizedEmail] = password;
    _store.saveUser(savedUser);
    _store.currentUserId = savedUser.id;
    _currentUser = savedUser;
    return true;
  }

  Future<void> approveDoctor(String doctorId) async {
    final doctor = _store.findUserById(doctorId);
    if (doctor == null) return;
    final updated = doctor.copyWith(
      approvalStatus: DoctorApprovalStatus.approved,
      approvalNote: 'Approved.',
    );
    await _upsertProfile(updated);
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
    await _upsertProfile(updated);
    _store.saveUser(updated);
    if (_currentUser?.id == doctorId) {
      _currentUser = updated;
    }
  }

  Future<void> toggleDoctorOnline(bool isOnline) async {
    final user = currentUser;
    if (user == null || !user.isDoctor) return;
    final updated = user.copyWith(isOnline: isOnline);
    await _upsertProfile(updated);
    _store.saveUser(updated);
    _currentUser = updated;
  }

  Future<void> logout() async {
    await _client?.auth.signOut();
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
    return await _uploadRemoteProfilePicture(userId, imageFile) ??
        imageFile.path;
  }

  Future<void> updateCurrentUser(
    UserModel user, {
    XFile? profilePictureFile,
  }) async {
    final profileImageUrl = profilePictureFile == null
        ? user.profileImage
        : await _uploadRemoteProfilePicture(user.id, profilePictureFile);
    final updatedUser = user.copyWith(
      profileImage: profileImageUrl ?? user.profileImage,
    );
    await _upsertProfile(updatedUser);
    _store.saveUser(updatedUser);
    _currentUser = updatedUser;
    _store.currentUserId = user.id;
  }

  Future<UserModel?> _createRemoteUser({
    required UserModel user,
    required String password,
    required UserRole role,
    XFile? profilePictureFile,
    PlatformFile? licenseDocumentFile,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.auth.signUp(
        email: user.email,
        password: password,
        data: {
          'first_name': user.firstName,
          'last_name': user.lastName,
          'phone': user.phone,
          'role': role.name,
        },
      );
      final remoteUser = response.user;
      if (remoteUser == null) return null;

      final profileImageUrl = profilePictureFile == null
          ? user.profileImage
          : await _uploadRemoteProfilePicture(
              remoteUser.id, profilePictureFile);
      final licenseDocumentUrl = licenseDocumentFile == null
          ? user.licenseDocumentPath
          : await _uploadRemoteDoctorDocument(
              remoteUser.id,
              licenseDocumentFile,
            );
      final remoteProfile = user.copyWith(
        id: remoteUser.id,
        profileImage: profileImageUrl ?? user.profileImage,
        licenseDocumentPath: licenseDocumentUrl ?? user.licenseDocumentPath,
      );
      await _upsertProfile(remoteProfile);
      return remoteProfile;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> _loadRemoteUser(supabase.User remoteUser) async {
    try {
      final data = await _client!
          .from('profiles')
          .select()
          .eq('id', remoteUser.id)
          .maybeSingle();
      if (data != null) {
        return UserModel.fromJson({
          ...Map<String, dynamic>.from(data),
          'id': remoteUser.id,
          'email': remoteUser.email ?? data['email'] ?? '',
        });
      }
    } catch (_) {
      // Use auth metadata when the profiles table is not ready.
    }

    final metadata = remoteUser.userMetadata ?? const <String, dynamic>{};
    return UserModel(
      id: remoteUser.id,
      email: remoteUser.email ?? '',
      firstName: (metadata['first_name'] ?? '').toString(),
      lastName: (metadata['last_name'] ?? '').toString(),
      phone: (metadata['phone'] ?? '').toString(),
      createdAt: DateTime.tryParse(remoteUser.createdAt) ?? DateTime.now(),
      role: UserRole.values.firstWhere(
        (role) => role.name == metadata['role']?.toString(),
        orElse: () => UserRole.patient,
      ),
    );
  }

  Future<void> _upsertProfile(UserModel user) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.from('profiles').upsert(user.toJson());
    } catch (_) {
      // Profile persistence is optional until the Supabase schema exists.
    }
  }

  Future<String?> _uploadRemoteProfilePicture(
    String userId,
    XFile imageFile,
  ) async {
    final client = _client;
    if (client == null || userId.trim().isEmpty) return null;

    try {
      final rawExtension = imageFile.name.split('.').last.toLowerCase();
      final safeExtension = rawExtension.isEmpty || rawExtension.length > 5
          ? 'jpg'
          : rawExtension.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final path =
          'profile-pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

      await client.storage.from('profile-images').uploadBinary(
            path,
            await imageFile.readAsBytes(),
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return client.storage.from('profile-images').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadRemoteDoctorDocument(
    String userId,
    PlatformFile documentFile,
  ) async {
    final client = _client;
    final bytes = documentFile.bytes;
    if (client == null || userId.trim().isEmpty || bytes == null) return null;

    try {
      final rawExtension = documentFile.name.split('.').last.toLowerCase();
      final safeExtension = rawExtension.isEmpty || rawExtension.length > 5
          ? 'pdf'
          : rawExtension.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final path =
          'doctor-verification/$userId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

      await client.storage.from('doctor-documents').uploadBinary(
            path,
            bytes,
            fileOptions: supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return client.storage.from('doctor-documents').getPublicUrl(path);
    } catch (_) {
      return null;
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
