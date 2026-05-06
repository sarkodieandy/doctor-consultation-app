import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorCard extends StatelessWidget {
  final String _name;
  final String _description;
  final String _imageUrl;
  final Color _bgColor;

  DoctorCard(this._name, this._description, this._imageUrl, this._bgColor);

  @override
  Widget build(BuildContext context) {
    final doctor = DoctorModel(
      id: _name.toLowerCase().replaceAll(' ', '_'),
      name: _name,
      specialty: _description,
      description: _description,
      imageUrl: _imageUrl,
      consultationFee: 120,
      experience: '8 yrs',
      hospital: 'City Health Centre',
    );

    return InkWell(
      onTap: () {
        Get.to(
          () => DetailScreen(doctor: doctor),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            kBlueColor.withOpacity(0.06),
            kWhiteColor,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBlueColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: kBlueColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image(
                      image: doctor.imageProvider,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kTitleTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kTitleTextColor.withOpacity(0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge(
                              label: 'Live profile',
                              color: kBlueColor,
                            ),
                            _buildBadge(
                              label: doctor.experience,
                              color: _bgColor,
                            ),
                            _buildBadge(
                              label:
                                  'GHS ${doctor.consultationFee.toStringAsFixed(0)}',
                              color: kBlueColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                doctor.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kTitleTextColor.withOpacity(0.62),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: kBlueColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBlueColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_hospital_outlined,
                      size: 15,
                      color: kBlueColor.withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctor.hospital,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kTitleTextColor.withOpacity(0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: kBlueColor.withOpacity(0.24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: kBlueColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    final deepColor = Color.alphaBlend(
      Colors.black.withOpacity(0.18),
      color,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: deepColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: deepColor.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: deepColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
