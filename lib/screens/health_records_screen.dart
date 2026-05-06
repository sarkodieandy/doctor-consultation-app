import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/health_record_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HealthRecordsScreen extends StatefulWidget {
  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  late HealthRecordController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HealthRecordController>();
  }

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
            _buildVitalsTab(context),
            _buildLabReportsTab(),
            _buildAllergiesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsTab(BuildContext context) {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
        }

        if (controller.errorMessage.value != null) {
          return _buildErrorState();
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildRecordsOverview(),
            SizedBox(height: 16),
            _buildHealthVaultCard(),
            SizedBox(height: 16),
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
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: patientConsultationPrepItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.folder_open_outlined,
                                size: 16, color: kBlueColor),
                            SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: 16),
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
            _buildHealthVaultCard(),
            SizedBox(height: 16),
            _buildSectionInfo(
              'Lab reports stay ready for future visits',
              'Upload controls and structured patient record views are ready for UI review.',
            ),
            SizedBox(height: 16),
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
            _buildHealthVaultCard(),
            SizedBox(height: 16),
            _buildSectionInfo(
              'Allergy reminders',
              'Keep severe reactions visible so every future consultation starts with the right safety context.',
            ),
            SizedBox(height: 16),
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

  Widget _buildHealthVaultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_special_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Vault',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep your vitals, reports, and allergy records up to date for every visit.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  color: patientStatusColor(record.status),
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
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              record.notes!,
              style: TextStyle(
                fontSize: 12,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
          ],
        ],
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
              'Unable to load health records',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kTitleTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                color: kTitleTextColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: controller.fetchAllRecords,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsOverview() {
    final abnormalCount =
        controller.allRecords.where((record) => record.isAbnormal).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewColumn(
              '${controller.allRecords.length}',
              'Records',
            ),
          ),
          Expanded(
            child: _buildOverviewColumn(
              '${controller.labReports.length}',
              'Reports',
            ),
          ),
          Expanded(
            child: _buildOverviewColumn(
              '$abnormalCount',
              'Watchlist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kBlueColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kTitleTextColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionInfo(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              height: 1.4,
              color: kTitleTextColor.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }
}
