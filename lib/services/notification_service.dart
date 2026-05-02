import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/services/ui_mock_store.dart';
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
  final _store = UiMockStore.instance;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
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

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  /// Save notification locally and show in-app.
  Future<void> _saveAndShow(NotificationModel notification) async {
    _store.notifications.removeWhere((item) => item.id == notification.id);
    _store.notifications.add(notification);
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

  Future<void> sendMedicationReminder({
    required String prescriptionId,
    required String medicineId,
    required String medicineName,
    required String dosage,
    required String frequency,
    String userId = '',
  }) async {
    final notification = NotificationModel(
      id: 'medication_${prescriptionId}_$medicineId',
      userId: userId,
      title: 'Medication Reminder Saved',
      message: 'Reminder added for $medicineName ($dosage, $frequency).',
      type: 'medication',
      relatedId: prescriptionId,
      isRead: false,
      createdAt: DateTime.now(),
      metadata: {
        'medicineId': medicineId,
        'medicineName': medicineName,
        'dosage': dosage,
        'frequency': frequency,
      },
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
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('notifications')
            .select()
            .or('user_id.eq.$userId,target_role.eq.all')
            .order('created_at', ascending: false);
        return (data as List)
            .map((item) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (_) {}
    }
    final notifications = _store.notifications
        .where((notification) => notification.userId == userId)
        .toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('notifications').update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('id', notificationId);
      } catch (_) {}
    }
    final index = _store.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index != -1) {
      _store.notifications[index] = _store.notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final client = _client;
    if (client != null) {
      try {
        await client
            .from('notifications')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('is_read', false);
      } catch (_) {}
    }
    for (var index = 0; index < _store.notifications.length; index += 1) {
      final notification = _store.notifications[index];
      if (notification.userId == userId && !notification.isRead) {
        _store.notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    return _store.notifications
        .where((notification) =>
            notification.userId == userId && !notification.isRead)
        .length;
  }
}
