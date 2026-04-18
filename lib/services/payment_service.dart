import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  Function(PaymentModel)? _onSuccess;
  Function(String)? _onFailure;

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  final _supabase = Supabase.instance.client;

  /// Initialize payment callbacks (UI-only, Paystack integration later)
  void initializePayment({
    required Function(PaymentModel) onSuccess,
    required Function(String) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
  }

  /// Process payment (UI-only for now, stores in Supabase)
  Future<void> processPayment({
    required String appointmentId,
    required String doctorId,
    required String userId,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    try {
      final paymentJson = {
        'appointment_id': appointmentId,
        'doctor_id': doctorId,
        'user_id': userId,
        'amount': amount,
        'status': 'completed',
        'payment_method': 'paystack',
        'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      };

      final data = await _supabase
          .from('payments')
          .insert(paymentJson)
          .select()
          .single();

      final payment = PaymentModel.fromJson(data);
      _onSuccess?.call(payment);
    } catch (e) {
      _onFailure?.call(e.toString());
    }
  }

  /// Process refund
  Future<bool> refundPayment(String transactionId, double amount) async {
    try {
      await _supabase
          .from('payments')
          .update({'status': 'refunded'}).eq('transaction_id', transactionId);

      return true;
    } catch (e) {
      print('Refund error: $e');
      return false;
    }
  }

  /// Get payment history
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    try {
      final data = await _supabase
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => PaymentModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  void dispose() {
    _onSuccess = null;
    _onFailure = null;
  }
}
