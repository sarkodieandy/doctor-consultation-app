class PaymentModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String userId;
  final double amount;
  final String status; // pending, completed, failed, refunded
  final String paymentMethod; // paystack, mobile_money, credit_card
  final String transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? receiptId;
  final String? failureReason;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.createdAt,
    this.completedAt,
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
    String? status,
    String? paymentMethod,
    String? transactionId,
    DateTime? createdAt,
    DateTime? completedAt,
    String? receiptId,
    String? failureReason,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
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
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
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
      status: json['status'] ?? 'pending',
      paymentMethod:
          json['payment_method'] ?? json['paymentMethod'] ?? 'paystack',
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      completedAt: (json['completed_at'] ?? json['completedAt']) != null
          ? DateTime.parse(json['completed_at'] ?? json['completedAt'])
          : null,
      receiptId: json['receipt_id'] ?? json['receiptId'],
      failureReason: json['failure_reason'] ?? json['failureReason'],
    );
  }
}
