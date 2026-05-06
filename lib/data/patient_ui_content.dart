import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:flutter/material.dart';

class PatientDoctorMeta {
  final String city;
  final String region;
  final String nextAvailable;
  final String responseTime;
  final List<String> languages;
  final List<String> consultationModes;
  final List<String> focusAreas;
  final List<String> trustBadges;

  const PatientDoctorMeta({
    required this.city,
    required this.region,
    required this.nextAvailable,
    required this.responseTime,
    required this.languages,
    required this.consultationModes,
    required this.focusAreas,
    required this.trustBadges,
  });
}

class PatientHighlight {
  final String title;
  final String subtitle;
  final String eyebrow;
  final String imageUrl;
  final IconData icon;
  final Color color;

  const PatientHighlight({
    required this.title,
    required this.subtitle,
    required this.eyebrow,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });
}

class PatientCareProgram {
  final String title;
  final String subtitle;
  final String actionLabel;
  final String imageUrl;
  final IconData icon;
  final Color color;

  const PatientCareProgram({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });
}

const List<String> patientRegions = [
  'All Ghana',
  'Greater Accra',
  'Ashanti',
  'Northern',
  'Western',
];

const List<String> patientLanguages = [
  'Any language',
  'English',
  'Twi',
  'Ga',
  'Ewe',
];

const List<String> patientConsultationModes = [
  'Any mode',
  'Video',
  'Voice',
  'Chat',
];

const List<String> patientIntakeReasons = [
  'Follow-up review',
  'New symptoms',
  'Medication refill',
  'Lab result review',
  'Second opinion',
  'Child health concern',
];

const List<String> patientSymptomsChecklist = [
  'Fever or chills',
  'Shortness of breath',
  'Persistent pain',
  'Dizziness',
  'Medication reaction',
  'Poor sleep',
];

const List<String> patientConsultationPrepItems = [
  'Bring NHIS or ID details',
  'Keep recent lab reports ready',
  'Prepare current medications',
  'Note symptom timeline',
];

const List<String> patientQuickReplies = [
  'I have uploaded my lab results.',
  'Can we keep this as a follow-up review?',
  'I need help understanding my dosage.',
  'Please share the next available slot.',
];

const List<String> patientReviewTags = [
  'clear explanation',
  'helpful follow-up',
  'respectful care',
  'fast response',
  'good with children',
  'easy medication plan',
];

const List<String> patientPharmacyServices = [
  'Pickup from nearby pharmacy',
  'Same-day delivery in Accra',
  'Dose reminder setup',
  'Call pharmacist for counselling',
];

const List<PatientHighlight> patientHomeHighlights = [
  PatientHighlight(
    title: 'Licensed doctors',
    subtitle: 'Verified profiles with care focus and response times.',
    eyebrow: 'Trusted access',
    imageUrl: 'assets/images/doctorbg.png',
    icon: Icons.verified_user_outlined,
    color: Colors.green,
  ),
  PatientHighlight(
    title: 'MoMo-friendly care',
    subtitle: 'Consultations remain ready for mobile money flows later.',
    eyebrow: 'Flexible payments',
    imageUrl: 'assets/images/detail_illustration.png',
    icon: Icons.account_balance_wallet_outlined,
    color: Colors.teal,
  ),
  PatientHighlight(
    title: 'Ghana coverage',
    subtitle: 'Browse doctors by region, language, and consultation mode.',
    eyebrow: 'Across regions',
    imageUrl: 'assets/images/onboarding_illustration.png',
    icon: Icons.public_outlined,
    color: Colors.deepOrange,
  ),
];

const List<PatientCareProgram> patientCarePrograms = [
  PatientCareProgram(
    title: 'Maternal Care',
    subtitle: 'Antenatal follow-ups, postpartum checks, and nutrition prompts.',
    actionLabel: 'Track visits',
    imageUrl: 'assets/images/doctor1.png',
    icon: Icons.pregnant_woman_outlined,
    color: Colors.pink,
  ),
  PatientCareProgram(
    title: 'Chronic Care',
    subtitle: 'Blood pressure, diabetes, and medication adherence support.',
    actionLabel: 'View plan',
    imageUrl: 'assets/images/heart surg.jpeg',
    icon: Icons.monitor_heart_outlined,
    color: Colors.red,
  ),
  PatientCareProgram(
    title: 'Family Health',
    subtitle: 'Keep children and dependants organised in one care routine.',
    actionLabel: 'Add member',
    imageUrl: 'assets/images/doctor2.png',
    icon: Icons.family_restroom_outlined,
    color: Colors.blue,
  ),
];

final Map<String, PatientDoctorMeta> _patientDoctorMetaById = {
  'doctor_1': const PatientDoctorMeta(
    city: 'Accra',
    region: 'Greater Accra',
    nextAvailable: 'Today, 4:30 PM',
    responseTime: 'Replies within 10 min',
    languages: ['English', 'Twi'],
    consultationModes: ['Video', 'Chat'],
    focusAreas: ['Hypertension', 'Chest pain', 'Routine reviews'],
    trustBadges: ['Licensed', 'Follow-up friendly', 'MoMo ready'],
  ),
  'doctor_2': const PatientDoctorMeta(
    city: 'Kumasi',
    region: 'Ashanti',
    nextAvailable: 'Tomorrow, 9:00 AM',
    responseTime: 'Replies within 20 min',
    languages: ['English', 'Twi'],
    consultationModes: ['Video', 'Voice'],
    focusAreas: ['Child wellness', 'Vaccines', 'Nutrition'],
    trustBadges: ['Paediatric care', 'Weekend slots', 'Trusted by parents'],
  ),
  'doctor_3': const PatientDoctorMeta(
    city: 'Tamale',
    region: 'Northern',
    nextAvailable: 'Today, 6:00 PM',
    responseTime: 'Replies within 15 min',
    languages: ['English', 'Dagbani'],
    consultationModes: ['Voice', 'Chat'],
    focusAreas: ['General symptoms', 'Medication review', 'Referrals'],
    trustBadges: ['Same-day triage', 'Referral aware', 'Low-bandwidth care'],
  ),
};

PatientDoctorMeta patientDoctorMetaFor(DoctorModel doctor) {
  return _patientDoctorMetaById[doctor.id] ??
      PatientDoctorMeta(
        city: doctor.hospital.isEmpty ? 'Accra' : doctor.hospital,
        region: 'Greater Accra',
        nextAvailable: 'Next available tomorrow',
        responseTime: 'Replies within 30 min',
        languages: const ['English'],
        consultationModes: const ['Video', 'Chat'],
        focusAreas: [doctor.specialty, 'Routine review', 'Follow-up care'],
        trustBadges: const [
          'Verified profile',
          'Digital records',
          'MoMo ready'
        ],
      );
}

Color patientStatusColor(String? status) {
  switch (status) {
    case 'high':
      return Colors.red;
    case 'low':
      return kYellowColor;
    default:
      return Colors.green;
  }
}
