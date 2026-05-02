import 'dart:async';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/services/ui_data_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selected = {};
  final _notesController = TextEditingController();
  bool _showTriage = false;

  static const _symptoms = [
    'Fever',
    'Headache',
    'Cough',
    'Chest pain',
    'Skin rash',
    'Stomach pain',
    'Dizziness',
    'Back pain',
  ];

  // Rule-based triage logic
  _TriageResult _computeTriage() {
    final urgent = _selected.contains('Chest pain') || _selected.length >= 4;
    final skinOnly = _selected.length == 1 && _selected.contains('Skin rash');
    if (urgent) {
      return _TriageResult(
        severity: 'High',
        severityColor: const Color(0xffE53935),
        specialty: 'General Practitioner / Emergency',
        careType: 'Urgent in-person consultation',
        estimatedWait: '< 30 minutes',
        icon: Icons.emergency_outlined,
        summary:
            'One or more of your symptoms indicate a condition that benefits from prompt medical review. KazHealth recommends booking an urgent in-person visit.',
      );
    } else if (skinOnly) {
      return _TriageResult(
        severity: 'Low',
        severityColor: const Color(0xff2E7D32),
        specialty: 'Dermatologist',
        careType: 'Video consultation',
        estimatedWait: '1 – 2 hours',
        icon: Icons.healing_outlined,
        summary:
            'Your reported symptom is commonly assessed via photo-based video review. A dermatology video consult is the recommended next step.',
      );
    } else if (_selected.length <= 2) {
      return _TriageResult(
        severity: 'Mild',
        severityColor: const Color(0xffF57F17),
        specialty: 'General Practitioner',
        careType: 'Chat or video consultation',
        estimatedWait: '2 – 4 hours',
        icon: Icons.chat_bubble_outline_rounded,
        summary:
            'Your symptoms suggest a mild condition. A remote GP chat or video consult can guide you to the right medication or follow-up plan.',
      );
    } else {
      return _TriageResult(
        severity: 'Moderate',
        severityColor: const Color(0xffE65100),
        specialty: 'General Practitioner',
        careType: 'In-person or video consultation',
        estimatedWait: '1 – 3 hours',
        icon: Icons.medical_information_outlined,
        summary:
            'Multiple symptoms are flagged. KazHealth recommends a same-day consultation to rule out overlapping conditions.',
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _selected.contains('Chest pain') || _selected.length >= 4;
    if (_showTriage) {
      final triage = _computeTriage();
      return _KazScaffold(
        title: 'Triage Assessment',
        subtitle: 'KazHealth care recommendation',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity badge row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: triage.severityColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: triage.severityColor.withOpacity(0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: triage.severityColor.withOpacity(0.15),
                        child: Icon(triage.icon,
                            color: triage.severityColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Severity level',
                            style: TextStyle(
                                color: kSearchTextColor, fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: triage.severityColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              triage.severity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    triage.summary,
                    style: TextStyle(
                        color: kTitleTextColor, height: 1.5, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Assessment rows
            _InfoRow(label: 'Suggested care', value: triage.careType),
            _InfoRow(label: 'Specialist', value: triage.specialty),
            _InfoRow(label: 'Estimated wait', value: triage.estimatedWait),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoRow(label: 'Symptoms flagged', value: _selected.join(', ')),
            ],
            const SizedBox(height: 18),
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSearchBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: kBlueColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a UI preview. Triage logic will be connected to clinical AI in the live build.',
                      style: TextStyle(
                          color: kSearchTextColor, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryAction(
              label: 'Continue to care services',
              icon: Icons.arrow_forward_rounded,
              onTap: () => Get.toNamed('/service-selection', arguments: {
                'symptoms': _selected.toList(),
                'notes': _notesController.text.trim(),
                'urgent': urgent,
              }),
            ),
            const SizedBox(height: 10),
            _SecondaryAction(
              label: 'Revise symptoms',
              icon: Icons.edit_outlined,
              onTap: () => setState(() => _showTriage = false),
            ),
          ],
        ),
      );
    }
    return _KazScaffold(
      title: 'Symptom Checker',
      subtitle: 'AI triage preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroPanel(
            icon: Icons.health_and_safety_outlined,
            title:
                urgent ? 'Urgent review recommended' : 'Tell us what you feel',
            body: urgent
                ? 'Your symptoms may need urgent attention. Book a doctor now or visit emergency care.'
                : 'Select symptoms and KazHealth will suggest the next care step.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _symptoms.map((symptom) {
              final active = _selected.contains(symptom);
              return FilterChip(
                selected: active,
                label: Text(symptom),
                selectedColor: kBlueColor.withOpacity(0.16),
                checkmarkColor: kBlueColor,
                onSelected: (_) {
                  setState(() {
                    active ? _selected.remove(symptom) : _selected.add(symptom);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _InputCard(
            child: TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText:
                    'Describe when it started, severity, and medications taken...',
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryAction(
            label: urgent ? 'Get triage assessment' : 'Get triage assessment',
            icon: Icons.health_and_safety_outlined,
            onTap: () {
              if (_selected.isEmpty) {
                Get.snackbar(
                  'No symptoms selected',
                  'Please select at least one symptom to continue.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: kWhiteColor,
                  colorText: kTitleTextColor,
                );
                return;
              }
              setState(() => _showTriage = true);
            },
          ),
        ],
      ),
    );
  }
}

class _TriageResult {
  const _TriageResult({
    required this.severity,
    required this.severityColor,
    required this.specialty,
    required this.careType,
    required this.estimatedWait,
    required this.icon,
    required this.summary,
  });

  final String severity;
  final Color severityColor;
  final String specialty;
  final String careType;
  final String estimatedWait;
  final IconData icon;
  final String summary;
}

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceOption('Doctor consultation', 'Video, chat, or in-person booking',
          Icons.medical_services_outlined, '/doctor-selection'),
      _ServiceOption(
          'Lab testing',
          'Preview test bundles, home pickup, and turnaround time',
          Icons.science_outlined,
          '/lab-selection'),
      _ServiceOption(
          'Pharmacy support',
          'Send prescription or request medication',
          Icons.local_pharmacy_outlined,
          '/prescriptions'),
      _ServiceOption('My appointments', 'Review bookings and next steps',
          Icons.calendar_month_outlined, '/appointments'),
      _ServiceOption('Care timeline', 'Track your post-visit plan',
          Icons.route_outlined, '/care-timeline'),
    ];
    return _KazScaffold(
      title: 'Service Selection',
      subtitle: 'Choose doctor, lab, or pharmacy',
      child: Column(
        children: [
          _HeroPanel(
            icon: Icons.touch_app_outlined,
            title: 'What do you need today?',
            body:
                'KazHealth routes you to the right service based on symptoms, availability, and care history.',
          ),
          const SizedBox(height: 18),
          ...services.map((item) => _ServiceTile(option: item)),
        ],
      ),
    );
  }
}

class LabSelectionScreen extends StatelessWidget {
  const LabSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const packages = [
      _LabPackage(
        title: 'Basic wellness panel',
        price: 'GHS 180',
        turnaround: '6 hours',
        details: 'CBC, malaria, urinalysis, and blood sugar check.',
      ),
      _LabPackage(
        title: 'Women’s health bundle',
        price: 'GHS 260',
        turnaround: 'Same day',
        details: 'Hormonal baseline, iron profile, and thyroid screening.',
      ),
      _LabPackage(
        title: 'Cardio risk panel',
        price: 'GHS 310',
        turnaround: '24 hours',
        details:
            'Lipid profile, fasting glucose, kidney function, and ECG prep.',
      ),
    ];

    return _KazScaffold(
      title: 'Lab Selection',
      subtitle: 'Browse test packages',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            icon: Icons.science_outlined,
            title: 'Lab booking preview',
            body:
                'This APK demonstrates how patients can browse tests, see pickup options, and confirm availability before backend scheduling is connected.',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBlueColor.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection options',
                  style: TextStyle(
                    color: kTitleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const _LabChoiceChip(label: 'Home pickup', active: true),
                const SizedBox(height: 8),
                const _LabChoiceChip(label: 'Walk-in partner lab'),
                const SizedBox(height: 8),
                const _LabChoiceChip(label: 'Corporate screening request'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...packages.map((package) => _LabPackageCard(package: package)),
          const SizedBox(height: 12),
          _InputCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Integration note',
                    style: TextStyle(
                      color: kTitleTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pricing, booking slots, payment confirmation, and result delivery are shown as UI preview only in this build.',
                    style: TextStyle(color: kSearchTextColor, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryAction(
            label: 'Reserve lab slot preview',
            icon: Icons.calendar_month_outlined,
            onTap: () => _showPreviewDialog(
              context,
              'Lab booking preview',
              'The scheduling backend is intentionally not connected in this APK. The client can still review the complete booking surface and interaction design.',
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final _dataService = UiDataService();
  final _queryController = TextEditingController();
  late Future<List<DoctorModel>> _future;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _future = _dataService.getDoctors();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _KazScaffold(
      title: 'Doctor Selection',
      subtitle: 'Browse and filter',
      child: Column(
        children: [
          _InputCard(
            child: TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search doctor or specialty',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All',
                'Cardiologist',
                'Dermatologist',
                'General Practice',
                'Dentist'
              ]
                  .map((filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          selectedColor: kBlueColor.withOpacity(0.16),
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<DoctorModel>>(
            future: _future,
            builder: (context, snapshot) {
              final doctors = (snapshot.data ?? []).where((doctor) {
                final query = _queryController.text.toLowerCase();
                final matchesQuery = query.isEmpty ||
                    doctor.name.toLowerCase().contains(query) ||
                    doctor.specialty.toLowerCase().contains(query);
                final matchesFilter =
                    _filter == 'All' || doctor.specialty == _filter;
                return matchesQuery && matchesFilter;
              }).toList();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: kBlueColor));
              }
              if (doctors.isEmpty) {
                return const _EmptyPanel(
                    message: 'No doctors match this filter.');
              }
              return Column(
                children: doctors
                    .map(
                      (doctor) => _DoctorSelectCard(
                        doctor: doctor,
                        onBook: () =>
                            Get.toNamed('/booking', arguments: doctor),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(Get.arguments ?? const {});
    return _KazScaffold(
      title: 'Booking Confirmation',
      subtitle: 'Success screen',
      child: Column(
        children: [
          _HeroPanel(
            icon: Icons.verified_rounded,
            title: 'Your booking is confirmed',
            body:
                'KazHealth has saved your appointment and sent the care details to your account.',
          ),
          const SizedBox(height: 16),
          _InfoRow(
              label: 'Doctor',
              value: args['doctor_name']?.toString() ?? 'Assigned doctor'),
          _InfoRow(
              label: 'Time',
              value: args['time']?.toString() ?? 'Upcoming slot'),
          _InfoRow(label: 'Payment', value: 'Confirmed'),
          const SizedBox(height: 18),
          _PrimaryAction(
            label: 'View my appointments',
            icon: Icons.calendar_month_outlined,
            onTap: () => Get.offNamed('/appointments'),
          ),
        ],
      ),
    );
  }
}

class TrackDoctorScreen extends StatefulWidget {
  const TrackDoctorScreen({super.key});

  @override
  State<TrackDoctorScreen> createState() => _TrackDoctorScreenState();
}

class _TrackDoctorScreenState extends State<TrackDoctorScreen>
    with SingleTickerProviderStateMixin {
  int _etaMinutes = 12;
  int _pingStep = 0; // 0–4 animates the doctor dot along the route
  Timer? _etaTimer;
  Timer? _pingTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Count down ETA every 60 s
    _etaTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        if (_etaMinutes > 1) _etaMinutes--;
      });
    });

    // Advance the ping dot every 3 s (demo speed)
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _pingStep = (_pingStep + 1) % 5;
      });
    });
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    _pingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(Get.arguments ?? const {});
    final doctorName = args['doctor_name']?.toString() ?? 'Dr. Kwame Asante';
    final specialty = args['specialty']?.toString() ?? 'General Practitioner';

    final arrived = _etaMinutes <= 0;

    return _KazScaffold(
      title: 'Track Doctor',
      subtitle: 'Live arrival update',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor info strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kBlueColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: kBlueColor.withOpacity(0.12),
                  child: Icon(Icons.person_rounded, color: kBlueColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName,
                          style: TextStyle(
                              color: kTitleTextColor,
                              fontWeight: FontWeight.w800)),
                      Text(specialty,
                          style:
                              TextStyle(color: kSearchTextColor, fontSize: 12)),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: arrived
                          ? const Color(0xff2E7D32)
                          : kBlueColor
                              .withOpacity(0.7 + _pulseController.value * 0.30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      arrived ? 'Arrived' : 'Live',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Route map
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kBlueColor.withOpacity(0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                        painter: _RouteMapPainter(progress: _pingStep / 4)),
                  ),
                  const Positioned(
                    left: 24,
                    top: 36,
                    child: _MapPin(icon: Icons.home_rounded, label: 'You'),
                  ),
                  const Positioned(
                    right: 32,
                    bottom: 42,
                    child: _MapPin(
                        icon: Icons.medical_services_rounded, label: 'Doctor'),
                  ),
                  // Moving doctor ping dot
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      // Interpolate along the bezier approximate positions
                      const positions = [
                        Offset(60, 80),
                        Offset(110, 105),
                        Offset(155, 108),
                        Offset(200, 100),
                        Offset(245, 90),
                      ];
                      final pos = positions[_pingStep.clamp(0, 4)];
                      return Positioned(
                        left: pos.dx - 10,
                        top: pos.dy - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kOrangeColor.withOpacity(
                                0.6 + _pulseController.value * 0.4),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: kOrangeColor.withOpacity(0.35),
                                  blurRadius: 8)
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ETA card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSearchBackgroundColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_outlined, color: kBlueColor, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arrived ? 'Doctor has arrived' : 'Estimated arrival',
                        style: TextStyle(color: kSearchTextColor, fontSize: 12),
                      ),
                      Text(
                        arrived ? 'Now' : '$_etaMinutes minutes',
                        style: TextStyle(
                          color: kTitleTextColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Progress steps
          _ProgressStep(title: 'Doctor assigned', done: true),
          _ProgressStep(title: 'Doctor confirmed route', done: _pingStep >= 1),
          _ProgressStep(title: 'Doctor is on the way', done: _pingStep >= 2),
          _ProgressStep(
              title: arrived
                  ? 'Doctor has arrived'
                  : 'Arrival estimate: $_etaMinutes min',
              done: arrived),
        ],
      ),
    );
  }
}

class ConsultationSummaryScreen extends StatelessWidget {
  const ConsultationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _KazScaffold(
      title: 'Consultation Summary',
      subtitle: 'Post-visit',
      child: Column(
        children: [
          _HeroPanel(
            icon: Icons.summarize_outlined,
            title: 'Visit summary ready',
            body:
                'Review diagnosis notes, medication instructions, and follow-up actions after your consultation.',
          ),
          const SizedBox(height: 16),
          const _InfoRow(
              label: 'Assessment', value: 'Mild upper respiratory symptoms'),
          const _InfoRow(
              label: 'Prescription', value: 'Available for download'),
          const _InfoRow(
              label: 'Follow-up', value: 'Check symptoms again in 48 hours'),
          const SizedBox(height: 18),
          _PrimaryAction(
            label: 'Open prescriptions',
            icon: Icons.picture_as_pdf_outlined,
            onTap: () => Get.toNamed('/prescriptions'),
          ),
          const SizedBox(height: 10),
          _SecondaryAction(
            label: 'Rate doctor',
            icon: Icons.star_border_rounded,
            onTap: () => Get.toNamed('/reviews'),
          ),
        ],
      ),
    );
  }
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool pushNotifications = true;
  bool appointmentReminders = true;
  bool mobileMoneyReceipts = true;

  @override
  Widget build(BuildContext context) {
    return _KazScaffold(
      title: 'Settings',
      subtitle: 'App preferences',
      child: Column(
        children: [
          _SettingsSwitch(
            title: 'Push notifications',
            subtitle: 'Booking alerts, reminders, and messages',
            value: pushNotifications,
            onChanged: (value) => setState(() => pushNotifications = value),
          ),
          _SettingsSwitch(
            title: 'Appointment reminders',
            subtitle: 'Notify me before upcoming visits',
            value: appointmentReminders,
            onChanged: (value) => setState(() => appointmentReminders = value),
          ),
          _SettingsSwitch(
            title: 'Payment receipts',
            subtitle: 'Send mobile money and card receipts',
            value: mobileMoneyReceipts,
            onChanged: (value) => setState(() => mobileMoneyReceipts = value),
          ),
        ],
      ),
    );
  }
}

class DoctorVerificationStatusScreen extends StatelessWidget {
  const DoctorVerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final hasDocument = (user?.licenseDocumentPath ?? '').isNotEmpty;
    final approved = user?.approvalStatus?.name == 'approved';
    return _KazScaffold(
      title: 'Verification Status',
      subtitle: 'Doctor onboarding',
      child: Column(
        children: [
          _HeroPanel(
            icon:
                approved ? Icons.verified_user_outlined : Icons.badge_outlined,
            title: approved ? 'You are verified' : 'Verification in progress',
            body: hasDocument
                ? 'Your license document is attached for KazHealth admin review.'
                : 'Upload a license document from your profile so the admin can approve your account.',
          ),
          const SizedBox(height: 16),
          _ProgressStep(title: 'Profile details completed', done: true),
          _ProgressStep(title: 'License document uploaded', done: hasDocument),
          _ProgressStep(title: 'Admin approval complete', done: approved),
          const SizedBox(height: 18),
          _PrimaryAction(
            label: 'Update doctor profile',
            icon: Icons.edit_outlined,
            onTap: () => Get.toNamed('/doctor-profile'),
          ),
        ],
      ),
    );
  }
}

class _KazScaffold extends StatelessWidget {
  const _KazScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: kTitleTextColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: kTitleTextColor, fontWeight: FontWeight.w800)),
            Text(subtitle,
                style: TextStyle(color: kSearchTextColor, fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: child,
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kBlueColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xff2E63DE)),
        boxShadow: [
          BoxShadow(
              color: kBlueColor.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 12))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.16),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.82), height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlueColor.withOpacity(0.14)),
      ),
      child: child,
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlueColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: kBlueColor,
          side: BorderSide(color: kBlueColor.withOpacity(0.25)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ServiceOption {
  const _ServiceOption(this.title, this.subtitle, this.icon, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _LabPackage {
  const _LabPackage({
    required this.title,
    required this.price,
    required this.turnaround,
    required this.details,
  });

  final String title;
  final String price;
  final String turnaround;
  final String details;
}

class _LabChoiceChip extends StatelessWidget {
  const _LabChoiceChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? kSearchBackgroundColor : const Color(0xffF7F9FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: active ? kBlueColor : kSearchTextColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? kCategoryTextColor : kTitleTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabPackageCard extends StatelessWidget {
  const _LabPackageCard({required this.package});

  final _LabPackage package;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBlueColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.title,
                  style: TextStyle(
                    color: kTitleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kSearchBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  package.price,
                  style: TextStyle(
                    color: kBlueColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            package.details,
            style: TextStyle(
              color: kSearchTextColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 16, color: kBlueColor),
              const SizedBox(width: 6),
              Text(
                'Turnaround ${package.turnaround}',
                style: TextStyle(
                  color: kCategoryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showPreviewDialog(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: kWhiteColor,
        title: Text(
          title,
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: kSearchTextColor, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: kBlueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.option});

  final _ServiceOption option;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.toNamed(option.route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: kBlueColor.withOpacity(0.12),
                  child: Icon(option.icon, color: kBlueColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.title,
                          style: TextStyle(
                              color: kTitleTextColor,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(option.subtitle,
                          style:
                              TextStyle(color: kSearchTextColor, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: kBlueColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorSelectCard extends StatelessWidget {
  const _DoctorSelectCard({required this.doctor, required this.onBook});

  final DoctorModel doctor;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBlueColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kBlueColor.withOpacity(0.12),
            backgroundImage: doctor.imageUrl.startsWith('http')
                ? NetworkImage(doctor.imageUrl)
                : null,
            child: doctor.imageUrl.startsWith('http')
                ? null
                : Icon(Icons.person, color: kBlueColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name,
                    style: TextStyle(
                        color: kTitleTextColor, fontWeight: FontWeight.w800)),
                Text(doctor.specialty,
                    style: TextStyle(color: kSearchTextColor, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                    'GHS ${doctor.consultationFee.toStringAsFixed(0)} · ${doctor.rating.toStringAsFixed(1)} rating',
                    style: TextStyle(
                        color: kBlueColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBook,
            style: ElevatedButton.styleFrom(
                backgroundColor: kBlueColor, foregroundColor: Colors.white),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: kWhiteColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: kSearchTextColor, fontWeight: FontWeight.w700)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: kTitleTextColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kWhiteColor, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: kTitleTextColor, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: kSearchTextColor, fontSize: 12)),
              ],
            ),
          ),
          Switch(
              value: value, activeThumbColor: kBlueColor, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.title, required this.done});

  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kWhiteColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done ? kBlueColor : kSearchTextColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: kTitleTextColor, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
            backgroundColor: kBlueColor,
            child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(color: kTitleTextColor, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter({this.progress = 0});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = kBlueColor.withOpacity(0.08)
      ..strokeWidth = 1;
    for (double x = 24; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Faded full route
    final fadedPaint = Paint()
      ..color = kBlueColor.withOpacity(0.20)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fullPath = Path()
      ..moveTo(54, 74)
      ..cubicTo(size.width * 0.35, 130, size.width * 0.55, 95, size.width - 72,
          size.height - 72);
    canvas.drawPath(fullPath, fadedPaint);

    // Highlighted travelled portion
    if (progress > 0) {
      final activePaint = Paint()
        ..color = kBlueColor
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final metrics = fullPath.computeMetrics().first;
      final travelled = metrics.extractPath(0, metrics.length * progress);
      canvas.drawPath(travelled, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter old) =>
      old.progress != progress;
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: kWhiteColor, borderRadius: BorderRadius.circular(18)),
      child: Text(message, style: TextStyle(color: kSearchTextColor)),
    );
  }
}
