import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepository {
  final AuthService _local = AuthService();

  UserModel? get currentUser => _local.currentUser;

  Future<UserModel?> getProfile() async {
    return _local.currentUser;
  }

  Future<UserModel?> updateProfile(Map<String, dynamic> updates) async {
    // Local update only
    final current = _local.currentUser;
    if (current == null) return null;
    final updated = current.copyWith(
      firstName:
          updates['first_name'] ?? updates['firstName'] ?? current.firstName,
      lastName: updates['last_name'] ?? updates['lastName'] ?? current.lastName,
      phone: updates['phone'] ?? current.phone,
      bio: updates['bio'] ?? current.bio,
    );
    await _local.updateCurrentUser(updated);
    return updated;
  }

  Future<String> uploadAvatar(XFile imageFile) async {
    // UI-only: No-op or mock
    return imageFile.path;
  }
}
