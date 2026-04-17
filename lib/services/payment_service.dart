import 'package:doctor_consultation_app/models/payment_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  Function(PaymentModel)? _onSuccess;
  Function(String)? _onFailure;

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  /// Initialize payment callbacks (UI-only, Paystack integration later)
  void initializePayment({
    required Function(PaymentModel) onSuccess,
    required Function(String) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
  }

  /// Simulate payment processing (UI-only for now)
  /// Will be replaced with Paystack integration
  Future<void> processPayment({
    required String appointmentId,
    required String doctorId,
    required String userId,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(Duration(seconds: 2));

      // Simulate success for UI demo
      final payment = PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appointmentId: appointmentId,
        doctorId: doctorId,
        userId: userId,
        amount: amount,
        status: 'completed',
        paymentMethod: 'paystack',
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      _onSuccess?.call(payment);
    } catch (e) {
      _onFailure?.call(e.toString());
    }
  }

  /// Process refund (simulated)
  Future<bool> refundPayment(String transactionId, double amount) async {
    try {
      await Future.delayed(Duration(seconds: 2));
      return true;
    } catch (e) {
      print('Refund error: $e');
      return false;
    }
  }

  /// Get payment history (mock data)
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      return [
        PaymentModel(
          id: '1',
          appointmentId: 'apt_1',
          doctorId: 'doc_1',
          userId: userId,
          amount: 500.0,
          status: 'completed',
          paymentMethod: 'paystack',
          transactionId: 'txn_123',
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          completedAt: DateTime.now().subtract(Duration(days: 5)),
          receiptId: 'rcpt_123',
        ),
      ];
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
