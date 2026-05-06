import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/care_timeline_controller.dart';
import 'package:doctor_consultation_app/models/care_timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CareTimelineScreen extends StatelessWidget {
  final controller = Get.find<CareTimelineController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBlueColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kWhiteColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Care Timeline',
          style: TextStyle(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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

        if (controller.items.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.fetchTimeline,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildOverviewCard(),
              SizedBox(height: 16),
              _buildNextStepCard(),
              SizedBox(height: 16),
              _buildFilterBar(),
              SizedBox(height: 16),
              ..._buildTimelineSections(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOverviewCard() {
    final items = controller.visibleItems;
    final newItems = items.where((item) => item.statusLabel == 'NEW').length;
    final upcomingItems =
        items.where((item) => item.timestamp.isAfter(DateTime.now())).length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStat('${items.length}', 'Moments')),
          Container(width: 1, height: 36, color: kWhiteColor.withOpacity(0.25)),
          Expanded(child: _buildStat('$upcomingItems', 'Upcoming')),
          Container(width: 1, height: 36, color: kWhiteColor.withOpacity(0.25)),
          Expanded(child: _buildStat('$newItems', 'New')),
        ],
      ),
    );
  }

  Widget _buildNextStepCard() {
    final nextItem = controller.nextUpcomingItem;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlueColor.withOpacity(0.2)),
      ),
      child: nextItem == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Step',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'You are caught up for now. Keep an eye on reminders and prescriptions for the next action in your care journey.',
                  style: TextStyle(
                    height: 1.45,
                    color: kTitleTextColor.withOpacity(0.66),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Step',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  nextItem.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  nextItem.subtitle,
                  style: TextStyle(
                    height: 1.45,
                    color: kTitleTextColor.withOpacity(0.66),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  DateFormat('MMM d, yyyy • hh:mm a')
                      .format(nextItem.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: kTitleTextColor.withOpacity(0.5),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    onPressed: () {
                      Get.toNamed(nextItem.routeName,
                          arguments: nextItem.arguments);
                    },
                    color: kBlueColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      nextItem.ctaLabel,
                      style: TextStyle(
                          color: kWhiteColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CareTimelineController.filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = CareTimelineController.filters[index];
          final isSelected = controller.selectedFilter.value == filter;
          return GestureDetector(
            onTap: () => controller.setFilter(filter),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? kOrangeColor : kWhiteColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? kOrangeColor
                      : kTitleTextColor.withOpacity(0.08),
                ),
              ),
              child: Text(
                '$filter (${controller.countForFilter(filter)})',
                style: TextStyle(
                  color: isSelected ? kWhiteColor : kTitleTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: kWhiteColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kWhiteColor.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(CareTimelineItem item) {
    final accent = _typeColor(item.type);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_typeIcon(item.type), color: kWhiteColor, size: 22),
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
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kTitleTextColor,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    height: 1.45,
                    color: kTitleTextColor.withOpacity(0.68),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  DateFormat('MMM d, yyyy • hh:mm a').format(item.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: kTitleTextColor.withOpacity(0.5),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.toNamed(item.routeName, arguments: item.arguments);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        item.ctaLabel,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    if (_secondaryActionLabel(item) != null)
                      TextButton(
                        onPressed: () {
                          final secondaryRoute = _secondaryActionRoute(item);
                          if (secondaryRoute != null) {
                            Get.toNamed(secondaryRoute);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _secondaryActionLabel(item)!,
                          style: TextStyle(
                            color: kTitleTextColor.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
            Icon(Icons.timeline, size: 60, color: Colors.grey[300]),
            SizedBox(height: 18),
            Text(
              'No care events yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Appointments, prescriptions, consultations, and reminders will appear here as your local care journey grows.',
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
              'Unable to load care timeline',
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
              onPressed: controller.fetchTimeline,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineSections() {
    final now = DateTime.now();
    final todayItems = <CareTimelineItem>[];
    final upcomingItems = <CareTimelineItem>[];
    final recentItems = <CareTimelineItem>[];

    for (final item in controller.visibleItems) {
      if (_isSameDay(item.timestamp, now)) {
        todayItems.add(item);
      } else if (item.timestamp.isAfter(now)) {
        upcomingItems.add(item);
      } else {
        recentItems.add(item);
      }
    }

    final sections = <Widget>[];
    if (todayItems.isNotEmpty) {
      sections.add(_buildSectionHeader('Today', todayItems.length));
      sections.addAll(todayItems.map(_buildTimelineItem));
    }
    if (upcomingItems.isNotEmpty) {
      sections.add(_buildSectionHeader('Upcoming', upcomingItems.length));
      sections.addAll(upcomingItems.map(_buildTimelineItem));
    }
    if (recentItems.isNotEmpty) {
      sections.add(_buildSectionHeader('Recent', recentItems.length));
      sections.addAll(recentItems.map(_buildTimelineItem));
    }
    return sections;
  }

  Widget _buildSectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kBlueColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String? _secondaryActionLabel(CareTimelineItem item) {
    switch (item.type) {
      case 'appointment':
      case 'reminder':
        return 'Messages';
      case 'consultation':
        return 'All consultations';
      case 'prescription':
      case 'medication':
        return 'All prescriptions';
      case 'review':
        return 'Reviews';
      default:
        return null;
    }
  }

  String? _secondaryActionRoute(CareTimelineItem item) {
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
        return null;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'consultation':
        return Icons.videocam_outlined;
      case 'prescription':
      case 'medication':
        return Icons.medication_outlined;
      case 'review':
        return Icons.star_outline;
      case 'appointment':
      case 'reminder':
        return Icons.calendar_today_outlined;
      default:
        return Icons.timeline;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'consultation':
        return Colors.deepPurple;
      case 'prescription':
      case 'medication':
        return Colors.teal;
      case 'review':
        return kOrangeColor;
      case 'appointment':
      case 'reminder':
        return kBlueColor;
      default:
        return Colors.grey;
    }
  }
}
