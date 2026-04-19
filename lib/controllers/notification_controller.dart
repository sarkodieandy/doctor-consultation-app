import 'package:doctor_consultation_app/models/notification_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/notification_service.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final _authService = AuthService();
  final _notificationService = NotificationService();

  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final errorMessage = Rxn<String>();

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    fetchNotifications();
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
      final result = await _notificationService.getNotifications(userId);
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
    await _notificationService.markNotificationAsRead(notificationId);
    await fetchNotifications();
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await _notificationService.markAllAsRead(userId);
    await fetchNotifications();
  }

  Future<void> openNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      await markAsRead(notification.id);
    }

    switch (notification.type) {
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
