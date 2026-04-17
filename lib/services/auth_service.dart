import 'package:doctor_consultation_app/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Simulated storage - replace with real backend/database
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

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

  // Simulated user database - replace with real backend
  final Map<String, String> _userDatabase = {
    'test@example.com': 'password123',
  };

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password cannot be empty';
      }

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      if (password.length < 3) {
        throw 'Password must be at least 3 characters';
      }

      // Create user object (in real app, get from backend)
      _currentUser = UserModel(
        id: email.split('@')[0],
        email: email,
        firstName: email.split('@')[0],
        lastName: 'User',
        phone: '+1234567890',
        profileImage: '',
        bio: '',
        createdAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<bool> signup(String email, String firstName, String lastName,
      String phone, String password) async {
    try {
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      // Basic validation
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

      // Create user object
      _currentUser = UserModel(
        id: email.split('@')[0],
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: '',
        bio: '',
        createdAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  /// Logout
  void logout() {
    _currentUser = null;
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      if (!_isValidEmail(email)) {
        throw 'Invalid email format';
      }

      if (!_userDatabase.containsKey(email)) {
        throw 'Email not found';
      }

      // In real app, send reset link to email
      return true;
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  /// Helper method to validate email
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  String? _normalizeUserId(String? userId) {
    final normalized = userId?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
