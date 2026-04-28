import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with TickerProviderStateMixin {
  late AppointmentController _appointmentController;
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _appointmentController = Get.find<AppointmentController>();
    _tabController = TabController(length: 4, vsync: this);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appointmentController.fetchDoctorAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<AppointmentModel> _filterByStatus(
    List<AppointmentModel> appointments,
    String status,
  ) {
    if (status == 'all') return appointments;
    return appointments.where((a) => a.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: kWhiteColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.menu, color: kTitleTextColor),
              onPressed: () {
                setState(() {
                  _isSidebarOpen = true;
                });
              },
            ),
            title: Text(
              'Appointments',
              style: TextStyle(
                color: kTitleTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.dashboard, color: kTitleTextColor),
                onPressed: () => Get.toNamed('/doctor-home'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: Container(
                color: kWhiteColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: kBlueColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: kBlueColor,
                  indicatorWeight: 3,
                  labelStyle:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Confirmed'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),
          ),
          body: Obx(() {
            final appointments = _appointmentController.doctorAppointments;

            if (_appointmentController.isLoading.value &&
                appointments.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: kBlueColor),
              );
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentList(appointments, 'all'),
                  _buildAppointmentList(appointments, 'pending'),
                  _buildAppointmentList(appointments, 'confirmed'),
                  _buildAppointmentList(appointments, 'completed'),
                ],
              ),
            );
          }),
        ),
        if (_isSidebarOpen)
          SidebarDrawer(
            onClose: () {
              setState(() {
                _isSidebarOpen = false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildAppointmentList(
    List<AppointmentModel> appointments,
    String status,
  ) {
    final filtered = _filterByStatus(appointments, status);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.event_busy,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No ${status == 'all' ? '' : '$status '}appointments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTitleTextColor.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Come back later',
              style: TextStyle(
                fontSize: 13,
                color: kTitleTextColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final apt = filtered[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildAppointmentCard(apt, index),
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, int index) {
    final status = appointment.status;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = kOrangeColor;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = kBlueColor;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Color(0xffFF6B6B);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar with gradient
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [statusColor, statusColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName.isNotEmpty
                          ? appointment.patientName
                          : 'Patient #${appointment.userId}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      appointment.speciality.isNotEmpty
                          ? appointment.speciality
                          : 'Appointment',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTitleTextColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),

          // Time and date info
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: kBlueColor),
                    SizedBox(width: 6),
                    Text(
                      appointment.formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: kTitleTextColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: kOrangeColor),
                    SizedBox(width: 6),
                    Text(
                      appointment.timeSlot,
                      style: TextStyle(
                        fontSize: 13,
                        color: kTitleTextColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action buttons for pending appointments
          if (status == 'pending') ...[
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _appointmentController.rejectAppointment(
                        appointment.id,
                        appointment.doctorId,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Color(0xffFF6B6B),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xffFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _appointmentController.approveAppointment(
                        appointment.id,
                        appointment.doctorId,
                        appointment.doctorName,
                        appointment.doctorImage,
                        appointment.userId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.w600,
                      ),
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
}
