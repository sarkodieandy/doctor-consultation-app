import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/controllers/chat_controller.dart';
import 'package:doctor_consultation_app/controllers/consultation_controller.dart';
import 'package:doctor_consultation_app/controllers/health_record_controller.dart';
import 'package:doctor_consultation_app/controllers/prescription_controller.dart';
import 'package:doctor_consultation_app/controllers/review_controller.dart';
import 'package:doctor_consultation_app/screens/booking_screen.dart';
import 'package:doctor_consultation_app/screens/chat_screen.dart';
import 'package:doctor_consultation_app/screens/consultation_screen.dart';
import 'package:doctor_consultation_app/screens/health_records_screen.dart';
import 'package:doctor_consultation_app/screens/home_screen.dart';
import 'package:doctor_consultation_app/screens/login_screen.dart';
import 'package:doctor_consultation_app/screens/my_appointments_screen.dart';
import 'package:doctor_consultation_app/screens/payment_screen.dart';
import 'package:doctor_consultation_app/screens/prescriptions_screen.dart';
import 'package:doctor_consultation_app/screens/profile_screen.dart';
import 'package:doctor_consultation_app/screens/reviews_screen.dart';
import 'package:doctor_consultation_app/screens/splash_screen.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme:
            GoogleFonts.varelaRoundTextTheme(Theme.of(context).textTheme),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => SplashScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginScreen(),
        ),
        GetPage(
          name: '/home',
          page: () => HomeScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AppointmentController>(() => AppointmentController());
          }),
        ),
        GetPage(
          name: '/booking',
          page: () => BookingScreen(
            doctor: Get.arguments,
          ),
        ),
        GetPage(
          name: '/payment',
          page: () => PaymentScreen(),
        ),
        GetPage(
          name: '/appointments',
          page: () => MyAppointmentsScreen(),
        ),
        GetPage(
          name: '/profile',
          page: () => ProfileScreen(),
        ),
        // Chat Routes
        GetPage(
          name: '/chat',
          page: () => ChatScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChatController>(() => ChatController());
          }),
        ),
        GetPage(
          name: '/chat-detail',
          page: () => ChatDetailScreen(),
        ),
        // Health Records Route
        GetPage(
          name: '/health-records',
          page: () => HealthRecordsScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<HealthRecordController>(() => HealthRecordController());
          }),
        ),
        // Prescriptions Routes
        GetPage(
          name: '/prescriptions',
          page: () => PrescriptionsScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<PrescriptionController>(() => PrescriptionController());
          }),
        ),
        GetPage(
          name: '/prescription-detail',
          page: () => PrescriptionDetailScreen(),
        ),
        // Consultations Routes
        GetPage(
          name: '/consultations',
          page: () => ConsultationScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ConsultationController>(() => ConsultationController());
          }),
        ),
        GetPage(
          name: '/consultation-detail',
          page: () => ConsultationScreen(),
        ),
        GetPage(
          name: '/video-consultation',
          page: () => VideoConsultationScreen(),
        ),
        // Reviews Routes
        GetPage(
          name: '/reviews',
          page: () => ReviewsScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ReviewController>(() => ReviewController());
          }),
        ),
        GetPage(
          name: '/write-review',
          page: () => WriteReviewScreen(),
        ),
      ],
    );
  }
}
