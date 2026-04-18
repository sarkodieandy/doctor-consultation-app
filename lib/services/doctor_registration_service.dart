/// Doctor Registration Service
/// Handles doctor registration, license upload, and approval workflow
/// Includes automatic document verification via OCR

import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/document_verification_service.dart';
import 'package:doctor_consultation_app/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class DoctorRegistrationService {
  static final DoctorRegistrationService _instance =
      DoctorRegistrationService._internal();

  factory DoctorRegistrationService() {
    return _instance;
  }

  DoctorRegistrationService._internal();

  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();
  final _authService = AuthService();
  final _verificationService = DocumentVerificationService();

  /// Complete doctor registration with license upload
  /// Automatically verifies documents and approves/rejects based on OCR results
  /// Returns true if successful, false otherwise
  Future<bool> registerDoctor({
    required String firstName,
    required String lastName,
    required String phone,
    required String specialty,
    required String experience, // e.g., "5" for 5 years
    required double consultationFee,
    required String bio,
    File? licenseFile,
    File? ghanaCardFile,
    String? profileImageFile,
  }) async {
    try {
      print('👨‍⚕️ Starting doctor registration...');

      final userId = _authService.currentUser?.id;
      if (userId == null) {
        print('❌ User not authenticated');
        return false;
      }

      // Step 1: Upload license document
      String? licensePath;
      if (licenseFile != null) {
        final fileName = 'license_${DateTime.now().millisecondsSinceEpoch}.pdf';
        licensePath = await _storageService.uploadDoctorLicense(
          userId,
          licenseFile,
          fileName,
        );

        if (licensePath == null) {
          print('❌ Failed to upload license');
          return false;
        }
      }

      // Step 1b: Upload Ghana Card (if provided)
      String? ghanaCardPath;
      if (ghanaCardFile != null) {
        final fileName =
            'ghana_card_${DateTime.now().millisecondsSinceEpoch}.jpg';
        ghanaCardPath = await _storageService.uploadDoctorLicense(
          userId,
          ghanaCardFile,
          fileName,
        );
      }

      // Step 2: Create user profile in database (with pending status)
      final registerData = {
        'id': userId,
        'email': _authService.currentUser?.email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': 'doctor',
        'specialty': specialty,
        'experience': experience,
        'consultation_fee': consultationFee,
        'license_document_path': licensePath,
        'ghana_card_path': ghanaCardPath,
        'approval_status': 'pending',
        'approval_note': 'Awaiting automated document verification...',
        'bio': bio,
        'is_online': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').upsert(registerData);

      print('✅ Doctor profile created');
      print('📄 License uploaded: $licensePath');
      if (ghanaCardPath != null)
        print('🇬🇭 Ghana card uploaded: $ghanaCardPath');

      // Step 3: AUTOMATIC DOCUMENT VERIFICATION
      print('🔍 Starting automated document verification...');

      if (licensePath != null) {
        final verificationResult =
            await _verificationService.verifyDoctorDocuments(
          doctorId: userId,
          licensePath: licensePath,
          ghanaCardPath: ghanaCardPath,
          doctorName: '$firstName $lastName',
          specialty: specialty,
        );

        print(
            '✅ Verification completed: ${verificationResult['overall_status']}');
        print('📊 Confidence score: ${verificationResult['confidence_score']}');

        // The verification service will automatically:
        // - Auto-approve high-confidence registrations
        // - Auto-reject failed verifications
        // - Notify admins for medium-confidence reviews
      } else {
        print('⚠️ No license uploaded, manual review required');
      }

      print('✅ Doctor registration process completed');
      print(
          '📋 Documents will be automatically verified and you\'ll receive status update');

      return true;
    } catch (e) {
      print('❌ Error registering doctor: $e');
      return false;
    }
  }

  /// Get doctor registration status
  Future<DoctorApprovalStatus?> getDoctorApprovalStatus(String doctorId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('approval_status')
          .eq('id', doctorId)
          .eq('role', 'doctor')
          .single();

      final statusString = data['approval_status'] as String?;
      if (statusString == null) return null;

      return DoctorApprovalStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => DoctorApprovalStatus.pending,
      );
    } catch (e) {
      print('Error getting approval status: $e');
      return null;
    }
  }

  /// Get doctor's license document path
  Future<String?> getDoctorLicensePath(String doctorId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('license_document_path')
          .eq('id', doctorId)
          .eq('role', 'doctor')
          .single();

      return data['license_document_path'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Update doctor profile (after registration)
  Future<bool> updateDoctorProfile({
    required String doctorId,
    String? firstName,
    String? lastName,
    String? phone,
    String? specialty,
    String? experience,
    double? consultationFee,
    String? bio,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (specialty != null) updateData['specialty'] = specialty;
      if (experience != null) updateData['experience'] = experience;
      if (consultationFee != null)
        updateData['consultation_fee'] = consultationFee;
      if (bio != null) updateData['bio'] = bio;

      await _supabase.from('profiles').update(updateData).eq('id', doctorId);

      print('✅ Doctor profile updated');
      return true;
    } catch (e) {
      print('❌ Error updating doctor profile: $e');
      return false;
    }
  }

  /// Get all pending doctor registrations (for admin)
  Future<List<UserModel>> getPendingDoctorRegistrations() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      return (data as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching pending registrations: $e');
      return [];
    }
  }

  /// Get all approved doctors (for patient browsing)
  Future<List<UserModel>> getApprovedDoctors() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false);

      return (data as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching approved doctors: $e');
      return [];
    }
  }

  /// Get all doctors (for admin)
  Future<List<UserModel>> getAllDoctors() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .order('created_at', ascending: false);

      return (data as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching all doctors: $e');
      return [];
    }
  }

  /// Get doctor by ID
  Future<UserModel?> getDoctorById(String doctorId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', doctorId)
          .eq('role', 'doctor')
          .single();

      return UserModel.fromJson(data);
    } catch (e) {
      print('Error fetching doctor: $e');
      return null;
    }
  }
}
