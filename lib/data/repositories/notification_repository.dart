import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';

class NotificationRepository {
  final NotificationService _local = NotificationService();

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    return await _local.getNotifications(userId);
  }

  Future<void> markAsRead(String notificationId) async {
    await _local.markNotificationAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _local.markAllAsRead(userId);
  }

  Future<int> getUnreadCount(String userId) async {
    return await _local.getUnreadCount(userId);
  }
}
