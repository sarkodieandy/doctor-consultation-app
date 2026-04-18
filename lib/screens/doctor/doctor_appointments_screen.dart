import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Mock appointment data
  final List<Map<String, dynamic>> _appointments = [
    {
      'patient': 'Kwame Mensah',
      'time': '10:00 AM',
      'date': 'Today',
      'type': 'General Checkup',
      'status': 'pending',
    },
    {
      'patient': 'Ama Serwaa',
      'time': '11:00 AM',
      'date': 'Today',
      'type': 'Follow-up Visit',
      'status': 'confirmed',
    },
    {
      'patient': 'Kofi Asante',
      'time': '2:00 PM',
      'date': 'Today',
      'type': 'Consultation',
      'status': 'confirmed',
    },
    {
      'patient': 'Yaa Boateng',
      'time': '9:00 AM',
      'date': 'Tomorrow',
      'type': 'Skin Checkup',
      'status': 'pending',
    },
    {
      'patient': 'Esi Ampofo',
      'time': '3:00 PM',
      'date': 'Yesterday',
      'type': 'Consultation',
      'status': 'completed',
    },
    {
      'patient': 'Nana Yaw',
      'time': '4:00 PM',
      'date': 'Yesterday',
      'type': 'Follow-up',
      'status': 'cancelled',
    },
  ];

  List<Map<String, dynamic>> _filterByStatus(String status) {
    if (status == 'all') return _appointments;
    return _appointments.where((a) => a['status'] == status).toList();
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
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList('all'),
                _buildAppointmentList('pending'),
                _buildAppointmentList('confirmed'),
                _buildAppointmentList('completed'),
              ],
            ),
          ),
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

  Widget _buildAppointmentList(String status) {
    final filtered = _filterByStatus(status);

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
              'No ${status} appointments',
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
          child: _buildAppointmentCard(apt),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] as String;
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
                      appointment['patient'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      appointment['type'],
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
                      appointment['date'],
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
                      appointment['time'],
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
                    onPressed: () {
                      setState(() {
                        appointment['status'] = 'cancelled';
                      });
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
                    onPressed: () {
                      setState(() {
                        appointment['status'] = 'confirmed';
                      });
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
