import 'package:doctor_consultation_app/models/review_model.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal();

  final List<ReviewModel> _mockReviews = [
    ReviewModel(
      id: 'rev_1',
      appointmentId: 'apt_1',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      doctorAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      patientName: 'John Doe',
      patientAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      rating: 5,
      title: 'Excellent Doctor',
      reviewText:
          'Dr. Stella is very professional and caring. She took time to explain everything.',
      tags: ['communication', 'expertise', 'punctuality'],
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      helpfulCount: 24,
      isVerifiedAppointment: true,
    ),
    ReviewModel(
      id: 'rev_2',
      appointmentId: 'apt_2',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      doctorAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      patientName: 'Jane Smith',
      patientAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      rating: 4,
      title: 'Very Good',
      reviewText: 'Professional and knowledgeable. Would recommend to others.',
      tags: ['expertise', 'cleanliness'],
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      helpfulCount: 18,
      isVerifiedAppointment: true,
    ),
    ReviewModel(
      id: 'rev_3',
      appointmentId: 'apt_3',
      doctorId: 'doc_2',
      doctorName: 'Dr. Joseph Cart',
      doctorAvatar:
          'https://images.unsplash.com/photo-1622902046580-2b47f47f5471?w=400',
      patientName: 'Mike Johnson',
      patientAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      rating: 5,
      title: 'Best Dentist',
      reviewText: 'Best dental care I have received. Highly recommended!',
      tags: ['expertise', 'communication', 'cleanliness'],
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      helpfulCount: 32,
      isVerifiedAppointment: true,
    ),
  ];

  /// Get all reviews
  Future<List<ReviewModel>> getAllReviews() async {
    await Future.delayed(Duration(milliseconds: 500));
    return _mockReviews;
  }

  /// Get reviews for a doctor
  Future<List<ReviewModel>> getDoctorReviews(String doctorId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockReviews.where((r) => r.doctorId == doctorId).toList();
  }

  /// Get doctor review summary
  Future<DoctorReviewSummary> getDoctorReviewSummary(
    String doctorId,
  ) async {
    await Future.delayed(Duration(milliseconds: 500));

    final reviews = _mockReviews.where((r) => r.doctorId == doctorId).toList();

    // Calculate average rating
    final totalRating = reviews.fold<double>(0, (sum, r) => sum + r.rating);
    final averageRating = reviews.isEmpty ? 0 : totalRating / reviews.length;

    // Calculate rating distribution
    final ratingDistribution = <int, int>{};
    for (var r in reviews) {
      final rating = r.rating.toInt();
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    // Get top tags
    final tagCounts = <String, int>{};
    for (var r in reviews) {
      for (var tag in r.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTagsList = topTags.take(3).map((e) => e.key).toList();

    final doctor = reviews.isNotEmpty ? reviews.first.doctorName : 'Doctor';

    return DoctorReviewSummary(
      doctorId: doctorId,
      doctorName: doctor,
      averageRating: averageRating.toDouble(),
      totalReviews: reviews.length,
      ratingDistribution: ratingDistribution,
      topTags: topTagsList,
      recentReviews: reviews.take(5).toList(),
    );
  }

  /// Get user reviews
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockReviews; // In real app, filter by patientId
  }

  /// Add review
  Future<bool> addReview(ReviewModel review) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      _mockReviews.add(review);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update review
  Future<bool> updateReview(ReviewModel review) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      final index = _mockReviews.indexWhere((r) => r.id == review.id);
      if (index != -1) {
        _mockReviews[index] = review;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      _mockReviews.removeWhere((r) => r.id == reviewId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markHelpful(String reviewId) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      final index = _mockReviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        final review = _mockReviews[index];
        _mockReviews[index] = review.copyWith(
          helpfulCount: review.helpfulCount + 1,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get reviews by rating
  Future<List<ReviewModel>> getReviewsByRating(
    String doctorId,
    int rating,
  ) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockReviews
        .where((r) => r.doctorId == doctorId && r.rating == rating)
        .toList();
  }
}
