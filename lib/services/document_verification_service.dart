import 'package:doctor_consultation_app/services/local_backend_store.dart';

class DocumentVerificationService {
  static final DocumentVerificationService _instance =
      DocumentVerificationService._internal();

  factory DocumentVerificationService() {
    return _instance;
  }

  DocumentVerificationService._internal();

  final _store = LocalBackendStore.instance;

  Future<Map<String, dynamic>> verifyDoctorDocuments({
    required String doctorId,
    required String licensePath,
    String? ghanaCardPath,
    required String doctorName,
    required String specialty,
  }) async {
    final result = {
      'doctor_id': doctorId,
      'license_verified': licensePath.isNotEmpty,
      'ghana_card_verified': ghanaCardPath == null || ghanaCardPath.isNotEmpty,
      'overall_status': 'manual_review',
      'reasons': <String>['Local UI-only mode requires manual approval.'],
      'confidence_score': 0.65,
      'doctor_name': doctorName,
      'specialty': specialty,
      'verified_at': DateTime.now().toIso8601String(),
    };

    _store.verifications[doctorId] = result;
    return result;
  }

  Future<Map<String, dynamic>?> getVerificationStatus(String doctorId) async {
    return _store.verifications[doctorId];
  }

  Future<List<Map<String, dynamic>>> getPendingReviewDoctors() async {
    return _store.verifications.values
        .where((item) => item['overall_status'] == 'manual_review')
        .toList();
  }

  Future<Map<String, dynamic>> getVerificationReport() async {
    final values = _store.verifications.values.toList();
    final approved =
        values.where((item) => item['overall_status'] == 'approved').length;
    final rejected =
        values.where((item) => item['overall_status'] == 'rejected').length;
    final pending = values
        .where((item) => item['overall_status'] == 'manual_review')
        .length;

    return {
      'total_doctors': values.length,
      'approved': approved,
      'rejected': rejected,
      'pending': pending,
      'automated_approvals': 0,
      'manual_reviews_required': pending,
    };
  }
}

enum VerificationStatus { approved, rejected, pending, manual_review }
