import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookingScreen({
    Key? key,
    required this.doctor,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime selectedDate;
  late String selectedTime;
  late String selectedMode;
  late String selectedLanguage;
  late String selectedReason;

  final controller = Get.find<AppointmentController>();
  final symptomController = TextEditingController();
  final notesController = TextEditingController();
  final selectedSymptoms = <String>{};

  final List<String> timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    final meta = patientDoctorMetaFor(widget.doctor);
    selectedDate = DateTime.now().add(const Duration(days: 1));
    selectedTime = timeSlots[0];
    selectedMode = meta.consultationModes.first;
    selectedLanguage = meta.languages.first;
    selectedReason = patientIntakeReasons.first;
  }

  @override
  void dispose() {
    symptomController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = patientDoctorMetaFor(widget.doctor);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Book Appointment',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: widget.doctor.imageProvider,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kTitleTextColor,
                          ),
                        ),
                        Text(
                          '${widget.doctor.specialty} • ${meta.city}',
                          style: TextStyle(
                            fontSize: 14,
                            color: kBlueColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          meta.nextAvailable,
                          style: TextStyle(
                            fontSize: 12,
                            color: kTitleTextColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSectionTitle('Consultation Fee'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBlueColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GHS ${widget.doctor.consultationFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kBlueColor,
                    ),
                  ),
                  Text(
                    'Payment details',
                    style: TextStyle(
                      fontSize: 12,
                      color: kTitleTextColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Date & Time'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kSearchBackgroundColor),
              ),
              child: GestureDetector(
                onTap: _selectDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        color: kTitleTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: kBlueColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final time = timeSlots[index];
                final isSelected = selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => selectedTime = time),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? kBlueColor : kWhiteColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? kBlueColor : kSearchBackgroundColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? kWhiteColor : kTitleTextColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Consultation Preferences'),
            const SizedBox(height: 10),
            _buildChoiceWrap(
              options: meta.consultationModes,
              selectedValue: selectedMode,
              onSelected: (value) => setState(() => selectedMode = value),
            ),
            const SizedBox(height: 12),
            _buildChoiceWrap(
              options: meta.languages,
              selectedValue: selectedLanguage,
              onSelected: (value) => setState(() => selectedLanguage = value),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Visit Reason'),
            const SizedBox(height: 10),
            _buildChoiceWrap(
              options: patientIntakeReasons,
              selectedValue: selectedReason,
              onSelected: (value) => setState(() => selectedReason = value),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Symptoms Checklist'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: patientSymptomsChecklist.map((symptom) {
                final isSelected = selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  selectedColor: kBlueColor.withOpacity(0.18),
                  checkmarkColor: kBlueColor,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        selectedSymptoms.remove(symptom);
                      } else {
                        selectedSymptoms.add(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: symptomController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe what you want the doctor to review.',
                filled: true,
                fillColor: kWhiteColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: kSearchBackgroundColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: kSearchBackgroundColor),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.18)),
              ),
              child: Text(
                'If symptoms are severe or sudden, use urgent care instead of waiting for a virtual appointment.',
                style: TextStyle(
                  color: kTitleTextColor.withOpacity(0.72),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Consultation Preparation'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: patientConsultationPrepItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18, color: kBlueColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Optional notes for the doctor or support team',
                filled: true,
                fillColor: kWhiteColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: kSearchBackgroundColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: kSearchBackgroundColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: kBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBlueColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Appointment Date',
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                  ),
                  _buildSummaryRow('Appointment Time', selectedTime),
                  _buildSummaryRow('Mode', selectedMode),
                  _buildSummaryRow('Language', selectedLanguage),
                  _buildSummaryRow('Reason', selectedReason),
                  _buildSummaryRow(
                    'Consultation Fee',
                    'GHS ${widget.doctor.consultationFee.toStringAsFixed(0)}',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: _proceedToPayment,
                color: kBlueColor,
                height: 55,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: () => Get.back(),
                color: kWhiteColor,
                height: 55,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: kTitleTextColor.withOpacity(0.2)),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: kTitleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: kTitleTextColor,
      ),
    );
  }

  Widget _buildChoiceWrap({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? kBlueColor : kWhiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kBlueColor : kSearchBackgroundColor,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? kWhiteColor : kTitleTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHighlighted ? kBlueColor : kTitleTextColor,
                fontSize: isHighlighted ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlueColor,
              onPrimary: kWhiteColor,
              surface: kBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _proceedToPayment() async {
    final appointmentId = await controller.bookAppointment(
      widget.doctor.id,
      selectedDate,
      selectedTime,
    );

    if (appointmentId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create the appointment draft.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Get.toNamed('/payment-method', arguments: {
      'doctor': widget.doctor,
      'date': selectedDate,
      'time': selectedTime,
      'appointment_id': appointmentId,
      'mode': selectedMode,
      'language': selectedLanguage,
      'reason': selectedReason,
      'symptoms': selectedSymptoms.toList(),
      'description': symptomController.text.trim(),
      'notes': notesController.text.trim(),
    });

    if (result == true) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked and payment confirmed.'),
          backgroundColor: Colors.green,
        ),
      );

      Get.offNamed('/appointments');
    }
  }
}
