import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/data/repositories/notification_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationController extends GetxController {
  final _authService = AuthService();
  final _notificationRepo = NotificationRepository();

  RealtimeChannel? _notificationChannel;

  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final errorMessage = Rxn<String>();

  String? _userId;
  String? _targetRole;

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        return;
      }
      fetchNotifications();
      _subscribeNotificationsRealtime();
    });
  }

  void _subscribeNotificationsRealtime() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    _targetRole ??= _resolveTargetRole();
    try {
      final client = Supabase.instance.client;
      _notificationChannel = client
          .channel('notifications-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final row = payload.newRecord;
              final rowUserId = row['user_id']?.toString();
              final targetRole = row['target_role']?.toString();
              if (rowUserId == userId ||
                  targetRole == 'all' ||
                  targetRole == _targetRole) {
                fetchNotifications();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  String? _resolveTargetRole() {
    final user = _authService.currentUser;
    if (user != null) {
      if (user.isDoctor) return 'doctor';
      if (user.isPatient) return 'patient';
      if (user.isAdmin) return 'admin';
    }

    try {
      final rawRole = Supabase
          .instance.client.auth.currentUser?.userMetadata?['role']
          ?.toString()
          .toLowerCase();
      if (rawRole == 'doctor' || rawRole == 'patient' || rawRole == 'admin') {
        return rawRole;
      }
    } catch (_) {}
    return null;
  }

  @override
  void onClose() {
    final channel = _notificationChannel;
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (_) {}
    }
    super.onClose();
  }

  Future<void> refresh() async {
    await fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      isLoading(true);
      errorMessage(null);
      final result = await _notificationRepo.fetchNotifications(userId);
      notifications.assignAll(result);
      unreadCount.value =
          result.where((notification) => !notification.isRead).length;
    } catch (error) {
      errorMessage(error.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationRepo.markAsRead(notificationId);
    await fetchNotifications();
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await _notificationRepo.markAllAsRead(userId);
    await fetchNotifications();
  }

  Future<void> openNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      await markAsRead(notification.id);
    }

    switch (notification.type) {
      case 'announcement':
        Get.toNamed('/notifications');
        break;
      case 'medication':
        Get.toNamed('/prescriptions');
        break;
      case 'review':
        Get.toNamed('/appointments');
        break;
      case 'payment':
      case 'reminder':
      case 'appointment':
      default:
        Get.toNamed('/appointments');
        break;
    }
  }
}
