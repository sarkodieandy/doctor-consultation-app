import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/prescription_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PrescriptionsScreen extends StatelessWidget {
  final controller = Get.find<PrescriptionController>();

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
            labelColor: kOrangeColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kOrangeColor,
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
    return Obx(
      () {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: kOrangeColor),
          );
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
            ...controller.activePrescriptions.map((prescription) {
              return _buildPrescriptionCard(prescription, true);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab() {
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
            ...controller.completedPrescriptions.map((prescription) {
              return _buildPrescriptionCard(prescription, false);
            }).toList(),
          ],
        );
      },
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
                color: isActive
                    ? kBlueColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
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
                            color: kTitleTextColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy')
                              .format(prescription.prescribedDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green : Colors.grey[600],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
          color: kBlueColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: kBlueColor, size: 18),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: kBlueColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
          icon: Icon(Icons.arrow_back, color: kTitleTextColor),
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
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              prescription.isActive ? 'Active' : 'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: prescription.isActive
                                    ? Colors.green
                                    : Colors.grey[600],
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
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kSearchBackgroundColor),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dosage: ${medicine.dosage}',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Frequency: ${medicine.frequency}',
                          style: TextStyle(fontSize: 13),
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
                  color: kYellowColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kYellowColor.withOpacity(0.3)),
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
