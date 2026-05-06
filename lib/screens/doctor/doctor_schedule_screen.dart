import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorScheduleScreen extends StatefulWidget {
  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final Map<String, bool> _workingDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 30; // minutes
  int _breakDuration = 10; // minutes

  final List<String> _blockedDates = [];

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schedule saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Manage Schedule',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Working Hours
              Text(
                'Working Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 16),
              Container(
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
                  children: [
                    // Start Time
                    _buildTimeRow(
                      'Start Time',
                      _formatTime(_startTime),
                      () => _pickTime(true),
                    ),
                    Divider(height: 24),
                    // End Time
                    _buildTimeRow(
                      'End Time',
                      _formatTime(_endTime),
                      () => _pickTime(false),
                    ),
                    Divider(height: 24),
                    // Slot Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Slot Duration',
                          style: TextStyle(
                            fontSize: 14,
                            color: kTitleTextColor,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _slotDuration,
                          underline: SizedBox(),
                          items: [15, 20, 30, 45, 60].map((min) {
                            return DropdownMenuItem(
                              value: min,
                              child: Text(
                                '$min min',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kBlueColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _slotDuration = value ?? 30;
                            });
                          },
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    // Break Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Break Between Slots',
                          style: TextStyle(
                            fontSize: 14,
                            color: kTitleTextColor,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _breakDuration,
                          underline: SizedBox(),
                          items: [0, 5, 10, 15, 20].map((min) {
                            return DropdownMenuItem(
                              value: min,
                              child: Text(
                                '$min min',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kBlueColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _breakDuration = value ?? 10;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Working Days
              Text(
                'Working Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
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
                  children: _workingDays.entries.map((entry) {
                    return SwitchListTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: kTitleTextColor,
                        ),
                      ),
                      value: entry.value,
                      activeThumbColor: kBlueColor,
                      onChanged: (value) {
                        setState(() {
                          _workingDays[entry.key] = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 24),

              // Blocked Dates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Blocked Dates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTitleTextColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        final formatted =
                            '${date.day}/${date.month}/${date.year}';
                        if (!_blockedDates.contains(formatted)) {
                          setState(() {
                            _blockedDates.add(formatted);
                          });
                        }
                      }
                    },
                    icon: Icon(Icons.add, color: kBlueColor, size: 20),
                    label: Text(
                      'Add Date',
                      style: TextStyle(color: kBlueColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_blockedDates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No blocked dates',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTitleTextColor.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ..._blockedDates.map((date) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.block, color: Color(0xffFF6B6B), size: 20),
                          SizedBox(width: 12),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              color: kTitleTextColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          setState(() {
                            _blockedDates.remove(date);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: MaterialButton(
                  onPressed: _saveSchedule,
                  color: kBlueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Save Schedule',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: kTitleTextColor,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kBlueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kBlueColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
