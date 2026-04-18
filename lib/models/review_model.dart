class ReviewModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String doctorAvatar;
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final double rating;
  final String title;
  final String reviewText;
  final List<String> tags;
  final DateTime createdAt;
  final int helpfulCount;
  final bool isVerifiedAppointment;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorAvatar,
    this.patientId = '',
    required this.patientName,
    required this.patientAvatar,
    required this.rating,
    required this.title,
    required this.reviewText,
    required this.tags,
    required this.createdAt,
    required this.helpfulCount,
    required this.isVerifiedAppointment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_avatar': doctorAvatar,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_avatar': patientAvatar,
      'rating': rating,
      'title': title,
      'review_text': reviewText,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'helpful_count': helpfulCount,
      'is_verified_appointment': isVerifiedAppointment,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] ?? '').toString(),
      appointmentId:
          (json['appointment_id'] ?? json['appointmentId'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      doctorName: json['doctor_name'] ?? json['doctorName'] ?? '',
      doctorAvatar: json['doctor_avatar'] ?? json['doctorAvatar'] ?? '',
      patientId: (json['patient_id'] ?? '').toString(),
      patientName: json['patient_name'] ?? json['patientName'] ?? '',
      patientAvatar: json['patient_avatar'] ?? json['patientAvatar'] ?? '',
      rating: (json['rating'] ?? 5).toDouble(),
      title: json['title'] ?? '',
      reviewText: json['review_text'] ?? json['reviewText'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      helpfulCount: json['helpful_count'] ?? json['helpfulCount'] ?? 0,
      isVerifiedAppointment: json['is_verified_appointment'] ??
          json['isVerifiedAppointment'] ??
          false,
    );
  }

  ReviewModel copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? doctorName,
    String? doctorAvatar,
    String? patientId,
    String? patientName,
    String? patientAvatar,
    double? rating,
    String? title,
    String? reviewText,
    List<String>? tags,
    DateTime? createdAt,
    int? helpfulCount,
    bool? isVerifiedAppointment,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorAvatar: doctorAvatar ?? this.doctorAvatar,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAvatar: patientAvatar ?? this.patientAvatar,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      reviewText: reviewText ?? this.reviewText,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isVerifiedAppointment:
          isVerifiedAppointment ?? this.isVerifiedAppointment,
    );
  }
}

class DoctorReviewSummary {
  final String doctorId;
  final String doctorName;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count
  final List<String> topTags;
  final List<ReviewModel> recentReviews;

  DoctorReviewSummary({
    required this.doctorId,
    required this.doctorName,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.topTags,
    required this.recentReviews,
  });
}
