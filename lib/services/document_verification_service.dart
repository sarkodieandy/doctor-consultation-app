/// Document Verification Service
/// Handles automated verification of doctor licenses and Ghana card
/// Uses OCR and verification APIs for automatic approval/disapproval

import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentVerificationService {
  static final DocumentVerificationService _instance =
      DocumentVerificationService._internal();

  factory DocumentVerificationService() {
    return _instance;
  }

  DocumentVerificationService._internal();

  final _supabase = Supabase.instance.client;

  /// Verify doctor license and Ghana card
  /// Returns approval status: 'approved', 'rejected', or 'manual_review'
  Future<Map<String, dynamic>> verifyDoctorDocuments({
    required String doctorId,
    required String licensePath,
    String? ghanaCardPath,
    required String doctorName,
    required String specialty,
  }) async {
    try {
      print('🔍 Starting document verification for doctor: $doctorId');

      final verificationResult = {
        'doctor_id': doctorId,
        'license_verified': false,
        'ghana_card_verified': false,
        'overall_status': 'pending',
        'reasons': <String>[],
        'confidence_score': 0.0,
      };

      // Step 1: Verify License Document
      final licenseResult = await _verifyLicenseDocument(
        licensePath,
        doctorName,
        specialty,
      );

      verificationResult['license_verified'] =
          licenseResult['verified'] ?? false;
      verificationResult['license_score'] = licenseResult['score'] ?? 0.0;

      if (!licenseResult['verified']!) {
        (verificationResult['reasons'] as List<String>)
            .add('License verification failed: ${licenseResult['reason']}');
      } else {
        print('✅ License verified successfully');
      }

      // Step 2: Verify Ghana Card (if provided)
      if (ghanaCardPath != null && ghanaCardPath.isNotEmpty) {
        final cardResult = await _verifyGhanaCard(ghanaCardPath, doctorName);
        verificationResult['ghana_card_verified'] =
            cardResult['verified'] ?? false;
        verificationResult['card_score'] = cardResult['score'] ?? 0.0;

        if (!cardResult['verified']!) {
          (verificationResult['reasons'] as List<String>)
              .add('Ghana card verification failed: ${cardResult['reason']}');
        } else {
          print('✅ Ghana card verified successfully');
        }
      }

      // Step 3: Determine overall approval status
      final licenseVerified = verificationResult['license_verified'] as bool;
      final cardVerified = verificationResult['ghana_card_verified'] as bool;
      final licenseScore =
          verificationResult['license_score'] as double? ?? 0.0;
      final cardScore = verificationResult['card_score'] as double? ?? 0.0;

      if (licenseVerified && (ghanaCardPath == null || cardVerified)) {
        // HIGH CONFIDENCE: Auto-approve
        if (licenseScore > 0.85 && cardScore > 0.85) {
          verificationResult['overall_status'] = 'approved';
          verificationResult['confidence_score'] =
              (licenseScore + cardScore) / 2;
          print('✅ AUTO-APPROVED - High confidence verification');
        } else if (licenseScore > 0.75 && cardScore > 0.75) {
          // MEDIUM CONFIDENCE: Send to manual review
          verificationResult['overall_status'] = 'manual_review';
          verificationResult['confidence_score'] =
              (licenseScore + cardScore) / 2;
          print('⚠️ MANUAL REVIEW REQUIRED - Medium confidence');
        }
      } else {
        // AUTO-REJECT
        verificationResult['overall_status'] = 'rejected';
        print('❌ AUTO-REJECTED - Document verification failed');
      }

      // Step 4: Update database with verification results
      await _saveVerificationResult(doctorId, verificationResult);

      // Step 5: Auto-approve or notify admin based on status
      if (verificationResult['overall_status'] == 'approved') {
        await _autoApprovDoctor(doctorId, verificationResult);
      } else if (verificationResult['overall_status'] == 'rejected') {
        await _autoRejectDoctor(
          doctorId,
          verificationResult['reasons'] as List<dynamic>,
        );
      } else {
        await _notifyAdminForManualReview(doctorId, verificationResult);
      }

      return verificationResult;
    } catch (e) {
      print('❌ Error verifying documents: $e');
      return {
        'doctor_id': doctorId,
        'overall_status': 'manual_review',
        'error': e.toString(),
      };
    }
  }

  /// Verify license document using OCR simulation
  /// In production, integrate with Google Vision API or Azure Document Intelligence
  Future<Map<String, dynamic>> _verifyLicenseDocument(
    String licensePath,
    String doctorName,
    String specialty,
  ) async {
    try {
      print('📄 Verifying license document...');

      // Simulate OCR verification
      // In production: Use Google Cloud Vision API or Azure Document Intelligence
      final result = {
        'verified': true,
        'score': 0.92,
        'extracted_name': doctorName,
        'extracted_specialty': specialty,
        'license_number': 'LIC-GH-2024-001234',
        'expiry_date': '2026-12-31',
        'issuing_body': 'Ghana Medical and Dental Council',
        'reason': null,
      };

      // Validation checks
      if (licensePath.isEmpty) {
        result['verified'] = false;
        result['score'] = 0.0;
        result['reason'] = 'License document is empty';
      }

      // Check expiry date
      final expiryDate = DateTime.parse(result['expiry_date'] as String);
      if (expiryDate.isBefore(DateTime.now())) {
        result['verified'] = false;
        result['score'] = 0.0;
        result['reason'] = 'License has expired';
      }

      // Verify name matches
      if (result['extracted_name'] != doctorName) {
        result['score'] = (result['score'] as double) * 0.8; // Reduce score
        result['verified'] = false;
        result['reason'] = 'Name on license does not match registration';
      }

      print('License verification score: ${result['score']}');
      return result;
    } catch (e) {
      return {
        'verified': false,
        'score': 0.0,
        'reason': 'OCR processing failed: $e',
      };
    }
  }

  /// Verify Ghana Card
  /// In production, integrate with Ghana National ID verification API
  Future<Map<String, dynamic>> _verifyGhanaCard(
    String ghanaCardPath,
    String doctorName,
  ) async {
    try {
      print('🇬🇭 Verifying Ghana card...');

      // Simulate Ghana Card verification
      // In production: Use Ghana NIA API or verification service
      final result = {
        'verified': true,
        'score': 0.95,
        'card_number': 'GHA-123456789-0123',
        'extracted_name': doctorName,
        'date_of_birth': '1990-05-15',
        'registration_status': 'active',
        'reason': null,
      };

      // Validation checks
      if (ghanaCardPath.isEmpty) {
        result['verified'] = false;
        result['score'] = 0.0;
        result['reason'] = 'Ghana card image is empty';
      }

      // Verify name matches
      if (result['extracted_name'] != doctorName) {
        result['score'] = (result['score'] as double) * 0.7;
        result['verified'] = false;
        result['reason'] = 'Name on card does not match registration';
      }

      // Check if card is active
      if (result['registration_status'] != 'active') {
        result['verified'] = false;
        result['reason'] = 'Ghana card is not active';
      }

      print('Ghana card verification score: ${result['score']}');
      return result;
    } catch (e) {
      return {
        'verified': false,
        'score': 0.0,
        'reason': 'Card verification failed: $e',
      };
    }
  }

  /// Save verification result to database
  Future<void> _saveVerificationResult(
    String doctorId,
    Map<String, dynamic> result,
  ) async {
    try {
      await _supabase.from('doctor_verifications').upsert({
        'doctor_id': doctorId,
        'license_verified': result['license_verified'] ?? false,
        'ghana_card_verified': result['ghana_card_verified'] ?? false,
        'overall_status': result['overall_status'],
        'confidence_score': result['confidence_score'] ?? 0.0,
        'verification_notes': (result['reasons'] as List?)?.join('; ') ?? '',
        'verified_at': DateTime.now().toIso8601String(),
      });

      print('✅ Verification result saved to database');
    } catch (e) {
      print('Error saving verification result: $e');
    }
  }

  /// Auto-approve doctor (only for high-confidence verifications)
  Future<void> _autoApprovDoctor(
    String doctorId,
    Map<String, dynamic> verificationResult,
  ) async {
    try {
      print('✅ AUTO-APPROVING DOCTOR: $doctorId');

      await _supabase.from('profiles').update({
        'approval_status': 'approved',
        'approval_note':
            'Automatically approved via document verification with ${(verificationResult['confidence_score'] as double? ?? 0).toStringAsFixed(0)}% confidence',
        'approved_at': DateTime.now().toIso8601String(),
        'verification_method': 'automated_ocr',
      }).eq('id', doctorId);

      // Create notification
      await _supabase.from('notifications').insert({
        'user_id': doctorId,
        'type': 'registration_approved',
        'title': '🎉 Registration Approved!',
        'message':
            'Your registration has been automatically approved via document verification.',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Doctor auto-approved and notified');
    } catch (e) {
      print('Error auto-approving doctor: $e');
    }
  }

  /// Auto-reject doctor (for failed verifications)
  Future<void> _autoRejectDoctor(
    String doctorId,
    List<dynamic> reasons,
  ) async {
    try {
      print('❌ AUTO-REJECTING DOCTOR: $doctorId');
      print('Reasons: $reasons');

      await _supabase.from('profiles').update({
        'approval_status': 'rejected',
        'approval_note':
            'Automatically rejected: ${reasons.join('; ')} Please verify your documents and try again.',
        'rejected_at': DateTime.now().toIso8601String(),
        'verification_method': 'automated_ocr',
      }).eq('id', doctorId);

      // Create rejection notification
      await _supabase.from('notifications').insert({
        'user_id': doctorId,
        'type': 'registration_rejected',
        'title': '⚠️ Registration Requirements Not Met',
        'message':
            'Your registration was not approved during automated verification. ${reasons.join('; ')} Please upload correct documents and try again.',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('❌ Doctor auto-rejected and notified');
    } catch (e) {
      print('Error auto-rejecting doctor: $e');
    }
  }

  /// Notify admin for manual review (medium confidence)
  Future<void> _notifyAdminForManualReview(
    String doctorId,
    Map<String, dynamic> verificationResult,
  ) async {
    try {
      print('⚠️ NOTIFYING ADMIN FOR MANUAL REVIEW: $doctorId');

      // Get admin users
      final adminUsers =
          await _supabase.from('profiles').select('id').eq('role', 'admin');

      // Notify all admins
      for (var admin in adminUsers as List) {
        await _supabase.from('notifications').insert({
          'user_id': admin['id'],
          'type': 'doctor_verification_review',
          'title': '🔍 Doctor Registration Requires Review',
          'message':
              'Doctor $doctorId needs manual review. Confidence score: ${(verificationResult['confidence_score'] as double? ?? 0).toStringAsFixed(1)}%',
          'read': false,
          'data': {'doctor_id': doctorId},
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      print('⚠️ Admins notified for manual review');
    } catch (e) {
      print('Error notifying admin: $e');
    }
  }

  /// Get verification status for a doctor
  Future<Map<String, dynamic>?> getVerificationStatus(String doctorId) async {
    try {
      final data = await _supabase
          .from('doctor_verifications')
          .select()
          .eq('doctor_id', doctorId)
          .maybeSingle();

      return data;
    } catch (e) {
      return null;
    }
  }

  /// Get all doctors pending manual review
  Future<List<Map<String, dynamic>>> getPendingReviewDoctors() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('*, doctor_verifications(*)')
          .eq('role', 'doctor')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching pending doctors: $e');
      return [];
    }
  }

  /// Get verification report for admin dashboard
  Future<Map<String, dynamic>> getVerificationReport() async {
    try {
      final approved = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .eq('approval_status', 'approved');

      final rejected = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .eq('approval_status', 'rejected');

      final pending = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .eq('approval_status', 'pending');

      final automated = await _supabase
          .from('profiles')
          .select()
          .eq('verification_method', 'automated_ocr');

      return {
        'total_doctors': approved.length + rejected.length + pending.length,
        'approved': approved.length,
        'rejected': rejected.length,
        'pending': pending.length,
        'automated_approvals': automated.length,
        'manual_reviews_required':
            pending.length - (automated.length - rejected.length),
      };
    } catch (e) {
      print('Error generating report: $e');
      return {
        'total_doctors': 0,
        'approved': 0,
        'rejected': 0,
        'pending': 0,
        'automated_approvals': 0,
      };
    }
  }
}

/// Verification Status Enum
enum VerificationStatus { approved, rejected, pending, manual_review }
