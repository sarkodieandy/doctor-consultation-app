import 'package:doctor_consultation_app/models/payment_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  late Razorpay _razorpay;

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal() {
    _razorpay = Razorpay();
  }

  /// Initialize Razorpay payment gateway
  void initializePayment({
    required Function(PaymentModel) onSuccess,
    required Function(String) onFailure,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
      onSuccess(_createPaymentModel(response.paymentId ?? '', 'completed'));
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
      onFailure(response.message ?? 'Payment failed');
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse response) {
      onFailure('External wallet: ${response.walletName}');
    });
  }

  /// Process payment
  void processPayment({
    required String appointmentId,
    required String doctorId,
    required String userId,
    required double amount,
    required String userEmail,
    required String userName,
  }) {
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Test key - replace with production
      'amount': (amount * 100).toInt(), // Amount in paise
      'currency': 'INR',
      'name': 'Doctor Consultation',
      'description': 'Appointment with Doctor - $appointmentId',
      'prefill': {
        'contact': '9999999999',
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#EF716B', // Orange color from design system
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
    }
  }

  /// Create payment model from transaction
  PaymentModel _createPaymentModel(String transactionId, String status) {
    return PaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      appointmentId: '',
      doctorId: '',
      userId: '',
      amount: 0.0,
      status: status,
      paymentMethod: 'razorpay',
      transactionId: transactionId,
      createdAt: DateTime.now(),
      completedAt: status == 'completed' ? DateTime.now() : null,
    );
  }

  /// Process refund
  Future<bool> refundPayment(String transactionId, double amount) async {
    try {
      // This would connect to your backend to process refund
      await Future.delayed(Duration(seconds: 2));
      return true;
    } catch (e) {
      print('Refund error: $e');
      return false;
    }
  }

  /// Get payment history
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    try {
      // Mock payment history
      await Future.delayed(Duration(milliseconds: 500));
      return [
        PaymentModel(
          id: '1',
          appointmentId: 'apt_1',
          doctorId: 'doc_1',
          userId: userId,
          amount: 500.0,
          status: 'completed',
          paymentMethod: 'razorpay',
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
    _razorpay.clear();
  }
}
