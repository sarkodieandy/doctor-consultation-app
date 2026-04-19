import 'package:doctor_consultation_app/services/local_backend_store.dart';

class PaystackService {
  static const String paystackBaseUrl = 'local://paystack';
  static const String paystackPublicKey = 'local-public-key';
  static const String paystackSecretKey = 'local-secret-key';

  PaystackService({Object? supabase});

  final _store = LocalBackendStore.instance;

  Future<String?> initializePayment({
    required String email,
    required double amount,
    required String consultationId,
    required String doctorId,
    required String patientId,
  }) async {
    return 'local-payment://$consultationId';
  }

  Future<Map<String, dynamic>?> verifyPayment(String reference) async {
    return {
      'reference': reference,
      'status': 'success',
      'amount': 0,
    };
  }

  Future<double> getCommissionAmount(
      String doctorId, double consultationAmount) async {
    return consultationAmount * 0.15;
  }

  Future<bool> createDoctorPayout({
    required String doctorId,
    required String paymentId,
    required double payoutAmount,
    required double commissionAmount,
  }) async {
    return true;
  }

  Future<String?> createTransferRecipient({
    required String doctorId,
    required String mobileNumber,
    required String provider,
  }) async {
    final recipientCode =
        'local_recipient_${doctorId}_${provider.toLowerCase()}';
    _store.payoutProfiles[doctorId] = {
      'mobile_money_number': mobileNumber,
      'mobile_money_provider': provider,
      'paystack_recipient_code': recipientCode,
    };
    return recipientCode;
  }
}
