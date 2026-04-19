import 'package:doctor_consultation_app/models/review_model.dart';
import 'package:doctor_consultation_app/services/local_backend_store.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal();
  final _store = LocalBackendStore.instance;

  /// Get all reviews
  Future<List<ReviewModel>> getAllReviews() async {
    final reviews = List<ReviewModel>.from(_store.reviews);
    reviews.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return reviews;
  }

  /// Get reviews for a doctor
  Future<List<ReviewModel>> getDoctorReviews(String doctorId) async {
    final reviews =
        _store.reviews.where((review) => review.doctorId == doctorId).toList();
    reviews.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return reviews;
  }

  /// Get doctor review summary
  Future<DoctorReviewSummary> getDoctorReviewSummary(String doctorId) async {
    try {
      final reviews = await getDoctorReviews(doctorId);

      final totalRating = reviews.fold<double>(0, (sum, r) => sum + r.rating);
      final averageRating =
          reviews.isEmpty ? 0.0 : totalRating / reviews.length;

      final ratingDistribution = <int, int>{};
      for (var r in reviews) {
        final rating = r.rating.toInt();
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }

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
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        topTags: topTagsList,
        recentReviews: reviews.take(5).toList(),
      );
    } catch (e) {
      print('Error getting review summary: $e');
      return DoctorReviewSummary(
        doctorId: doctorId,
        doctorName: 'Doctor',
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: {},
        topTags: [],
        recentReviews: [],
      );
    }
  }

  /// Get user reviews
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    final reviews =
        _store.reviews.where((review) => review.patientId == userId).toList();
    reviews.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return reviews;
  }

  /// Add review
  Future<bool> addReview(ReviewModel review) async {
    _store.reviews.add(review.id.isEmpty
        ? review.copyWith(id: _store.nextId('review'))
        : review);
    return true;
  }

  /// Update review
  Future<bool> updateReview(ReviewModel review) async {
    final index = _store.reviews.indexWhere((item) => item.id == review.id);
    if (index == -1) return false;
    _store.reviews[index] = review;
    return true;
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId) async {
    _store.reviews.removeWhere((review) => review.id == reviewId);
    return true;
  }

  /// Mark review as helpful
  Future<bool> markHelpful(String reviewId) async {
    final index = _store.reviews.indexWhere((review) => review.id == reviewId);
    if (index == -1) return false;
    final review = _store.reviews[index];
    _store.reviews[index] =
        review.copyWith(helpfulCount: review.helpfulCount + 1);
    return true;
  }

  /// Get reviews by rating
  Future<List<ReviewModel>> getReviewsByRating(
      String doctorId, int rating) async {
    return _store.reviews
        .where((review) =>
            review.doctorId == doctorId && review.rating.toInt() == rating)
        .toList();
  }
}
