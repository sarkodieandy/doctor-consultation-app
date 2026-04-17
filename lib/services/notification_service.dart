import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  /// Initialize notifications
  Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Send appointment reminder notification
  Future<void> sendAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
  }) async {
    final notification = NotificationModel(
      id: appointmentId,
      userId: '',
      title: 'Appointment Reminder',
      message: 'Your appointment with $doctorName is in 1 hour',
      type: 'reminder',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _showNotification(
      id: appointmentId.hashCode,
      title: notification.title,
      body: notification.message,
    );
  }

  /// Send appointment confirmed notification
  Future<void> sendAppointmentConfirmed({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
  }) async {
    final notification = NotificationModel(
      id: appointmentId,
      userId: '',
      title: 'Appointment Confirmed',
      message: 'Your appointment with $doctorName is confirmed',
      type: 'appointment',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _showNotification(
      id: appointmentId.hashCode,
      title: notification.title,
      body: notification.message,
    );
  }

  /// Send payment success notification
  Future<void> sendPaymentSuccess({
    required String paymentId,
    required double amount,
    required String appointmentId,
  }) async {
    final notification = NotificationModel(
      id: paymentId,
      userId: '',
      title: 'Payment Successful',
      message: 'Payment of ₹$amount received. Your appointment is confirmed.',
      type: 'payment',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _showNotification(
      id: paymentId.hashCode,
      title: notification.title,
      body: notification.message,
    );
  }

  /// Send payment failed notification
  Future<void> sendPaymentFailed({
    required String paymentId,
    required String reason,
  }) async {
    final notification = NotificationModel(
      id: paymentId,
      userId: '',
      title: 'Payment Failed',
      message: 'Payment failed: $reason. Please try again.',
      type: 'payment',
      relatedId: paymentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _showNotification(
      id: paymentId.hashCode,
      title: notification.title,
      body: notification.message,
    );
  }

  /// Send review request notification
  Future<void> sendReviewRequest({
    required String appointmentId,
    required String doctorName,
  }) async {
    final notification = NotificationModel(
      id: appointmentId,
      userId: '',
      title: 'Share Your Experience',
      message: 'How was your appointment with $doctorName? Leave a review.',
      type: 'review',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _showNotification(
      id: appointmentId.hashCode,
      title: notification.title,
      body: notification.message,
    );
  }

  /// Show local notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'doctor_app_channel',
      'Doctor Consultation Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Get all notifications (mock)
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      return [
        NotificationModel(
          id: '1',
          userId: userId,
          title: 'Appointment Confirmed',
          message: 'Your appointment with Dr. Stella is confirmed',
          type: 'appointment',
          relatedId: 'apt_1',
          isRead: false,
          createdAt: DateTime.now().subtract(Duration(hours: 2)),
        ),
        NotificationModel(
          id: '2',
          userId: userId,
          title: 'Payment Successful',
          message: 'Payment of ₹500 received successfully',
          type: 'payment',
          relatedId: 'pmt_1',
          isRead: true,
          createdAt: DateTime.now().subtract(Duration(hours: 3)),
        ),
      ];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
