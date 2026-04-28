import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  static const String licenseBucket = 'local-license-bucket';

  Future<String?> uploadDoctorLicense(
    String doctorId,
    PlatformFile licenseFile,
    String fileName,
  ) async {
    final resolvedName =
        licenseFile.name.isNotEmpty ? licenseFile.name : fileName;
    return 'local://doctor_licenses/$doctorId/$resolvedName';
  }

  Future<String?> getLicenseDownloadUrl(String storagePath) async {
    return storagePath;
  }

  Future<bool> deleteLicense(String storagePath) async {
    return true;
  }

  Future<bool> licenseExists(String storagePath) async {
    return storagePath.isNotEmpty;
  }

  Future<bool> licenseFileExists(String storagePath) async {
    return storagePath.isNotEmpty;
  }

  Future<String?> uploadProfileImage(
    String userId,
    XFile imageFile,
  ) async {
    return imageFile.path;
  }

  Future<String?> getProfileImageUrl(String storagePath) async {
    return storagePath;
  }
}
