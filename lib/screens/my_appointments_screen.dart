import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAppointmentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppointmentController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchUserAppointments();
      controller.fetchUpcomingAppointments();
    });

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          'My Appointments',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: InkWell(
          onTap: () => Get.back(),
          child: Icon(Icons.arrow_back, color: kTitleTextColor),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(kBlueColor),
                ),
              )
            : controller.appointments.isEmpty
                ? _buildEmptyState(context)
                : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upcoming Appointments
                          if (controller.upcomingAppointments.isNotEmpty) ...[
                            Text(
                              'Upcoming Appointments',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: kTitleTextColor,
                              ),
                            ),
                            SizedBox(height: 15),
                            ...controller.upcomingAppointments.map((apt) {
                              return _buildAppointmentCard(context, apt, true);
                            }).toList(),
                            SizedBox(height: 30),
                          ],

                          // Completed & Cancelled
                          Text(
                            'Past Appointments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: kTitleTextColor,
                            ),
                          ),
                          SizedBox(height: 15),
                          ...controller.appointments
                              .where((apt) => !apt.isUpcoming)
                              .map((apt) {
                            return _buildAppointmentCard(context, apt, false);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: kBlueColor.withOpacity(0.3)),
          SizedBox(height: 20),
          Text(
            'No Appointments Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Book your first appointment with a doctor',
            style: TextStyle(
              fontSize: 14,
              color: kTitleTextColor.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 30),
          MaterialButton(
            onPressed: () {
              // TODO: Navigate to home/doctors list
            },
            color: kOrangeColor,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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

  Widget _buildAppointmentCard(
    BuildContext context,
    dynamic appointment,
    bool isUpcoming,
  ) {
    final statusColor = isUpcoming ? kBlueColor : kTitleTextColor.withOpacity(0.5);
    final statusText =
        isUpcoming ? 'Confirmed' : (appointment.isCancelled ? 'Cancelled' : 'Completed');

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
                child: Image.asset(
                  appointment.doctorImage,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 15),
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
                    SizedBox(height: 5),
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: kTitleTextColor.withOpacity(0.1)),
          SizedBox(height: 15),
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
                    '\$${appointment.consultationFee.toStringAsFixed(2)}',
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
          if (isUpcoming) ...[
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.find<AppointmentController>()
                          .cancelAppointment(appointment.id);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: kOrangeColor),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: kOrangeColor),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      // TODO: Start consultation
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
            SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: () {
                  // TODO: Show review dialog
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
        ],
      ),
    );
  }
}
