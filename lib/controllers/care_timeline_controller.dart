import 'package:doctor_consultation_app/models/care_timeline_item.dart';
import 'package:doctor_consultation_app/data/repositories/appointment_repository.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/consultation_service.dart';
import 'package:doctor_consultation_app/data/repositories/prescription_repository.dart';
import 'package:doctor_consultation_app/data/repositories/notification_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class CareTimelineController extends GetxController {
  final _authService = AuthService();
  final _appointmentRepo = AppointmentRepository();
  final _consultationService = ConsultationService();
  final _prescriptionRepo = PrescriptionRepository();
  final _notificationRepo = NotificationRepository();

  final items = <CareTimelineItem>[].obs;
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();
  final selectedFilter = 'All'.obs;

  static const filters = <String>[
    'All',
    'Appointments',
    'Consultations',
    'Prescriptions',
    'Updates',
  ];

  String? _userId;

  static const _appointmentFallbackImage = 'assets/images/doctor1.png';
  static const _consultationFallbackImage = 'assets/images/doctor2.png';
  static const _prescriptionFallbackImage =
      'assets/images/detail_illustration.png';
  static const _notificationFallbackImage =
      'assets/images/onboarding_illustration.png';

  @override
  void onInit() {
    super.onInit();
    _userId = _authService.resolveUserId(fallback: Get.arguments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        return;
      }
      fetchTimeline();
    });
  }

  List<CareTimelineItem> get visibleItems {
    return items
        .where((item) => _matchesFilter(item, selectedFilter.value))
        .toList();
  }

  CareTimelineItem? get nextUpcomingItem {
    final now = DateTime.now();
    for (final item in items) {
      if (item.timestamp.isAfter(now)) {
        return item;
      }
    }
    return null;
  }

  int countForFilter(String filter) {
    return items.where((item) => _matchesFilter(item, filter)).length;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  bool _matchesFilter(CareTimelineItem item, String filter) {
    switch (filter) {
      case 'Appointments':
        return item.type == 'appointment';
      case 'Consultations':
        return item.type == 'consultation';
      case 'Prescriptions':
        return item.type == 'prescription' || item.type == 'medication';
      case 'Updates':
        return item.type != 'appointment' &&
            item.type != 'consultation' &&
            item.type != 'prescription';
      default:
        return true;
    }
  }

  Future<void> fetchTimeline() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      isLoading(true);
      errorMessage(null);

      final appointments = await _appointmentRepo.fetchUserAppointments(userId);
      final consultations = await _consultationService.getConsultations(userId);
      final prescriptions = await _prescriptionRepo.fetchPrescriptions(userId);
      final notifications = await _notificationRepo.fetchNotifications(userId);

      final timelineItems = <CareTimelineItem>[
        ...appointments.map(
          (appointment) => CareTimelineItem(
            id: 'appointment_${appointment.id}',
            type: 'appointment',
            title: 'Appointment with ${appointment.doctorName}',
            subtitle:
                '${appointment.speciality} • ${appointment.timeSlot} • GHS ${appointment.consultationFee.toStringAsFixed(2)}',
            imageUrl: _resolvePreviewImage(
              appointment.doctorImage,
              _appointmentFallbackImage,
            ),
            contextTags: [
              appointment.speciality,
              appointment.timeSlot,
              'GHS ${appointment.consultationFee.toStringAsFixed(2)}',
            ],
            statusLabel: appointment.status.toUpperCase(),
            timestamp: appointment.appointmentDate,
            ctaLabel: 'Open appointments',
            routeName: '/appointments',
          ),
        ),
        ...consultations.map(
          (consultation) => CareTimelineItem(
            id: 'consultation_${consultation.id}',
            type: 'consultation',
            title:
                '${consultation.consultationType.toUpperCase()} consultation',
            subtitle:
                '${consultation.doctorName} • ${consultation.duration.inMinutes} min',
            imageUrl: _resolvePreviewImage(
              consultation.doctorAvatar,
              _consultationFallbackImage,
            ),
            contextTags: [
              consultation.doctorName,
              '${consultation.duration.inMinutes} min',
              consultation.consultationType.toUpperCase(),
            ],
            statusLabel: consultation.status.toUpperCase(),
            timestamp: consultation.endedAt ?? consultation.scheduledTime,
            ctaLabel: 'Open consultation',
            routeName: '/consultation-detail',
            arguments: consultation,
          ),
        ),
        ...prescriptions.map(
          (prescription) => CareTimelineItem(
            id: 'prescription_${prescription.id}',
            type: 'prescription',
            title: 'Prescription from ${prescription.doctorName}',
            subtitle:
                '${prescription.medicines.length} medicine${prescription.medicines.length == 1 ? '' : 's'} • ${prescription.notes}',
            imageUrl: _prescriptionFallbackImage,
            contextTags: [
              prescription.doctorName,
              '${prescription.medicines.length} medicine${prescription.medicines.length == 1 ? '' : 's'}',
              if (prescription.medicines.isNotEmpty)
                prescription.medicines.first.name,
            ],
            statusLabel: prescription.isActive ? 'ACTIVE' : 'COMPLETED',
            timestamp: prescription.prescribedDate,
            ctaLabel: 'View prescription',
            routeName: '/prescription-detail',
            arguments: prescription,
          ),
        ),
        ...notifications.map(
          (notification) => CareTimelineItem(
            id: 'notification_${notification.id}',
            type: notification.type,
            title: notification.title,
            subtitle: notification.message,
            imageUrl: _notificationFallbackImage,
            contextTags: [
              notification.type.toUpperCase(),
              notification.isRead ? 'Viewed' : 'Unread',
            ],
            statusLabel: notification.isRead ? 'READ' : 'NEW',
            timestamp: notification.createdAt,
            ctaLabel: 'Open inbox',
            routeName: '/notifications',
          ),
        ),
      ];

      timelineItems.sort(
        (left, right) => right.timestamp.compareTo(left.timestamp),
      );
      items.assignAll(timelineItems);
    } catch (error) {
      errorMessage(error.toString());
    } finally {
      isLoading(false);
    }
  }

  String _resolvePreviewImage(String candidate, String fallback) {
    final value = candidate.trim();
    if (value.startsWith('assets/')) {
      return value;
    }
    return fallback;
  }
}
