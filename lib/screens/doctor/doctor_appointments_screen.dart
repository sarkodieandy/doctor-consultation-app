import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Appointments',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kBlueColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kBlueColor,
          labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('all'),
          _buildAppointmentList('pending'),
          _buildAppointmentList('confirmed'),
          _buildAppointmentList('completed'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final filtered = _filterByStatus(status);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'No $status appointments',
              style: TextStyle(
                fontSize: 16,
                color: kTitleTextColor.withOpacity(0.5),
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
        return _buildAppointmentCard(apt);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] as String;
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = kOrangeColor;
        break;
      case 'completed':
        statusColor = kBlueColor;
        break;
      case 'cancelled':
        statusColor = Color(0xffFF6B6B);
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kBlueColor.withOpacity(0.1),
                child: Icon(Icons.person, color: kBlueColor),
              ),
              SizedBox(width: 12),
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                appointment['date'],
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                appointment['time'],
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),

          // Action buttons for pending appointments
          if (status == 'pending') ...[
            SizedBox(height: 12),
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
                      side: BorderSide(color: Color(0xffFF6B6B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(color: Color(0xffFF6B6B)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        appointment['status'] = 'confirmed';
                      });
                    },
                    color: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(color: kWhiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Complete button for confirmed
          if (status == 'confirmed') ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: () {
                  setState(() {
                    appointment['status'] = 'completed';
                  });
                },
                color: kBlueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Mark Complete',
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
