class HealthRecordModel {
  final String id;
  final String userId;
  final String type; // vital, lab, document, allergy
  final String title;
  final String value;
  final String unit;
  final String? normalRange;
  final String? status; // normal, high, low
  final DateTime recordDate;
  final String? documentUrl;
  final String? notes;

  HealthRecordModel({
    required this.id,
    this.userId = '',
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    this.normalRange,
    this.status,
    required this.recordDate,
    this.documentUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'value': value,
      'unit': unit,
      'normal_range': normalRange,
      'status': status,
      'record_date': recordDate.toIso8601String(),
      'document_url': documentUrl,
      'notes': notes,
    };
  }

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      type: (json['type'] ?? 'vital').toString(),
      title: (json['title'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      normalRange: (json['normal_range'] ?? json['normalRange'])?.toString(),
      status: (json['status'])?.toString(),
      recordDate: DateTime.parse(json['record_date'] ??
          json['recordDate'] ??
          DateTime.now().toIso8601String()),
      documentUrl: (json['document_url'] ?? json['documentUrl'])?.toString(),
      notes: (json['notes'])?.toString(),
    );
  }

  bool get isNormal => status == 'normal' || status == null;
  bool get isAbnormal => status == 'high' || status == 'low';

  HealthRecordModel copyWith({
    String? id,
    String? type,
    String? title,
    String? value,
    String? unit,
    String? normalRange,
    String? status,
    DateTime? recordDate,
    String? documentUrl,
    String? notes,
  }) {
    return HealthRecordModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      normalRange: normalRange ?? this.normalRange,
      status: status ?? this.status,
      recordDate: recordDate ?? this.recordDate,
      documentUrl: documentUrl ?? this.documentUrl,
      notes: notes ?? this.notes,
    );
  }
}

class VitalSign {
  final String id;
  final String type; // heart_rate, blood_pressure, temperature, weight, height
  final String value;
  final String unit;
  final DateTime recordedAt;
  final String status; // normal, high, low

  VitalSign({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.status,
  });
}
