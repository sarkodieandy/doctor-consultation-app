class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String speciality;
  final DateTime appointmentDate;
  final String timeSlot;
  final double consultationFee;
  final String status; // pending, confirmed, completed, cancelled
  final DateTime createdAt;
  final String? notes;
  final double? rating;
  final String? review;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.speciality,
    required this.appointmentDate,
    required this.timeSlot,
    required this.consultationFee,
    this.status = 'pending',
    required this.createdAt,
    this.notes,
    this.rating,
    this.review,
  });

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) && status == 'confirmed';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  String get formattedDate => _formatDate(appointmentDate);

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_image': doctorImage,
      'speciality': speciality,
      'appointment_date': appointmentDate.toIso8601String(),
      'time_slot': timeSlot,
      'consultation_fee': consultationFee,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'rating': rating,
      'review': review,
    };
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      doctorName: json['doctor_name'] ?? json['doctorName'] ?? '',
      doctorImage: json['doctor_image'] ?? json['doctorImage'] ?? '',
      speciality: json['speciality'] ?? '',
      appointmentDate: json['appointment_date'] != null
          ? DateTime.parse(json['appointment_date'])
          : (json['appointmentDate'] != null
              ? DateTime.parse(json['appointmentDate'])
              : DateTime.now()),
      timeSlot: json['time_slot'] ?? json['timeSlot'] ?? '',
      consultationFee:
          (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      notes: json['notes'],
      rating: json['rating'] != null ? (json['rating']).toDouble() : null,
      review: json['review'],
    );
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? doctorId,
    String? doctorName,
    String? doctorImage,
    String? speciality,
    DateTime? appointmentDate,
    String? timeSlot,
    double? consultationFee,
    String? status,
    DateTime? createdAt,
    String? notes,
    double? rating,
    String? review,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorImage: doctorImage ?? this.doctorImage,
      speciality: speciality ?? this.speciality,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      consultationFee: consultationFee ?? this.consultationFee,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
