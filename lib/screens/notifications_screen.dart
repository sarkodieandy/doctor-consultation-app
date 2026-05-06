import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NotificationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: controller.markAllAsRead,
            child: Text(
              'Mark all',
              style: TextStyle(
                color: kBlueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        if (controller.errorMessage.value != null) {
          return _buildErrorState();
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildOverviewCard(),
              SizedBox(height: 16),
              _buildNotificationQuickCard(),
              SizedBox(height: 16),
              ...controller.notifications.map(_buildNotificationCard),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat('${controller.notifications.length}', 'Total'),
          ),
          Expanded(
            child: _buildStat('${controller.unreadCount.value}', 'Unread'),
          ),
          Expanded(
            child: _buildStat(
              '${controller.notifications.where((item) => item.type == 'reminder').length}',
              'Reminders',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: kBlueColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kTitleTextColor.withOpacity(0.58),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    final accentColor = _typeColor(notification.type);

    return GestureDetector(
      onTap: () => controller.openNotification(notification),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : accentColor.withOpacity(0.24),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(notification.type), color: accentColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kTitleTextColor,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      height: 1.45,
                      color: kTitleTextColor.withOpacity(0.68),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    DateFormat('MMM d, yyyy • hh:mm a')
                        .format(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: kTitleTextColor.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _actionLabel(notification.type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 14, color: accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationQuickCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay on top of care',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reminders, appointment updates, and prescription alerts are all here.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: controller.markAllAsRead,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Mark all\nread',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Unable to load notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.errorMessage.value ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 18),
            OutlinedButton(
              onPressed: controller.refresh,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
            SizedBox(height: 18),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Appointment reminders, payment updates, and follow-up prompts appear here in the UI preview.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication_outlined;
      case 'payment':
        return Icons.receipt_long_outlined;
      case 'review':
        return Icons.star_outline;
      case 'reminder':
        return Icons.alarm_outlined;
      default:
        return Icons.calendar_today_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication':
      case 'prescription':
        return Colors.teal;
      case 'payment':
        return Colors.green;
      case 'review':
        return kOrangeColor;
      case 'reminder':
      case 'consultation':
        return Colors.deepPurple;
      case 'appointment':
        return kBlueColor;
      default:
        return kBlueColor;
    }
  }

  String _actionLabel(String type) {
    switch (type) {
      case 'medication':
        return 'Open prescriptions';
      case 'review':
        return 'Open appointments';
      case 'payment':
        return 'View booking history';
      case 'reminder':
        return 'Check upcoming visit';
      default:
        return 'Open details';
    }
  }
}
