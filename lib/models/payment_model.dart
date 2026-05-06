class PaymentModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String userId;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, refunded
  final String paymentMethod; // mobile_money, card, bank_transfer, ussd
  final String transactionId;
  final String? gatewayReference; // Paystack reference
  final double platformFee;
  final double doctorAmount;
  final String payoutStatus; // not_ready, pending, processed, failed
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? receiptId;
  final String? failureReason;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.userId,
    required this.amount,
    this.currency = 'GHS',
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    this.gatewayReference,
    this.platformFee = 0,
    this.doctorAmount = 0,
    this.payoutStatus = 'not_ready',
    required this.createdAt,
    this.completedAt,
    this.refundedAt,
    this.receiptId,
    this.failureReason,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';

  PaymentModel copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? userId,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? transactionId,
    String? gatewayReference,
    double? platformFee,
    double? doctorAmount,
    String? payoutStatus,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? receiptId,
    String? failureReason,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      platformFee: platformFee ?? this.platformFee,
      doctorAmount: doctorAmount ?? this.doctorAmount,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      receiptId: receiptId ?? this.receiptId,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'gateway_reference': gatewayReference,
      'platform_fee': platformFee,
      'doctor_amount': doctorAmount,
      'payout_status': payoutStatus,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'refunded_at': refundedAt?.toIso8601String(),
      'receipt_id': receiptId,
      'failure_reason': failureReason,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] ?? '').toString(),
      appointmentId:
          (json['appointment_id'] ?? json['appointmentId'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: (json['currency'] ?? 'GHS').toString(),
      status: _normalizeStatus(
          json['status'] ?? json['payment_status'] ?? 'pending'),
      paymentMethod:
          (json['payment_method'] ?? json['paymentMethod'] ?? 'mobile_money')
              .toString(),
      transactionId: (json['transaction_id'] ??
              json['transactionId'] ??
              json['gateway_reference'] ??
              '')
          .toString(),
      gatewayReference: json['gateway_reference']?.toString(),
      platformFee: (json['platform_fee'] ?? 0).toDouble(),
      doctorAmount: (json['doctor_amount'] ?? 0).toDouble(),
      payoutStatus: (json['payout_status'] ?? 'not_ready').toString(),
      createdAt: DateTime.parse(json['created_at'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      completedAt: (json['completed_at'] ?? json['completedAt']) != null
          ? DateTime.parse(json['completed_at'] ?? json['completedAt'])
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'])
          : null,
      receiptId: (json['receipt_id'] ?? json['receiptId'])?.toString(),
      failureReason:
          (json['failure_reason'] ?? json['failureReason'])?.toString(),
    );
  }

  static String _normalizeStatus(dynamic status) {
    final value = status?.toString().toLowerCase() ?? 'pending';
    return switch (value) {
      'paid' => 'completed',
      'refunded' => 'refunded',
      'failed' => 'failed',
      'pending' => 'pending',
      _ => value,
    };
  }
}
