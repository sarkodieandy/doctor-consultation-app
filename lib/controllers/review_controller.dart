import 'package:doctor_consultation_app/models/review_model.dart';
import 'package:doctor_consultation_app/services/review_service.dart';
import 'package:get/get.dart';

class ReviewController extends GetxController {
  final _reviewService = ReviewService();

  final allReviews = <ReviewModel>[].obs;
  final doctorReviews = <ReviewModel>[].obs;
  final doctorReviewSummary = Rxn<DoctorReviewSummary>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchAllReviews();
  }

  /// Fetch all reviews
  Future<void> fetchAllReviews() async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _reviewService.getAllReviews();
      allReviews.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Fetch doctor reviews
  Future<void> fetchDoctorReviews(String doctorId) async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _reviewService.getDoctorReviews(doctorId);
      doctorReviews.assignAll(result);

      // Get summary
      final summary = await _reviewService.getDoctorReviewSummary(doctorId);
      doctorReviewSummary(summary);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Add review
  Future<bool> addReview(ReviewModel review) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _reviewService.addReview(review);

      if (success) {
        await fetchDoctorReviews(review.doctorId);
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Update review
  Future<bool> updateReview(ReviewModel review) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _reviewService.updateReview(review);

      if (success) {
        await fetchDoctorReviews(review.doctorId);
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId, String doctorId) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _reviewService.deleteReview(reviewId);

      if (success) {
        await fetchDoctorReviews(doctorId);
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Mark review as helpful
  Future<bool> markHelpful(String reviewId) async {
    try {
      isLoading(true);
      errorMessage(null);

      final success = await _reviewService.markHelpful(reviewId);

      if (success) {
        // Update local review
        final index = allReviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          allReviews[index] = allReviews[index]
              .copyWith(helpfulCount: allReviews[index].helpfulCount + 1);
        }
      }
      return success;
    } catch (e) {
      errorMessage(e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Get reviews by rating
  Future<void> getReviewsByRating(String doctorId, int rating) async {
    try {
      isLoading(true);
      errorMessage(null);
      final result = await _reviewService.getReviewsByRating(doctorId, rating);
      doctorReviews.assignAll(result);
    } catch (e) {
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }
}
