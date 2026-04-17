import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/health_record_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HealthRecordsScreen extends StatelessWidget {
  final controller = Get.find<HealthRecordController>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          elevation: 0,
          title: Text(
            'Health Records',
            style: TextStyle(
              color: kTitleTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: kOrangeColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kOrangeColor,
            tabs: [
              Tab(text: 'Vitals'),
              Tab(text: 'Lab Reports'),
              Tab(text: 'Allergies'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVitalsTab(),
            _buildLabReportsTab(),
            _buildAllergiesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsTab() {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Latest vitals summary
            Obx(
              () {
                final vitals = controller.latestVitals;
                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildVitalCard('Heart Rate', vitals['heart_rate'] ?? '--',
                        'bpm', kBlueColor),
                    _buildVitalCard('BP', vitals['blood_pressure'] ?? '--',
                        'mmHg', kOrangeColor),
                    _buildVitalCard('Temp', vitals['temperature'] ?? '--', '°F',
                        kYellowColor),
                    _buildVitalCard(
                        'Weight', vitals['weight'] ?? '--', 'kg', kBlueColor),
                  ],
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              'All Vital Signs',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 12),
            ...controller.vitalSigns.map((vital) {
              return _buildRecordCard(vital);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildLabReportsTab() {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            ...controller.labReports.map((report) {
              return _buildRecordCard(report);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAllergiesTab() {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            ...controller.allergies.map((allergy) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          allergy.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      allergy.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: kTitleTextColor,
                      ),
                    ),
                    if (allergy.notes != null) ...[
                      SizedBox(height: 8),
                      Text(
                        allergy.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildVitalCard(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(dynamic record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: kTitleTextColor,
                ),
              ),
              Text(
                '${record.value} ${record.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: kBlueColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (record.normalRange != null) ...[
            Text(
              'Normal: ${record.normalRange}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
          ],
          Text(
            DateFormat('MMM dd, yyyy').format(record.recordDate),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
