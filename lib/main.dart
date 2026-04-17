import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/screens/booking_screen.dart';
import 'package:doctor_consultation_app/screens/home_screen.dart';
import 'package:doctor_consultation_app/screens/login_screen.dart';
import 'package:doctor_consultation_app/screens/my_appointments_screen.dart';
import 'package:doctor_consultation_app/screens/payment_screen.dart';
import 'package:doctor_consultation_app/screens/profile_screen.dart';
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
      ],
    );
  }
}
