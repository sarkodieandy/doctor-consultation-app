import 'package:doctor_consultation_app/services/ui_mock_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class DocumentVerificationService {
  static final DocumentVerificationService _instance =
      DocumentVerificationService._internal();

  factory DocumentVerificationService() {
    return _instance;
  }

  DocumentVerificationService._internal();

  final _store = UiMockStore.instance;

  supabase.SupabaseClient? get _client {
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> verifyDoctorDocuments({
    required String doctorId,
    required String licensePath,
    String? ghanaCardPath,
    required String doctorName,
    required String specialty,
  }) async {
    final now = DateTime.now().toIso8601String();
    final result = {
      'doctor_id': doctorId,
      'license_verified': licensePath.isNotEmpty,
      'ghana_card_verified': ghanaCardPath == null || ghanaCardPath.isNotEmpty,
      'overall_status': 'manual_review',
      'reasons': <String>['Local UI-only mode requires manual approval.'],
      'confidence_score': 0.65,
      'doctor_name': doctorName,
      'specialty': specialty,
      'verified_at': now,
    };

    final client = _client;
    if (client != null) {
      try {
        final verification = await client
            .from('doctor_verifications')
            .insert({
              'doctor_id': doctorId,
              'status': 'pending',
              'admin_note': 'Awaiting admin review',
              'created_at': now,
              'updated_at': now,
            })
            .select()
            .single();

        final verificationId = verification['id']?.toString();

        await client.from('doctor_documents').insert({
          'doctor_id': doctorId,
          'verification_id': verificationId,
          'document_type': 'medical_license',
          'storage_path': licensePath,
          'file_name': 'medical_license',
          'status': 'uploaded',
          'metadata': {
            'doctor_name': doctorName,
            'specialty': specialty,
          },
          'created_at': now,
          'updated_at': now,
        });

        if (ghanaCardPath != null && ghanaCardPath.isNotEmpty) {
          await client.from('doctor_documents').insert({
            'doctor_id': doctorId,
            'verification_id': verificationId,
            'document_type': 'national_id',
            'storage_path': ghanaCardPath,
            'file_name': 'ghana_card',
            'status': 'uploaded',
            'created_at': now,
            'updated_at': now,
          });
        }

        result['overall_status'] = 'pending';
        result['verification_id'] = verificationId;
      } catch (_) {
        // Keep local fallback below.
      }
    }

    _store.verifications[doctorId] = result;
    return result;
  }

  Future<Map<String, dynamic>?> getVerificationStatus(String doctorId) async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('doctor_verifications')
            .select(
                'id, doctor_id, status, decision_reason, admin_note, reviewed_at, updated_at')
            .eq('doctor_id', doctorId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (data != null) {
          return {
            'doctor_id': doctorId,
            'verification_id': data['id'],
            'overall_status': data['status'] ?? 'pending',
            'decision_reason': data['decision_reason'],
            'admin_note': data['admin_note'],
            'reviewed_at': data['reviewed_at'],
            'updated_at': data['updated_at'],
          };
        }
      } catch (_) {}
    }
    return _store.verifications[doctorId];
  }

  Future<List<Map<String, dynamic>>> getPendingReviewDoctors() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('doctor_verifications')
            .select('id, doctor_id, status, admin_note, created_at')
            .eq('status', 'pending')
            .order('created_at', ascending: false);
        return (data as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (_) {}
    }
    return _store.verifications.values
        .where((item) => item['overall_status'] == 'manual_review')
        .toList();
  }

  Future<Map<String, dynamic>> getVerificationReport() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client.from('doctor_verifications').select('status');
        final rows = (data as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final approved =
            rows.where((item) => item['status'] == 'approved').length;
        final rejected =
            rows.where((item) => item['status'] == 'rejected').length;
        final pending =
            rows.where((item) => item['status'] == 'pending').length;

        return {
          'total_doctors': rows.length,
          'approved': approved,
          'rejected': rejected,
          'pending': pending,
          'automated_approvals': 0,
          'manual_reviews_required': pending,
        };
      } catch (_) {}
    }

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
