import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAppointmentsScreen extends StatefulWidget {
  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late AppointmentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AppointmentController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchUserAppointments();
      _controller.fetchUpcomingAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBlueColor,
        elevation: 0,
        title: Text(
          'My Appointments',
          style: TextStyle(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: InkWell(
          onTap: () => Get.back(),
          child: Icon(Icons.arrow_back_ios_new, color: kWhiteColor),
        ),
      ),
      body: Obx(
        () {
          if (_controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(kBlueColor),
              ),
            );
          }
          if (_controller.errorMessage.value != null) {
            return _buildErrorState();
          }
          if (_controller.appointments.isEmpty) {
            return _buildEmptyState(context);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverview(_controller),
                  const SizedBox(height: 22),
                  _buildReminderHub(_controller),
                  const SizedBox(height: 22),
                  if (_controller.upcomingAppointments.isNotEmpty) ...[
                    Text(
                      'Upcoming Appointments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kTitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ..._controller.upcomingAppointments.map((apt) {
                      return _buildAppointmentCard(context, apt, true);
                    }).toList(),
                    const SizedBox(height: 26),
                  ],
                  Text(
                    'Past Appointments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kTitleTextColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ..._controller.appointments
                      .where((apt) => !apt.isUpcoming)
                      .map((apt) {
                    return _buildAppointmentCard(context, apt, false);
                  }).toList(),
                  const SizedBox(height: 20),
                  _buildCareTips(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview(AppointmentController controller) {
    final cancelledCount =
        controller.appointments.where((apt) => apt.isCancelled).length;
    final completedCount =
        controller.appointments.where((apt) => apt.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewStat(
              '${controller.upcomingAppointments.length}',
              'Upcoming',
            ),
          ),
          Container(width: 1, height: 36, color: kWhiteColor.withOpacity(0.25)),
          Expanded(
            child: _buildOverviewStat(
              '$completedCount',
              'Completed',
            ),
          ),
          Container(width: 1, height: 36, color: kWhiteColor.withOpacity(0.25)),
          Expanded(
            child: _buildOverviewStat(
              '$cancelledCount',
              'Cancelled',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label) {
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
        const SizedBox(height: 4),
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

  Widget _buildReminderHub(AppointmentController controller) {
    final nextAppointment = controller.upcomingAppointments.isNotEmpty
        ? controller.upcomingAppointments.first
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlueColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBlueColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications_outlined,
                    color: kWhiteColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Care Reminders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kTitleTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nextAppointment == null
                ? 'When you book your next visit, you can save local reminders and review them from notifications.'
                : 'Next: ${nextAppointment.doctorName} on ${nextAppointment.formattedDate} at ${nextAppointment.timeSlot}.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: kTitleTextColor.withOpacity(0.68),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  Icons.inbox_outlined,
                  'Inbox',
                  kBlueColor,
                  () => Get.toNamed('/notifications'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  Icons.timeline,
                  'Timeline',
                  const Color(0xff6C5CE7),
                  () => Get.toNamed('/care-timeline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  Icons.alarm_add_outlined,
                  'Remind',
                  kOrangeColor,
                  nextAppointment == null
                      ? null
                      : () async {
                          await controller.sendAppointmentReminder(
                            nextAppointment.id,
                            nextAppointment.doctorName,
                            nextAppointment.appointmentDate,
                          );
                          Get.snackbar(
                            'Reminder Saved',
                            'A local reminder was added to your notifications.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick Links row
          Row(
            children: [
              _buildQuickLink(
                  Icons.medication_outlined, 'Prescriptions', '/prescriptions'),
              const SizedBox(width: 10),
              _buildQuickLink(
                  Icons.videocam_outlined, 'Consultations', '/consultations'),
              const SizedBox(width: 10),
              _buildQuickLink(Icons.chat_bubble_outline, 'Chat', '/chat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.25) : color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: kWhiteColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink(IconData icon, String label, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Get.toNamed(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBlueColor.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: kBlueColor, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: kTitleTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to load appointments',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kTitleTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                _controller.fetchUserAppointments();
                _controller.fetchUpcomingAppointments();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today,
              size: 80, color: kBlueColor.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            'No Appointments Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Book your first appointment and keep the rest of your care journey here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: kTitleTextColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 30),
          MaterialButton(
            onPressed: () {
              Get.offNamed('/home');
            },
            color: kOrangeColor,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Find a Doctor',
              style: TextStyle(
                color: kWhiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorImage(String imageUrl) {
    const double size = 70;
    const fallback = 'assets/images/doctor1.png';
    if (imageUrl.trim().isEmpty) {
      return Image.asset(fallback,
          width: size, height: size, fit: BoxFit.cover);
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.asset(fallback,
          width: size, height: size, fit: BoxFit.cover);
    }
    return Image.asset(imageUrl, width: size, height: size, fit: BoxFit.cover);
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    dynamic appointment,
    bool isUpcoming,
  ) {
    final statusColor = isUpcoming
        ? kBlueColor
        : (appointment.isCancelled ? kOrangeColor : Colors.green);
    final statusText = isUpcoming
        ? 'Confirmed'
        : (appointment.isCancelled ? 'Cancelled' : 'Completed');

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildDoctorImage(appointment.doctorImage),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kTitleTextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      appointment.speciality,
                      style: TextStyle(
                        fontSize: 13,
                        color: kTitleTextColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kWhiteColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: kTitleTextColor.withOpacity(0.1)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: kTitleTextColor.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${appointment.formattedDate} • ${appointment.timeSlot}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: kTitleTextColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Consultation Fee',
                    style: TextStyle(
                      fontSize: 12,
                      color: kTitleTextColor.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'GHS ${appointment.consultationFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kOrangeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isUpcoming
                  ? 'Prepare your records, list your medications, and join the consultation on time.'
                  : appointment.isCancelled
                      ? 'This visit was cancelled. You can book another doctor or time from the home screen.'
                      : 'Review your prescription, save follow-up notes, and leave feedback if helpful.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: kTitleTextColor.withOpacity(0.68),
              ),
            ),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    onPressed: () async {
                      await Get.find<AppointmentController>()
                          .sendAppointmentReminder(
                        appointment.id,
                        appointment.doctorName,
                        appointment.appointmentDate,
                      );
                      Get.snackbar(
                        'Reminder Saved',
                        'This appointment reminder is now in your notifications.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    color: kBlueColor.withOpacity(0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: kBlueColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Remind Me',
                      style: TextStyle(
                          color: kBlueColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      Get.find<AppointmentController>()
                          .cancelAppointment(appointment.id);
                    },
                    color: kOrangeColor.withOpacity(0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: kOrangeColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: kOrangeColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      Get.toNamed('/consultations');
                    },
                    color: kBlueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Consult',
                      style: TextStyle(color: kWhiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (appointment.isCompleted && appointment.rating == null) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    onPressed: () async {
                      await Get.find<AppointmentController>().sendReviewRequest(
                        appointment.id,
                        appointment.doctorName,
                      );
                      Get.snackbar(
                        'Follow-up Saved',
                        'A review reminder was added to your notifications.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    color: kBlueColor.withOpacity(0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: kBlueColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Remind Me Later',
                      style: TextStyle(
                          color: kBlueColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      Get.toNamed('/write-review', arguments: appointment);
                    },
                    color: kOrangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Write a Review',
                      style: TextStyle(color: kWhiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCareTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlueColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBlueColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.checklist_outlined,
                    color: kWhiteColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Patient Checklist',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kTitleTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTip('Confirm your preferred language before the session.'),
          _buildTip('Keep any recent tests or prescriptions close by.'),
          _buildTip(
              'Use the review screen after completed visits to track care quality.'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: kBlueColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: kTitleTextColor.withOpacity(0.68)),
            ),
          ),
        ],
      ),
    );
  }
}
