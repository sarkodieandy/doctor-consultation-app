import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/controllers/care_timeline_controller.dart';
import 'package:doctor_consultation_app/controllers/chat_controller.dart';
import 'package:doctor_consultation_app/controllers/consultation_controller.dart';
import 'package:doctor_consultation_app/controllers/health_record_controller.dart';
import 'package:doctor_consultation_app/controllers/notification_controller.dart';
import 'package:doctor_consultation_app/controllers/prescription_controller.dart';
import 'package:doctor_consultation_app/controllers/review_controller.dart';
import 'package:doctor_consultation_app/config/supabase_config.dart';
import 'package:doctor_consultation_app/screens/booking_screen.dart';
import 'package:doctor_consultation_app/screens/care_timeline_screen.dart';
import 'package:doctor_consultation_app/screens/chat_screen.dart';
import 'package:doctor_consultation_app/screens/consultation_screen.dart';
import 'package:doctor_consultation_app/screens/video_consultation_screen_new.dart';
import 'package:doctor_consultation_app/screens/doctor/doctor_appointments_screen.dart';
import 'package:doctor_consultation_app/screens/doctor/doctor_dashboard_screen.dart';
import 'package:doctor_consultation_app/screens/doctor/doctor_earnings_screen.dart';
import 'package:doctor_consultation_app/screens/doctor/doctor_profile_edit_screen.dart';
import 'package:doctor_consultation_app/screens/doctor/doctor_prescription_writer_screen.dart';
import 'package:doctor_consultation_app/screens/doctor/doctor_schedule_screen.dart';
import 'package:doctor_consultation_app/screens/doctor/pending_approval_screen.dart';
import 'package:doctor_consultation_app/screens/health_records_screen.dart';
import 'package:doctor_consultation_app/screens/home_screen.dart';
import 'package:doctor_consultation_app/screens/login_screen.dart';
import 'package:doctor_consultation_app/screens/signup_screen.dart';
import 'package:doctor_consultation_app/screens/my_appointments_screen.dart';
import 'package:doctor_consultation_app/screens/notifications_screen.dart';
import 'package:doctor_consultation_app/screens/onboarding_screen.dart';
import 'package:doctor_consultation_app/screens/payment_screen.dart';
import 'package:doctor_consultation_app/screens/payment_method_screen.dart';
import 'package:doctor_consultation_app/screens/prescriptions_screen.dart';
import 'package:doctor_consultation_app/screens/profile_screen.dart';
import 'package:doctor_consultation_app/screens/reviews_screen.dart';
import 'package:doctor_consultation_app/screens/requested_flow_screens.dart';
import 'package:doctor_consultation_app/screens/splash_screen.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:doctor_consultation_app/services/ui_data_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void ensureAppointmentController() {
  if (!Get.isRegistered<AppointmentController>()) {
    Get.put<AppointmentController>(AppointmentController());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: AuthService()),
        Provider<UiDataService>(create: (_) => UiDataService()),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        defaultTransition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
        popGesture: true,
        builder: (context, child) {
          return Listener(
            onPointerDown: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: ThemeData(
          textTheme:
              GoogleFonts.varelaRoundTextTheme(Theme.of(context).textTheme),
          appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(size: 24),
          ),
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
            name: '/signup',
            page: () => SignupScreen(),
          ),
          GetPage(
            name: '/onboarding',
            page: () => OnboardingScreen(),
          ),
          GetPage(
            name: '/home',
            page: () => HomeScreen(),
            binding: BindingsBuilder(ensureAppointmentController),
          ),
          GetPage(
            name: '/booking',
            page: () => BookingScreen(
              doctor: Get.arguments,
            ),
            binding: BindingsBuilder(ensureAppointmentController),
          ),
          GetPage(
            name: '/payment',
            page: () => PaymentScreen(),
            binding: BindingsBuilder(ensureAppointmentController),
          ),
          GetPage(
            name: '/payment-method',
            page: () => PaymentMethodScreen(),
            binding: BindingsBuilder(ensureAppointmentController),
          ),
          GetPage(
            name: '/appointments',
            page: () => MyAppointmentsScreen(),
            binding: BindingsBuilder(ensureAppointmentController),
          ),
          GetPage(
            name: '/profile',
            page: () => ProfileScreen(),
          ),
          GetPage(
            name: '/symptom-checker',
            page: () => const SymptomCheckerScreen(),
          ),
          GetPage(
            name: '/service-selection',
            page: () => const ServiceSelectionScreen(),
          ),
          GetPage(
            name: '/lab-selection',
            page: () => const LabSelectionScreen(),
          ),
          GetPage(
            name: '/doctor-selection',
            page: () => const DoctorSelectionScreen(),
          ),
          GetPage(
            name: '/booking-confirmation',
            page: () => const BookingConfirmationScreen(),
          ),
          GetPage(
            name: '/track-doctor',
            page: () => const TrackDoctorScreen(),
          ),
          GetPage(
            name: '/consultation-summary',
            page: () => const ConsultationSummaryScreen(),
          ),
          GetPage(
            name: '/settings',
            page: () => const AppSettingsScreen(),
          ),
          GetPage(
            name: '/notifications',
            page: () => NotificationsScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<NotificationController>()) {
                Get.lazyPut<NotificationController>(
                    () => NotificationController());
              }
            }),
          ),
          GetPage(
            name: '/care-timeline',
            page: () => CareTimelineScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<CareTimelineController>()) {
                Get.lazyPut<CareTimelineController>(
                    () => CareTimelineController());
              }
            }),
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
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<ChatController>()) {
                Get.lazyPut<ChatController>(() => ChatController());
              }
            }),
          ),
          // Health Records Route
          GetPage(
            name: '/health-records',
            page: () => HealthRecordsScreen(),
            binding: BindingsBuilder(() {
              Get.lazyPut<HealthRecordController>(
                  () => HealthRecordController());
            }),
          ),
          // Prescriptions Routes
          GetPage(
            name: '/prescriptions',
            page: () => PrescriptionsScreen(),
            binding: BindingsBuilder(() {
              Get.lazyPut<PrescriptionController>(
                  () => PrescriptionController());
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
              Get.lazyPut<ConsultationController>(
                  () => ConsultationController());
            }),
          ),
          GetPage(
            name: '/consultation-detail',
            page: () => ConsultationDetailScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<ConsultationController>()) {
                Get.lazyPut<ConsultationController>(
                    () => ConsultationController());
              }
            }),
          ),
          GetPage(
            name: '/video-consultation',
            page: () =>
                VideoConsultationScreen(), // uses video_consultation_screen_new.dart
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<ConsultationController>()) {
                Get.lazyPut<ConsultationController>(
                    () => ConsultationController());
              }
            }),
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
          // Doctor Routes
          GetPage(
            name: '/pending-approval',
            page: () => PendingApprovalScreen(),
          ),
          GetPage(
            name: '/doctor-home',
            page: () => DoctorDashboardScreen(),
          ),
          GetPage(
            name: '/doctor-schedule',
            page: () => DoctorScheduleScreen(),
          ),
          GetPage(
            name: '/doctor-appointments',
            page: () => DoctorAppointmentsScreen(),
          ),
          GetPage(
            name: '/doctor-earnings',
            page: () => DoctorEarningsScreen(),
          ),
          GetPage(
            name: '/doctor-profile-edit',
            page: () => DoctorProfileEditScreen(),
          ),
          // Aliases used by doctor dashboard quick actions
          GetPage(
            name: '/doctor-chat',
            page: () => ChatScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<ChatController>()) {
                Get.lazyPut<ChatController>(() => ChatController());
              }
            }),
          ),
          GetPage(
            name: '/doctor-prescriptions',
            page: () => PrescriptionsScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<PrescriptionController>()) {
                Get.lazyPut<PrescriptionController>(
                    () => PrescriptionController());
              }
            }),
          ),
          GetPage(
            name: '/doctor-profile',
            page: () => DoctorProfileEditScreen(),
          ),
          GetPage(
            name: '/doctor-write-prescription',
            page: () => const DoctorPrescriptionWriterScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<PrescriptionController>()) {
                Get.lazyPut<PrescriptionController>(
                    () => PrescriptionController());
              }
            }),
          ),
          GetPage(
            name: '/doctor-verification-status',
            page: () => const DoctorVerificationStatusScreen(),
          ),
        ],
      ),
    );
  }
}
