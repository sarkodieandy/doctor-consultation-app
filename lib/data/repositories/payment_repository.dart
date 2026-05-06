import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final _supabase = Supabase.instance.client;

  /// Calls the `initialize-payment` Edge Function.
  /// Returns `{ reference, authorization_url, access_code, payment_id }`.
  Future<Map<String, dynamic>> initializePayment({
    required String appointmentId,
    required double amount,
    required String currency,
    String? paymentMethod,
    String? doctorId,
  }) async {
    final response = await _supabase.functions.invoke(
      'initialize-payment',
      body: {
        'appointmentId': appointmentId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod ?? 'mobile_money',
        'doctorId': doctorId ?? '',
      },
    );

    if (response.status != 200) {
      final msg = (response.data as Map?)?['error']?.toString() ??
          'Payment initialization failed (${response.status})';
      throw msg;
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Calls the `verify-payment` Edge Function.
  /// Returns `true` only when Paystack confirms the transaction as `success`.
  Future<bool> verifyPayment(String reference) async {
    final response = await _supabase.functions.invoke(
      'verify-payment',
      body: {'reference': reference},
    );

    if (response.status != 200) return false;
    return (response.data as Map?)?['verified'] == true;
  }

  /// Reads the authenticated user's own payment history from Supabase.
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
