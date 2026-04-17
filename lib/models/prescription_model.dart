class PrescriptionModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String appointmentId;
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
    required this.prescribedDate,
    this.expiryDate,
    required this.medicines,
    required this.notes,
    required this.status,
    this.attachmentUrl,
  });

  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isActive => status == 'active' && !isExpired;

  PrescriptionModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? appointmentId,
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
  });

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
