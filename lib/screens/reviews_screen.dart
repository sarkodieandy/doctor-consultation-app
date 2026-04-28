import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/review_controller.dart';
import 'package:doctor_consultation_app/data/patient_ui_content.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
import 'package:doctor_consultation_app/models/review_model.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatefulWidget {
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late ReviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ReviewController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        title: Text(
          'Reviews',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: kOrangeColor),
            );
          }

          if (controller.allReviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 60, color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text('No reviews yet'),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildReviewSummary(controller),
              SizedBox(height: 16),
              _buildLeaveReviewCard(),
              SizedBox(height: 16),
              ...controller.allReviews.map((review) {
                return _buildReviewCard(review);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaveReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2E5ED2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.star_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Feedback Matters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Help improve care quality. Rate your recent visits and share your experience.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: _avatarProvider(review.patientAvatar),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.patientName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: kTitleTextColor,
                            ),
                          ),
                          Text(
                            'For Dr. ${review.doctorName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (review.isVerifiedAppointment)
                      Tooltip(
                        message: 'Verified Appointment',
                        child: Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),

                // Rating
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating.toInt()
                              ? Icons.star
                              : Icons.star_border,
                          color: kYellowColor,
                          size: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${review.rating}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(review.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Title
                Text(
                  review.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 8),

                // Review text
                Text(
                  review.reviewText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 8,
                  children: review.tags.map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kBlueColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: kBlueColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),

                // Helpful
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined,
                        size: 16, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${review.helpfulCount} found this helpful',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.markHelpful(review.id),
                      child: Text(
                        'Helpful',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kBlueColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(ReviewController controller) {
    final totalReviews = controller.allReviews.length;
    final averageRating = totalReviews == 0
        ? 0.0
        : controller.allReviews
                .fold<double>(0, (sum, review) => sum + review.rating) /
            totalReviews;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryStat(
              averageRating.toStringAsFixed(1),
              'Average',
            ),
          ),
          Expanded(
            child: _buildSummaryStat('$totalReviews', 'Reviews'),
          ),
          Expanded(
            child: _buildSummaryStat(
              '${controller.allReviews.where((review) => review.isVerifiedAppointment).length}',
              'Verified',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: kBlueColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: kTitleTextColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  ImageProvider<Object> _avatarProvider(String avatar) {
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    if (avatar.toLowerCase().contains('.svg')) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    return const AssetImage(DoctorModel.fallbackImagePath);
  }
}

class WriteReviewScreen extends StatefulWidget {
  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final controller = Get.find<ReviewController>();
  final authService = AuthService();
  late double _rating;
  final titleController = TextEditingController();
  final reviewController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> availableTags = patientReviewTags;

  @override
  void initState() {
    super.initState();
    _rating = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Write a Review',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Get.arguments != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Reviewing ${Get.arguments.doctorName} after your ${Get.arguments.speciality} consultation.',
                  style: TextStyle(
                    color: kTitleTextColor.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),
            if (Get.arguments != null) SizedBox(height: 16),
            // Rating
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate your experience',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => GestureDetector(
                          onTap: () {
                            setState(() => _rating = (index + 1).toDouble());
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: kYellowColor,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_rating > 0) ...[
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        '$_rating star${_rating.toInt() > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: kYellowColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              'Review Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Summarize your experience',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kSearchBackgroundColor),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: kWhiteColor,
              ),
            ),
            SizedBox(height: 16),

            // Review
            Text(
              'Your Review',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your detailed experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kSearchBackgroundColor),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: kWhiteColor,
              ),
            ),
            SizedBox(height: 16),

            // Tags
            Text(
              'What was good? (Select all that apply)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kTitleTextColor,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  backgroundColor: kWhiteColor,
                  selectedColor: kBlueColor.withOpacity(0.2),
                  side: BorderSide(
                    color: isSelected ? kBlueColor : kSearchBackgroundColor,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: _submitReview,
                color: kOrangeColor,
                height: 50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Submit Review',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    final appointment = Get.arguments;
    final user = authService.currentUser;

    if (_rating == 0) {
      Get.snackbar('Error', 'Please select a rating');
      return;
    }

    if (titleController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter a review title');
      return;
    }

    if (reviewController.text.isEmpty) {
      Get.snackbar('Error', 'Please write your review');
      return;
    }

    if (appointment == null || user == null) {
      Get.snackbar('Error', 'Review context is missing');
      return;
    }

    final success = await controller.addReview(
      ReviewModel(
        id: '',
        appointmentId: appointment.id,
        doctorId: appointment.doctorId,
        doctorName: appointment.doctorName,
        doctorAvatar: appointment.doctorImage,
        patientId: user.id,
        patientName: user.fullName,
        patientAvatar: user.profileImage.isEmpty
            ? DoctorModel.fallbackImagePath
            : user.profileImage,
        rating: _rating,
        title: titleController.text.trim(),
        reviewText: reviewController.text.trim(),
        tags: List<String>.from(_selectedTags),
        createdAt: DateTime.now(),
        helpfulCount: 0,
        isVerifiedAppointment: true,
      ),
    );

    if (success) {
      await controller.fetchAllReviews();
      Get.offNamed('/reviews');
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    reviewController.dispose();
    super.dispose();
  }
}
