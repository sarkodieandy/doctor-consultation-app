import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:doctor_consultation_app/services/local_backend_store.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  Function(PaymentModel)? _onSuccess;
  Function(String)? _onFailure;

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();
  final _store = LocalBackendStore.instance;

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
      final payment = PaymentModel(
        id: _store.nextId('payment'),
        appointmentId: appointmentId,
        doctorId: doctorId,
        userId: userId,
        amount: amount,
        status: 'completed',
        paymentMethod: 'local_preview',
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      _store.payments.add(payment);
      _onSuccess?.call(payment);
    } catch (error) {
      _onFailure?.call(error.toString());
    }
  }

  /// Process refund
  Future<bool> refundPayment(String transactionId, double amount) async {
    final index = _store.payments.indexWhere(
      (payment) => payment.transactionId == transactionId,
    );
    if (index == -1) return false;
    _store.payments[index] =
        _store.payments[index].copyWith(status: 'refunded');
    return true;
  }

  /// Get payment history
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    final payments =
        _store.payments.where((payment) => payment.userId == userId).toList();
    payments.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return payments;
  }

  void dispose() {
    _onSuccess = null;
    _onFailure = null;
  }
}
