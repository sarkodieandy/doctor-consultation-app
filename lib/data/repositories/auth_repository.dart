import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class AuthRepository {
  final AuthService _local = AuthService();

  Future<void> initSession() async {
    await _local.initSession();
  }

  UserModel? get currentUser => _local.currentUser;

  bool get isLoggedIn => _local.isLoggedIn;

  Future<UserModel> login(String login, String password) async {
    // UI-only: Use local AuthService
    await _local.login(login, password);
    return _local.currentUser!;
  }

  Future<UserModel> register(
    String email,
    String firstName,
    String lastName,
    String phone,
    String password, {
    XFile? profilePictureFile,
  }) async {
    // UI-only: Use local AuthService
    await _local.signup(email, firstName, lastName, phone, password,
        profilePictureFile: profilePictureFile);
    return _local.currentUser!;
  }

  Future<void> logout() async {
    await _local.logout();
  }
}
