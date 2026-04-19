import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaystackCheckoutScreen extends StatefulWidget {
  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late Map<String, dynamic> args;
  late DoctorModel doctor;
  String? selectedMethod;

  final List<_PaymentMethod> methods = const [
    _PaymentMethod(
      id: 'mobile_money',
      label: 'Mobile Money',
      subtitle: 'MTN, Vodafone, AirtelTigo',
      icon: Icons.phone_android_rounded,
      color: Color(0xff00C48C),
    ),
    _PaymentMethod(
      id: 'card',
      label: 'Debit / Credit Card',
      subtitle: 'Visa, Mastercard, Verve',
      icon: Icons.credit_card_rounded,
      color: Color(0xff0052CC),
    ),
    _PaymentMethod(
      id: 'bank_transfer',
      label: 'Bank Transfer',
      subtitle: 'Direct transfer to a virtual account',
      icon: Icons.account_balance_rounded,
      color: Color(0xff6B4EFF),
    ),
    _PaymentMethod(
      id: 'ussd',
      label: 'USSD',
      subtitle: 'Dial a code from any phone',
      icon: Icons.dialpad_rounded,
      color: Color(0xffFF6B35),
    ),
  ];

  @override
  void initState() {
    super.initState();
    args = Get.arguments as Map<String, dynamic>;
    doctor = args['doctor'] as DoctorModel;
    selectedMethod = 'mobile_money';
  }

  void _continue() {
    if (selectedMethod == null) return;
    Get.toNamed('/payment', arguments: {
      ...args,
      'payment_method': selectedMethod,
    });
  }

  @override
  Widget build(BuildContext context) {
    final fee = doctor.consultationFee;

    return Scaffold(
      backgroundColor: const Color(0xff011B33),
      body: Column(
        children: [
          // ── Paystack header ──────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Paystack wordmark
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xff00C48C),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Paystack',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 12, color: Color(0xff00C48C)),
                        const SizedBox(width: 4),
                        const Text(
                          'Secured',
                          style: TextStyle(
                              color: Color(0xff00C48C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Amount + merchant ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  doctor.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'GHS ${fee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doctor.specialty} Consultation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Payment methods sheet ───────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                    child: Text(
                      'Choose a payment method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kTitleTextColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: methods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildMethodTile(methods[i]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: selectedMethod != null ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlueColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Pay GHS ${fee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(_PaymentMethod method) {
    final isSelected = selectedMethod == method.id;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? method.color.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? method.color : const Color(0xffE8E8E8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(method.icon, color: method.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? method.color : kTitleTextColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    method.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: kTitleTextColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? method.color : const Color(0xffD0D0D0),
                  width: 2,
                ),
                color: isSelected ? method.color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethod {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _PaymentMethod({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
