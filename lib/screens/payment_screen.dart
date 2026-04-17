import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:doctor_consultation_app/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late DoctorModel doctor;
  late DateTime appointmentDate;
  late String appointmentTime;

  final paymentService = PaymentService();
  final notificationService = NotificationService();
  final controller = Get.find<AppointmentController>();
  final authService = AuthService();

  bool isProcessing = false;
  String? _pendingAppointmentId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    doctor = args['doctor'];
    appointmentDate = args['date'];
    appointmentTime = args['time'];

    paymentService.initializePayment(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kTitleTextColor),
          onPressed: () {
            if (!isProcessing) Get.back();
          },
        ),
        title: Text(
          'Payment',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kOrangeColor),
                  SizedBox(height: 20),
                  Text(
                    'Processing Payment...',
                    style: TextStyle(
                      fontSize: 16,
                      color: kTitleTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: kTitleTextColor,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Doctor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                doctor.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Specialty',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                doctor.specialty,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${DateFormat('MMM dd').format(appointmentDate)}, $appointmentTime',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Consultation Fee',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${doctor.consultationFee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Taxes & Charges',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹50',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: kTitleTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${(doctor.consultationFee + 50).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: kOrangeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25),

                    // Payment Methods
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kTitleTextColor,
                      ),
                    ),
                    SizedBox(height: 15),

                    // Razorpay Payment Option
                    _paymentMethodCard(
                      title: 'Pay with Razorpay',
                      subtitle: 'Credit Card, Debit Card, UPI, Wallet',
                      icon: Icons.payment,
                      onTap: _processRazorpayPayment,
                    ),
                    SizedBox(height: 15),

                    // Wallet Payment Option
                    _paymentMethodCard(
                      title: 'Wallet Balance',
                      subtitle: '₹500 available',
                      icon: Icons.account_balance_wallet,
                      onTap: () => _showMessage('Wallet payment coming soon'),
                    ),
                    SizedBox(height: 25),

                    // Terms & Conditions
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kSearchBackgroundColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: kBlueColor),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'I agree to the terms & conditions and privacy policy',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _paymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kSearchBackgroundColor),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kBlueColor),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kTitleTextColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  void _processRazorpayPayment() {
    final user = authService.currentUser;
    if (user == null) {
      _showMessage('Please log in again before making a payment.');
      return;
    }

    _pendingAppointmentId = 'apt_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => isProcessing = true);

    paymentService.processPayment(
      appointmentId: _pendingAppointmentId!,
      doctorId: doctor.id,
      userId: user.id,
      amount: doctor.consultationFee + 50,
      userEmail: user.email,
      userName: user.fullName.trim(),
    );
  }

  Future<void> _handlePaymentSuccess(dynamic payment) async {
    setState(() => isProcessing = false);

    final appointmentBooked = await controller.bookAppointment(
      doctor.id,
      appointmentDate,
      appointmentTime,
    );

    if (!mounted) {
      return;
    }

    if (!appointmentBooked) {
      _showMessage(
        controller.errorMessage.value ??
            'Payment was completed, but the appointment could not be created.',
      );
      return;
    }

    await notificationService.sendPaymentSuccess(
      paymentId: payment.transactionId ?? 'payment_${DateTime.now().millisecondsSinceEpoch}',
      amount: doctor.consultationFee + 50,
      appointmentId: _pendingAppointmentId ?? '',
    );

    _showSuccessDialog();
  }

  void _handlePaymentFailure(String error) {
    setState(() => isProcessing = false);

    notificationService.sendPaymentFailed(
      paymentId: '',
      reason: error,
    );

    _showMessage('Payment Failed: $error');
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your appointment with ${doctor.name} is confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: MaterialButton(
                  onPressed: () {
                    Get.offAllNamed('/home');
                  },
                  color: kOrangeColor,
                  height: 50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Go to Home',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kOrangeColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    paymentService.dispose();
    super.dispose();
  }
}
