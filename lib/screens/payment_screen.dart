import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/data/repositories/payment_repository.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _authService = AuthService();
  final _paymentRepository = PaymentRepository();
  final _notificationService = NotificationService();

  late DoctorModel doctor;
  late DateTime appointmentDate;
  late String appointmentTime;
  late String appointmentId;
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
    appointmentId = args['appointment_id']?.toString() ??
        args['consultation_id']?.toString() ??
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
    commissionAmount = doctor.consultationFee * 0.15;
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
    try {
      final initialization = await _paymentRepository.initializePayment(
        appointmentId: appointmentId,
        amount: doctor.consultationFee,
        currency: 'GHS',
        paymentMethod: paymentMethod,
      );
      final reference = initialization['reference']?.toString() ??
          initialization['transaction_id']?.toString();

      if (reference == null || reference.isEmpty) {
        throw 'Payment initialization failed';
      }

      final verified = await _paymentRepository.verifyPayment(reference);
      if (!verified) {
        throw 'Payment verification failed';
      }

      await _notificationService.sendPaymentSuccess(
        paymentId: appointmentId,
        amount: doctor.consultationFee,
        appointmentId: appointmentId,
        userId: user.id,
      );

      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment completed successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Get.back(result: true);
        }
      });
    } catch (message) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultationFee = doctor.consultationFee;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: kBlueColor),
            )
          : Column(
              children: [
                // ── Blue header ──────────────────────────────
                _buildHeader(consultationFee),

                // ── Scrollable body ──────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      children: [
                        _buildConsultationCard()
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 350.ms)
                            .slideY(begin: 0.12, end: 0),
                        const SizedBox(height: 16),
                        if (selectedSymptoms.isNotEmpty ||
                            symptomDescription.isNotEmpty ||
                            careNotes.isNotEmpty)
                          _buildIntakeCard()
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 350.ms)
                              .slideY(begin: 0.12, end: 0),
                        if (selectedSymptoms.isNotEmpty ||
                            symptomDescription.isNotEmpty ||
                            careNotes.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildBreakdownCard(consultationFee)
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 350.ms)
                            .slideY(begin: 0.12, end: 0),
                        const SizedBox(height: 28),
                        _buildConfirmButton(consultationFee)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 350.ms)
                            .slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(double fee) {
    return Container(
      decoration: BoxDecoration(
        color: kBlueColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
          child: Column(
            children: [
              // Back button row
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  const Text(
                    'Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              // Doctor avatar + name
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 12),
              Text(
                doctor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialty,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              // Amount pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  'GHS ${fee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.06, end: 0);
  }

  Widget _buildConsultationCard() {
    return _Card(
      title: 'Consultation Details',
      icon: Icons.event_note_rounded,
      children: [
        _InfoTile(
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: DateFormat('EEE, MMM d yyyy').format(appointmentDate),
        ),
        _InfoTile(
          icon: Icons.access_time_rounded,
          label: 'Time',
          value: appointmentTime,
        ),
        _InfoTile(
          icon: Icons.videocam_rounded,
          label: 'Mode',
          value: consultationMode,
        ),
        _InfoTile(
          icon: Icons.language_rounded,
          label: 'Language',
          value: preferredLanguage,
        ),
        _InfoTile(
          icon: Icons.medical_information_rounded,
          label: 'Reason',
          value: visitReason,
        ),
        _InfoTile(
          icon: _paymentMethodIcon(paymentMethod),
          label: 'Payment via',
          value: _paymentMethodLabel(paymentMethod),
        ),
      ],
    );
  }

  Widget _buildIntakeCard() {
    return _Card(
      title: 'Care Intake',
      icon: Icons.health_and_safety_rounded,
      children: [
        if (selectedSymptoms.isNotEmpty)
          _InfoTile(
            icon: Icons.sick_rounded,
            label: 'Symptoms',
            value: selectedSymptoms.join(', '),
          ),
        if (symptomDescription.isNotEmpty)
          _InfoTile(
            icon: Icons.description_rounded,
            label: 'Description',
            value: symptomDescription,
          ),
        if (careNotes.isNotEmpty)
          _InfoTile(
            icon: Icons.note_rounded,
            label: 'Notes',
            value: careNotes,
          ),
      ],
    );
  }

  Widget _buildBreakdownCard(double fee) {
    return _Card(
      title: 'Payment Breakdown',
      icon: Icons.receipt_long_rounded,
      children: [
        _BreakdownRow(
          label: 'Consultation Fee',
          value: 'GHS ${fee.toStringAsFixed(2)}',
          valueColor: kTitleTextColor,
        ),
        _BreakdownRow(
          label: 'Platform Fee',
          value: '- GHS ${commissionAmount.toStringAsFixed(2)}',
          valueColor: Colors.redAccent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: kTitleTextColor.withOpacity(0.08), height: 1),
        ),
        _BreakdownRow(
          label: 'Doctor Receives',
          value: 'GHS ${doctorEarnings.toStringAsFixed(2)}',
          valueColor: Colors.green,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildConfirmButton(double fee) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _completePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlueColor,
          disabledBackgroundColor: kBlueColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isProcessing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay GHS ${fee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _paymentMethodIcon(String id) {
    switch (id) {
      case 'mobile_money':
        return Icons.phone_android_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank_transfer':
        return Icons.account_balance_rounded;
      case 'ussd':
        return Icons.dialpad_rounded;
      default:
        return Icons.payment_rounded;
    }
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
}

// ── Reusable card wrapper ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kBlueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kBlueColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: kTitleTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

// ── Info tile row ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: kBlueColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: kTitleTextColor.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTitleTextColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown row ─────────────────────────────────────────────────────────────
class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? kTitleTextColor : kTitleTextColor.withOpacity(0.65),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
