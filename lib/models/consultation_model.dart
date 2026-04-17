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
