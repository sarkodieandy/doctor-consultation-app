class PrescriptionModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String appointmentId;
  final String patientId;
  final DateTime prescribedDate;
  final DateTime? expiryDate;
  final List<Medicine> medicines;
  final String notes;
  final String status; // active, completed, expired
  final String? attachmentUrl;

  PrescriptionModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentId,
    this.patientId = '',
    required this.prescribedDate,
    this.expiryDate,
    required this.medicines,
    required this.notes,
    required this.status,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'prescribed_date': prescribedDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
      'status': status,
      'attachment_url': attachmentUrl,
    };
  }

  factory PrescriptionModel.fromJson(Map<String, dynamic> json,
      {List<Medicine>? medicines}) {
    return PrescriptionModel(
      id: (json['id'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      doctorName: (json['doctor_name'] ?? json['doctorName'] ?? '').toString(),
      appointmentId:
          (json['appointment_id'] ?? json['appointmentId'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      prescribedDate: DateTime.parse(json['prescribed_date'] ??
          json['prescribedDate'] ??
          DateTime.now().toIso8601String()),
      expiryDate: (json['expiry_date'] ?? json['expiryDate']) != null
          ? DateTime.parse(json['expiry_date'] ?? json['expiryDate'])
          : null,
      medicines: medicines ?? [],
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      attachmentUrl:
          (json['attachment_url'] ?? json['attachmentUrl'])?.toString(),
    );
  }

  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isActive => status == 'active' && !isExpired;

  PrescriptionModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? appointmentId,
    String? patientId,
    DateTime? prescribedDate,
    DateTime? expiryDate,
    List<Medicine>? medicines,
    String? notes,
    String? status,
    String? attachmentUrl,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      medicines: medicines ?? this.medicines,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}

class Medicine {
  final String id;
  final String prescriptionId;
  final String name;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String instructions;
  final List<String> sideEffects;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.sideEffects,
    this.prescriptionId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prescription_id': prescriptionId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'side_effects': sideEffects,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: (json['id'] ?? '').toString(),
      prescriptionId: (json['prescription_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      frequency: (json['frequency'] ?? '').toString(),
      duration: int.tryParse((json['duration'] ?? 0).toString()) ?? 0,
      instructions: (json['instructions'] ?? '').toString(),
      sideEffects:
          List<String>.from(json['side_effects'] ?? json['sideEffects'] ?? []),
    );
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    int? duration,
    String? instructions,
    List<String>? sideEffects,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      sideEffects: sideEffects ?? this.sideEffects,
    );
  }
}
