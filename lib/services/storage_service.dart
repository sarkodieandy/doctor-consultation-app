/// File Upload and Storage Service
/// Handles doctor license document uploads/downloads
/// Uses Supabase Storage for file management

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  final _supabase = Supabase.instance.client;
  static const String licenseBucket = 'doctor-licenses';

  /// Upload doctor license document
  /// Returns the file path if successful, null if failed
  Future<String?> uploadDoctorLicense(
    String doctorId,
    File licenseFile,
    String fileName,
  ) async {
    try {
      print('📤 Uploading license for doctor: $doctorId');

      // Create path: doctor-licenses/doctor_id/license_filename
      final storagePath = 'doctor_licenses/$doctorId/$fileName';

      // Upload file
      await _supabase.storage.from(licenseBucket).upload(
            storagePath,
            licenseFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('✅ License uploaded successfully: $storagePath');
      return storagePath;
    } catch (e) {
      print('❌ Error uploading license: $e');
      return null;
    }
  }

  /// Get download URL for license document (for admin download)
  Future<String?> getLicenseDownloadUrl(String storagePath) async {
    try {
      final url =
          _supabase.storage.from(licenseBucket).getPublicUrl(storagePath);

      print('🔗 Download URL generated: $url');
      return url;
    } catch (e) {
      print('❌ Error generating download URL: $e');
      return null;
    }
  }

  /// Delete license document (if doctor is rejected)
  Future<bool> deleteLicense(String storagePath) async {
    try {
      await _supabase.storage.from(licenseBucket).remove([storagePath]);
      print('🗑 License deleted: $storagePath');
      return true;
    } catch (e) {
      print('❌ Error deleting license: $e');
      return false;
    }
  }

  /// Check if license exists
  Future<bool> licenseExists(String storagePath) async {
    try {
      final files =
          await _supabase.storage.from(licenseBucket).list(path: storagePath);
      return files.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if license file exists
  Future<bool> licenseFileExists(String storagePath) async {
    try {
      final fileName = storagePath.split('/').last;
      final objects = await _supabase.storage
          .from(licenseBucket)
          .list(path: storagePath.replaceAll('/$fileName', ''));
      return objects.any((obj) => obj.name == fileName);
    } catch (e) {
      return false;
    }
  }

  /// Upload profile image (optional for doctors)
  Future<String?> uploadProfileImage(
    String userId,
    File imageFile,
  ) async {
    try {
      print('📤 Uploading profile image for user: $userId');

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'profile_images/$userId/$fileName';

      await _supabase.storage.from('profiles').upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('✅ Profile image uploaded: $storagePath');
      return storagePath;
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return null;
    }
  }

  /// Get profile image download URL
  Future<String?> getProfileImageUrl(String storagePath) async {
    try {
      final url = _supabase.storage.from('profiles').getPublicUrl(storagePath);
      return url;
    } catch (e) {
      return null;
    }
  }
}
