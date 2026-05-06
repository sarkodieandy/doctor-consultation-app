import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/care_timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CareNextStepCard extends StatelessWidget {
  final CareTimelineItem item;
  final String badgeLabel;
  final String bodyText;
  final String? primaryLabel;
  final String? primaryRouteName;
  final String? secondaryLabel;
  final String? secondaryRouteName;

  const CareNextStepCard({
    super.key,
    required this.item,
    required this.badgeLabel,
    required this.bodyText,
    this.primaryLabel,
    this.primaryRouteName,
    this.secondaryLabel,
    this.secondaryRouteName,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = colorForType(item.type);
    final actionColor = kBlueColor;
    final isUrgent = _isUrgent(item.timestamp);
    final timeLabel = _timeLabel(item.timestamp);
    final resolvedPrimaryLabel =
        primaryLabel ?? _primaryLabelForState(isUrgent);
    final resolvedPrimaryRoute = primaryRouteName ?? item.routeName;
    final resolvedSecondaryLabel = secondaryLabel ?? _secondaryLabelForType();
    final resolvedSecondaryRoute =
        secondaryRouteName ?? _secondaryRouteForType();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? accentColor.withOpacity(0.28)
              : accentColor.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 54,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconForType(item.type),
                      size: 12,
                      color: accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labelForType(item.type),
                      style: TextStyle(
                        color: kTitleTextColor.withOpacity(0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isUrgent
                          ? accentColor
                          : kTitleTextColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: kTitleTextColor.withOpacity(0.46),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isUrgent ? accentColor.withOpacity(0.08) : kBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kTitleTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bodyText,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: kTitleTextColor.withOpacity(0.65),
                        ),
                      ),
                      if (item.contextTags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.contextTags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildImagePreview(accentColor),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(
                      resolvedPrimaryRoute,
                      arguments: item.arguments,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: kWhiteColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          resolvedPrimaryLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: kWhiteColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(resolvedSecondaryRoute),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: actionColor,
                    side: BorderSide(color: actionColor.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(resolvedSecondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color colorForType(String type) {
    switch (type) {
      case 'consultation':
        return Colors.deepPurple;
      case 'prescription':
      case 'medication':
        return Colors.teal;
      case 'review':
        return Colors.amber.shade700;
      case 'appointment':
      case 'reminder':
        return kBlueColor;
      default:
        return kOrangeColor;
    }
  }

  static IconData iconForType(String type) {
    switch (type) {
      case 'consultation':
        return Icons.videocam_outlined;
      case 'prescription':
      case 'medication':
        return Icons.medication_outlined;
      case 'review':
        return Icons.star_outline;
      case 'appointment':
        return Icons.calendar_today_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  static String labelForType(String type) {
    switch (type) {
      case 'consultation':
        return 'Consultation';
      case 'prescription':
        return 'Prescription';
      case 'medication':
        return 'Medication';
      case 'review':
        return 'Review';
      case 'appointment':
        return 'Appointment';
      case 'reminder':
        return 'Reminder';
      default:
        return 'Update';
    }
  }

  Widget _buildImagePreview(Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(
            item.imageUrl,
            width: 78,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 78,
                height: 92,
                color: accentColor.withOpacity(0.12),
                alignment: Alignment.center,
                child: Icon(
                  iconForType(item.type),
                  color: accentColor,
                  size: 22,
                ),
              );
            },
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isUrgent(DateTime timestamp) {
    final difference = timestamp.difference(DateTime.now());
    return !difference.isNegative && difference.inHours <= 24;
  }

  String _timeLabel(DateTime timestamp) {
    final now = DateTime.now();
    final difference = timestamp.difference(now);

    if (difference.isNegative) {
      final elapsed = now.difference(timestamp);
      if (elapsed.inHours < 1) {
        return 'Moments ago';
      }
      if (elapsed.inHours < 24) {
        return '${elapsed.inHours}h ago';
      }
      if (elapsed.inDays == 1) {
        return 'Yesterday';
      }
      return DateFormat('MMM d').format(timestamp);
    }

    if (difference.inHours < 1) {
      return 'Within the hour';
    }
    if (difference.inHours < 24) {
      return 'In ${difference.inHours}h';
    }
    if (difference.inDays == 1) {
      return 'Tomorrow';
    }
    if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    }
    return DateFormat('MMM d').format(timestamp);
  }

  String _secondaryLabelForType() {
    switch (item.type) {
      case 'appointment':
      case 'reminder':
        return 'Messages';
      case 'consultation':
        return 'All Consults';
      case 'prescription':
      case 'medication':
        return 'Prescriptions';
      case 'review':
        return 'Reviews';
      default:
        return 'Full Timeline';
    }
  }

  String _primaryLabelForState(bool isUrgent) {
    switch (item.type) {
      case 'appointment':
        if (isUrgent) {
          return 'Prepare Visit';
        }
        return item.statusLabel == 'COMPLETED'
            ? 'Review Visit'
            : 'Open Appointment';
      case 'consultation':
        if (isUrgent || item.statusLabel == 'SCHEDULED') {
          return 'Join Consultation';
        }
        if (item.statusLabel == 'COMPLETED') {
          return 'View Summary';
        }
        return item.ctaLabel;
      case 'prescription':
      case 'medication':
        return item.statusLabel == 'ACTIVE'
            ? 'Review Medication'
            : 'View Details';
      case 'review':
        return item.statusLabel == 'NEW' ? 'Give Feedback' : 'Open Reviews';
      case 'reminder':
        return 'Check Reminder';
      case 'payment':
        return 'View Payment';
      default:
        return item.ctaLabel;
    }
  }

  String _secondaryRouteForType() {
    switch (item.type) {
      case 'appointment':
      case 'reminder':
        return '/chat';
      case 'consultation':
        return '/consultations';
      case 'prescription':
      case 'medication':
        return '/prescriptions';
      case 'review':
        return '/reviews';
      default:
        return '/care-timeline';
    }
  }
}
