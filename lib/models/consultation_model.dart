class ConsultationModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String doctorAvatar;
  final String userId;
  final DateTime scheduledTime;
  final Duration duration;
  final String status; // scheduled, ongoing, completed, cancelled
  final String consultationType; // video, audio, text
  final String? roomId;
  final String? recordingUrl;
  final String? summary;
  final DateTime? startedAt;
  final DateTime? endedAt;

  ConsultationModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorAvatar,
    required this.userId,
    required this.scheduledTime,
    required this.duration,
    required this.status,
    required this.consultationType,
    this.roomId,
    this.recordingUrl,
    this.summary,
    this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_avatar': doctorAvatar,
      'user_id': userId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'duration_minutes': duration.inMinutes,
      'status': status,
      'consultation_type': consultationType,
      'room_id': roomId,
      'recording_url': recordingUrl,
      'summary': summary,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: (json['id'] ?? '').toString(),
      appointmentId:
          (json['appointment_id'] ?? json['appointmentId'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      doctorName: json['doctor_name'] ?? json['doctorName'] ?? '',
      doctorAvatar: json['doctor_avatar'] ?? json['doctorAvatar'] ?? '',
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      scheduledTime: DateTime.parse(json['scheduled_time'] ??
          json['scheduledTime'] ??
          DateTime.now().toIso8601String()),
      duration: Duration(minutes: json['duration_minutes'] ?? 30),
      status: json['status'] ?? 'scheduled',
      consultationType:
          json['consultation_type'] ?? json['consultationType'] ?? 'video',
      roomId: json['room_id'] ?? json['roomId'],
      recordingUrl: json['recording_url'] ?? json['recordingUrl'],
      summary: json['summary'],
      startedAt: (json['started_at'] ?? json['startedAt']) != null
          ? DateTime.parse(json['started_at'] ?? json['startedAt'])
          : null,
      endedAt: (json['ended_at'] ?? json['endedAt']) != null
          ? DateTime.parse(json['ended_at'] ?? json['endedAt'])
          : null,
    );
  }

  bool get isUpcoming =>
      status == 'scheduled' && DateTime.now().isBefore(scheduledTime);
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  ConsultationModel copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? doctorName,
    String? doctorAvatar,
    String? userId,
    DateTime? scheduledTime,
    Duration? duration,
    String? status,
    String? consultationType,
    String? roomId,
    String? recordingUrl,
    String? summary,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorAvatar: doctorAvatar ?? this.doctorAvatar,
      userId: userId ?? this.userId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      consultationType: consultationType ?? this.consultationType,
      roomId: roomId ?? this.roomId,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      summary: summary ?? this.summary,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
