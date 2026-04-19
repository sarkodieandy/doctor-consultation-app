import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailScreen extends StatelessWidget {
  final DoctorModel doctor;

  const DetailScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final meta = patientDoctorMetaFor(doctor);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Doctor Profile',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundImage: doctor.imageProvider,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    doctor.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTitleTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${doctor.specialty} • ${meta.city}, ${meta.region}',
                    style: TextStyle(
                      color: kBlueColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: meta.trustBadges
                        .map(
                          (badge) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: kBlueColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kBlueColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.star,
                          '${doctor.rating}',
                          'Rating',
                          kYellowColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.work_outline,
                          doctor.experience,
                          'Experience',
                          kBlueColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.payments_outlined,
                          'GHS ${doctor.consultationFee.toStringAsFixed(0)}',
                          'Fee',
                          kOrangeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              'About Doctor',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.description,
                    style: TextStyle(
                      height: 1.6,
                      color: kTitleTextColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(Icons.local_hospital_outlined, doctor.hospital),
                  _buildInfoRow(Icons.access_time, meta.nextAvailable),
                  _buildInfoRow(Icons.chat_outlined, meta.responseTime),
                  _buildInfoRow(Icons.translate, meta.languages.join(' • ')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Care Focus',
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: meta.focusAreas
                    .map(
                      (area) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          area,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kTitleTextColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Consultation Options',
              Column(
                children: meta.consultationModes
                    .map(
                      (mode) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: kOrangeColor.withOpacity(0.12),
                              child: Icon(
                                mode == 'Video'
                                    ? Icons.videocam_outlined
                                    : mode == 'Voice'
                                        ? Icons.call_outlined
                                        : Icons.chat_bubble_outline,
                                size: 16,
                                color: kOrangeColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$mode consultation available for follow-up and routine check-ins.',
                                style: TextStyle(
                                  color: kTitleTextColor.withOpacity(0.72),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/booking', arguments: doctor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrangeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Book Appointment',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTitleTextColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: kTitleTextColor.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kBlueColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: kTitleTextColor.withOpacity(0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
