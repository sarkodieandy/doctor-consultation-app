import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/prescription_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PrescriptionsScreen extends StatefulWidget {
  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  late PrescriptionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PrescriptionController>();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          elevation: 0,
          title: Text(
            'Prescriptions',
            style: TextStyle(
              color: kTitleTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: kBlueColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kBlueColor,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: kBlueColor),
        );
      }

      if (controller.errorMessage.value != null) {
        return _buildErrorState();
      }

      if (controller.activePrescriptions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined,
                  size: 60, color: Colors.grey[300]),
              SizedBox(height: 20),
              Text('No active prescriptions'),
            ],
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildPrescriptionOverview(
            activeCount: controller.activePrescriptions.length,
            completedCount: controller.completedPrescriptions.length,
          ),
          SizedBox(height: 16),
          _buildDoseReminderCard(),
          SizedBox(height: 16),
          ...controller.activePrescriptions.map((prescription) {
            return _buildPrescriptionCard(prescription, true);
          }).toList(),
        ],
      );
    });
  }

  Widget _buildHistoryTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: kBlueColor),
        );
      }

      if (controller.errorMessage.value != null) {
        return _buildErrorState();
      }

      return ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildPharmacySupportCard(),
          SizedBox(height: 16),
          ...controller.completedPrescriptions.map((prescription) {
            return _buildPrescriptionCard(prescription, false);
          }).toList(),
        ],
      );
    });
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
              'Unable to load prescriptions',
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
              onPressed: controller.fetchAllPrescriptions,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(dynamic prescription, bool isActive) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/prescription-detail', arguments: prescription);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
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
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? kBlueColor : Color(0xff2E5ED2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.doctorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kWhiteColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy')
                              .format(prescription.prescribedDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: kWhiteColor.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Color(0xff1F4FBF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: kWhiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${prescription.medicines.length} Medicine${prescription.medicines.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...prescription.medicines.take(2).map<Widget>((medicine) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• ${medicine.name} - ${medicine.dosage}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                  if (prescription.medicines.length > 2)
                    Text(
                      '+ ${prescription.medicines.length - 2} more',
                      style: TextStyle(
                        fontSize: 12,
                        color: kBlueColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 12),
                  Text(
                    prescription.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: kTitleTextColor.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (isActive)
                        _buildActionButton(
                          Icons.alarm_add_outlined,
                          'Remind Me',
                          () async {
                            final medicines = prescription.medicines;
                            if (medicines.isEmpty) {
                              return;
                            }
                            final success =
                                await controller.sendMedicineReminder(
                              prescription,
                              medicines.first,
                            );
                            if (success) {
                              Get.snackbar(
                                'Reminder Saved',
                                'Dose reminder added to notifications.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                        ),
                      _buildActionButton(
                        Icons.download,
                        'Download',
                        () => controller.downloadPrescription(prescription.id),
                      ),
                      _buildActionButton(
                        Icons.share,
                        'Share',
                        () => controller.sharePrescription(prescription.id, []),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kBlueColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: kWhiteColor, size: 18),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: kWhiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionOverview({
    required int activeCount,
    required int completedCount,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildOverviewStat('$activeCount', 'Active')),
          Expanded(child: _buildOverviewStat('$completedCount', 'Completed')),
          Expanded(
            child: _buildOverviewStat(
              '${patientPharmacyServices.length}',
              'Support',
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
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: kWhiteColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kWhiteColor.withOpacity(0.88),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacySupportCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffEFF4FF),
        border: Border.all(color: kBlueColor.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pharmacy Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 10),
          ...patientPharmacyServices.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.local_pharmacy_outlined,
                      size: 16, color: kBlueColor),
                  SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseReminderCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffEFF4FF),
        border: Border.all(color: kBlueColor.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dose Reminders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Save local reminders for active medicines so they appear in your notifications inbox during the day.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: kTitleTextColor.withOpacity(0.65),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.alarm_add_outlined, size: 16, color: kBlueColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap Remind Me on any active prescription to store a dose reminder locally.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrescriptionDetailScreen extends StatelessWidget {
  final controller = Get.find<PrescriptionController>();

  @override
  Widget build(BuildContext context) {
    final prescription = Get.arguments;

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
          'Prescription Details',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xffEFF4FF),
                border: Border.all(color: kBlueColor.withOpacity(0.22)),
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
                  Text(
                    'Prescribed By',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    prescription.doctorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Prescription Notes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    prescription.notes,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: kTitleTextColor.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(prescription.prescribedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: prescription.isActive
                                  ? Colors.green
                                  : Color(0xff1F4FBF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              prescription.isActive ? 'Active' : 'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: kWhiteColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Medicines',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 12),
            ...prescription.medicines.map<Widget>((medicine) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xffF3F7FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBlueColor.withOpacity(0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kTitleTextColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dosage: ${medicine.dosage}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Frequency: ${medicine.frequency}',
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Duration: ${medicine.duration} days',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Instructions: ${medicine.instructions}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      medicine.instructions,
                      style: TextStyle(
                        fontSize: 12,
                        color: kTitleTextColor.withOpacity(0.65),
                      ),
                    ),
                    if (prescription.isActive) ...[
                      SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final success = await controller.sendMedicineReminder(
                            prescription,
                            medicine,
                          );
                          if (success) {
                            Get.snackbar(
                              'Reminder Saved',
                              '${medicine.name} reminder added to notifications.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        icon: Icon(Icons.alarm_add_outlined, size: 18),
                        label: Text('Set Dose Reminder'),
                      ),
                    ],
                    if (medicine.sideEffects.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Possible side effects: ${medicine.sideEffects.join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTitleTextColor.withOpacity(0.58),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            if (prescription.notes != null) ...[
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kTitleTextColor,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xffEAF1FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBlueColor.withOpacity(0.25)),
                ),
                child: Text(
                  prescription.notes,
                  style: TextStyle(
                    fontSize: 13,
                    color: kTitleTextColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
