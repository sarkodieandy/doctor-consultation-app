class ReviewModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String doctorAvatar;
  final String patientName;
  final String patientAvatar;
  final double rating;
  final String title;
  final String reviewText;
  final List<String> tags; // communication, expertise, cleanliness, punctuality
  final DateTime createdAt;
  final int helpfulCount;
  final bool isVerifiedAppointment;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorAvatar,
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

  ReviewModel copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? doctorName,
    String? doctorAvatar,
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
