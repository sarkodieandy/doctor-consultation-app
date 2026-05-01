import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/prescription_controller.dart';
import 'package:doctor_consultation_app/models/appointment_model.dart';
import 'package:doctor_consultation_app/models/prescription_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorPrescriptionWriterScreen extends StatefulWidget {
  const DoctorPrescriptionWriterScreen({super.key});

  @override
  State<DoctorPrescriptionWriterScreen> createState() =>
      _DoctorPrescriptionWriterScreenState();
}

class _DoctorPrescriptionWriterScreenState
    extends State<DoctorPrescriptionWriterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _medicineRows = <_MedicineInput>[_MedicineInput()];
  late final PrescriptionController _controller;

  AppointmentModel? get _appointment {
    final args = Get.arguments;
    if (args is AppointmentModel) return args;
    if (args is Map) {
      final data = Map<String, dynamic>.from(args);
      final appointmentId = (data['appointmentId'] ?? '').toString();
      final patientId = (data['patientId'] ?? '').toString();
      final doctorId = (data['doctorId'] ?? '').toString();
      if (appointmentId.isEmpty || patientId.isEmpty || doctorId.isEmpty) {
        return null;
      }
      return AppointmentModel(
        id: appointmentId,
        userId: patientId,
        doctorId: doctorId,
        doctorName:
            (data['doctorFullName'] ?? data['doctorName'] ?? '').toString(),
        doctorImage: (data['doctorAvatar'] ?? '').toString(),
        patientName:
            (data['patientFullName'] ?? data['patientName'] ?? '').toString(),
        patientAvatar: (data['patientAvatar'] ?? '').toString(),
        speciality: (data['speciality'] ?? 'Consultation').toString(),
        appointmentDate: DateTime.now(),
        timeSlot: 'Current call',
        consultationFee: 0,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<PrescriptionController>()
        ? Get.find<PrescriptionController>()
        : Get.put(PrescriptionController());
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final row in _medicineRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _sendPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    final appointment = _appointment;
    final doctor = AuthService().currentUser;
    if (appointment == null || doctor == null) {
      Get.snackbar('Prescription not sent', 'Open this from an appointment.');
      return;
    }

    final medicines = _medicineRows.map((row) {
      return Medicine(
        id: '',
        name: row.name.text.trim(),
        dosage: row.dosage.text.trim(),
        frequency: row.frequency.text.trim(),
        duration: int.tryParse(row.duration.text.trim()) ?? 1,
        instructions: row.instructions.text.trim(),
        sideEffects: row.sideEffects.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
      );
    }).toList();

    final prescription = PrescriptionModel(
      id: '',
      doctorId: doctor.id,
      doctorName: doctor.fullName,
      appointmentId: appointment.id,
      patientId: appointment.userId,
      prescribedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      medicines: medicines,
      notes: _notesController.text.trim(),
      status: 'active',
    );

    final success = await _controller.createPrescription(prescription);
    if (!mounted) return;
    if (success) {
      Get.snackbar(
        'Prescription sent',
        '${appointment.patientName.isEmpty ? 'Patient' : appointment.patientName} can now view and download it.',
        backgroundColor: kBlueColor,
        colorText: kWhiteColor,
      );
      Get.back();
    } else {
      Get.snackbar(
        'Prescription not sent',
        _controller.errorMessage.value ?? 'Please check the details and retry.',
      );
    }
  }

  void _addMedicine() {
    setState(() => _medicineRows.add(_MedicineInput()));
  }

  void _removeMedicine(int index) {
    if (_medicineRows.length == 1) return;
    setState(() {
      final row = _medicineRows.removeAt(index);
      row.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: Get.back,
        ),
        title: Text(
          'Send Prescription',
          style: TextStyle(color: kTitleTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PatientHeader(appointment: appointment),
            const SizedBox(height: 18),
            for (var index = 0; index < _medicineRows.length; index++) ...[
              _MedicineCard(
                index: index,
                input: _medicineRows[index],
                canRemove: _medicineRows.length > 1,
                onRemove: () => _removeMedicine(index),
              ),
              const SizedBox(height: 14),
            ],
            OutlinedButton.icon(
              onPressed: _addMedicine,
              icon: Icon(Icons.add_rounded, color: kBlueColor),
              label: Text('Add another medicine',
                  style: TextStyle(color: kBlueColor)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kBlueColor.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FieldShell(
              child: TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Clinical notes',
                  hintText: 'Diagnosis, follow-up advice, warning signs',
                ),
              ),
            ),
            const SizedBox(height: 22),
            Obx(() {
              return ElevatedButton.icon(
                onPressed:
                    _controller.isLoading.value ? null : _sendPrescription,
                icon: _controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text(
                  'Send to patient',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlueColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.appointment});

  final AppointmentModel? appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBlueColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment?.patientName.isNotEmpty == true
                      ? appointment!.patientName
                      : 'Selected patient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment == null
                      ? 'Open from doctor appointments'
                      : '${appointment!.formattedDate} at ${appointment!.timeSlot}',
                  style: TextStyle(color: Colors.white.withOpacity(0.78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.index,
    required this.input,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _MedicineInput input;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlueColor.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Medicine ${index + 1}',
                style: TextStyle(
                  color: kTitleTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.red,
                ),
            ],
          ),
          _TextField(controller: input.name, label: 'Medicine name'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _TextField(controller: input.dosage, label: 'Dosage')),
              const SizedBox(width: 10),
              Expanded(
                child: _TextField(
                  controller: input.duration,
                  label: 'Days',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TextField(controller: input.frequency, label: 'Frequency'),
          const SizedBox(height: 12),
          _TextField(
            controller: input.instructions,
            label: 'Instructions',
            required: false,
          ),
          const SizedBox(height: 12),
          _TextField(
            controller: input.sideEffects,
            label: 'Side effects, comma separated',
            required: false,
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.required = true,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlueColor.withOpacity(0.12)),
      ),
      child: child,
    );
  }
}

class _MedicineInput {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final frequency = TextEditingController();
  final duration = TextEditingController(text: '5');
  final instructions = TextEditingController();
  final sideEffects = TextEditingController();

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    instructions.dispose();
    sideEffects.dispose();
  }
}
