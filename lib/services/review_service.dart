import 'package:doctor_consultation_app/models/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal();

  final _supabase = Supabase.instance.client;

  /// Get all reviews
  Future<List<ReviewModel>> getAllReviews() async {
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .order('created_at', ascending: false);

      return (data as List).map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  /// Get reviews for a doctor
  Future<List<ReviewModel>> getDoctorReviews(String doctorId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching doctor reviews: $e');
      return [];
    }
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
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .eq('patient_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user reviews: $e');
      return [];
    }
  }

  /// Add review
  Future<bool> addReview(ReviewModel review) async {
    try {
      final json = review.toJson();
      json.remove('id');
      await _supabase.from('reviews').insert(json);
      return true;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  /// Update review
  Future<bool> updateReview(ReviewModel review) async {
    try {
      final json = review.toJson();
      json.remove('id');
      await _supabase.from('reviews').update(json).eq('id', review.id);
      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markHelpful(String reviewId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select('helpful_count')
          .eq('id', reviewId)
          .single();

      final currentCount = data['helpful_count'] ?? 0;

      await _supabase
          .from('reviews')
          .update({'helpful_count': currentCount + 1}).eq('id', reviewId);

      return true;
    } catch (e) {
      print('Error marking helpful: $e');
      return false;
    }
  }

  /// Get reviews by rating
  Future<List<ReviewModel>> getReviewsByRating(
      String doctorId, int rating) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select()
          .eq('doctor_id', doctorId)
          .eq('rating', rating)
          .order('created_at', ascending: false);

      return (data as List).map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reviews by rating: $e');
      return [];
    }
  }
}
