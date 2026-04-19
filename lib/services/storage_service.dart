import 'dart:io';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  static const String licenseBucket = 'local-license-bucket';

  Future<String?> uploadDoctorLicense(
    String doctorId,
    File licenseFile,
    String fileName,
  ) async {
    return 'local://doctor_licenses/$doctorId/$fileName';
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
    File imageFile,
  ) async {
    return imageFile.path;
  }

  Future<String?> getProfileImageUrl(String storagePath) async {
    return storagePath;
  }
}
