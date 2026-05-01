import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  static const String licenseBucket = 'doctor-documents';

  supabase.SupabaseClient? get _client {
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadDoctorLicense(
    String doctorId,
    PlatformFile licenseFile,
    String fileName,
  ) async {
    final client = _client;
    final bytes = licenseFile.bytes;
    if (client != null && bytes != null) {
      try {
        final resolvedName =
            licenseFile.name.isNotEmpty ? licenseFile.name : fileName;
        final extension = resolvedName.split('.').last.toLowerCase();
        final safeExtension = extension.isEmpty || extension.length > 5
            ? 'pdf'
            : extension.replaceAll(RegExp(r'[^a-z0-9]'), '');
        final path =
            'doctor-verification/$doctorId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
        await client.storage.from(licenseBucket).uploadBinary(
              path,
              bytes,
              fileOptions: supabase.FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
        return client.storage.from(licenseBucket).getPublicUrl(path);
      } catch (_) {}
    }

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
