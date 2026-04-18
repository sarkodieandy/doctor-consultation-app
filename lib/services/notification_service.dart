import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  final _supabase = Supabase.instance.client;

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

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  /// Save notification to Supabase and show locally
  Future<void> _saveAndShow(NotificationModel notification) async {
    try {
      final json = notification.toJson();
      json.remove('id');
      await _supabase.from('notifications').insert(json);
    } catch (e) {
      print('Error saving notification: $e');
    }

    await _showNotification(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.message,
    );
  }

  /// Send appointment reminder notification
  Future<void> sendAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
    String userId = '',
  }) async {
    final notification = NotificationModel(
      id: appointmentId,
      userId: userId,
      title: 'Appointment Reminder',
      message: 'Your appointment with $doctorName is in 1 hour',
      type: 'reminder',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _saveAndShow(notification);
  }

  /// Send appointment confirmed notification
  Future<void> sendAppointmentConfirmed({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
    String userId = '',
  }) async {
    final notification = NotificationModel(
      id: appointmentId,
      userId: userId,
      title: 'Appointment Confirmed',
      message: 'Your appointment with $doctorName is confirmed',
      type: 'appointment',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _saveAndShow(notification);
  }

  /// Send payment success notification
  Future<void> sendPaymentSuccess({
    required String paymentId,
    required double amount,
    required String appointmentId,
    String userId = '',
  }) async {
    final notification = NotificationModel(
      id: paymentId,
      userId: userId,
      title: 'Payment Successful',
      message:
          'Payment of GHS $amount received. Your appointment is confirmed.',
      type: 'payment',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _saveAndShow(notification);
  }

  /// Send payment failed notification
  Future<void> sendPaymentFailed({
    required String paymentId,
    required String reason,
    String userId = '',
  }) async {
    final notification = NotificationModel(
      id: paymentId,
      userId: userId,
      title: 'Payment Failed',
      message: 'Payment failed: $reason. Please try again.',
      type: 'payment',
      relatedId: paymentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _saveAndShow(notification);
  }

  /// Send review request notification
  Future<void> sendReviewRequest({
    required String appointmentId,
    required String doctorName,
    String userId = '',
  }) async {
    final notification = NotificationModel(
      id: appointmentId,
      userId: userId,
      title: 'Share Your Experience',
      message: 'How was your appointment with $doctorName? Leave a review.',
      type: 'review',
      relatedId: appointmentId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _saveAndShow(notification);
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
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  /// Get all notifications
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }
}
