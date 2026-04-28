import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';

class PaymentRepository {
  final UiMockStore _store = UiMockStore.instance;

  Future<Map<String, dynamic>> initializePayment({
    required String appointmentId,
    required double amount,
    required String currency,
    String? paymentMethod,
  }) async {
    // UI-only: Use local/mock data
    return {
      'transaction_id': 'txn_local_${DateTime.now().millisecondsSinceEpoch}'
    };
  }

  Future<bool> verifyPayment(String transactionId) async {
    // UI-only: Always return true
    return true;
  }

  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    // UI-only: Use local/mock data
    final payments =
        _store.payments.where((payment) => payment.userId == userId).toList();
    payments.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return payments;
  }
}
