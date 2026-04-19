import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:doctor_consultation_app/services/payment_service.dart';
import 'package:doctor_consultation_app/services/paystack_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _authService = AuthService();
  final _paymentService = PaymentService();
  final _notificationService = NotificationService();
  final _paystackService = PaystackService();

  late DoctorModel doctor;
  late DateTime appointmentDate;
  late String appointmentTime;
  late String consultationId;
  late String consultationMode;
  late String preferredLanguage;
  late String visitReason;
  late String symptomDescription;
  late String careNotes;
  late List<dynamic> selectedSymptoms;

  double commissionAmount = 0;
  double doctorEarnings = 0;
  bool isLoading = true;
  bool isProcessing = false;
  String paymentMethod = 'mobile_money';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    doctor = args['doctor'];
    appointmentDate = args['date'];
    appointmentTime = args['time'];
    consultationId = args['consultation_id'] ??
        DateTime.now().millisecondsSinceEpoch.toString();
    consultationMode = args['mode'] ?? 'Video';
    preferredLanguage = args['language'] ?? 'English';
    visitReason = args['reason'] ?? 'General review';
    symptomDescription = args['description'] ?? '';
    careNotes = args['notes'] ?? '';
    selectedSymptoms = (args['symptoms'] as List<dynamic>? ?? []);
    paymentMethod = args['payment_method'] ?? 'mobile_money';
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    commissionAmount = await _paystackService.getCommissionAmount(
      doctor.id,
      doctor.consultationFee,
    );
    doctorEarnings = doctor.consultationFee - commissionAmount;
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _completePayment() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to continue.')),
      );
      return;
    }

    setState(() => isProcessing = true);

    _paymentService.initializePayment(
      onSuccess: (_) async {
        await _paystackService.createDoctorPayout(
          doctorId: doctor.id,
          paymentId: consultationId,
          payoutAmount: doctorEarnings,
          commissionAmount: commissionAmount,
        );
        await _notificationService.sendPaymentSuccess(
          paymentId: consultationId,
          amount: doctor.consultationFee,
          appointmentId: consultationId,
          userId: user.id,
        );
        if (!mounted) return;
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed in local preview mode.'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Get.back(result: true);
          }
        });
      },
      onFailure: (message) {
        if (!mounted) return;
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );

    await _paymentService.processPayment(
      appointmentId: consultationId,
      doctorId: doctor.id,
      userId: user.id,
      amount: doctor.consultationFee,
      userEmail: user.email,
      userName: user.fullName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultationFee = doctor.consultationFee;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Payment Preview'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Backend payment processing has been removed. This screen now previews the UI-only payment state.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consultation Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              child: Icon(Icons.person),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    doctor.specialty,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Date',
                          DateFormat('MMM d, yyyy').format(appointmentDate),
                        ),
                        _buildDetailRow('Time', appointmentTime),
                        _buildDetailRow('Mode', consultationMode),
                        _buildDetailRow('Language', preferredLanguage),
                        _buildDetailRow('Reason', visitReason),
                        _buildDetailRow(
                            'Payment via', _paymentMethodLabel(paymentMethod)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Care Intake Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedSymptoms.isNotEmpty)
                          _buildDetailRow(
                            'Symptoms',
                            selectedSymptoms.join(', '),
                          ),
                        if (symptomDescription.isNotEmpty)
                          _buildDetailRow('Description', symptomDescription),
                        if (careNotes.isNotEmpty)
                          _buildDetailRow('Notes', careNotes),
                        if (selectedSymptoms.isEmpty &&
                            symptomDescription.isEmpty &&
                            careNotes.isEmpty)
                          const Text(
                            'No additional patient notes were added for this local preview.',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentRow(
                          'Consultation Fee',
                          'GHS ${consultationFee.toStringAsFixed(2)}',
                          Colors.black,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentRow(
                          'Platform Commission',
                          'GHS ${commissionAmount.toStringAsFixed(2)}',
                          Colors.red,
                        ),
                        const Divider(height: 16),
                        _buildPaymentRow(
                          'Doctor Receives',
                          'GHS ${doctorEarnings.toStringAsFixed(2)}',
                          Colors.green,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _completePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Mark Payment Complete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _paymentMethodLabel(String id) {
    switch (id) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'card':
        return 'Debit / Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ussd':
        return 'USSD';
      default:
        return id;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
