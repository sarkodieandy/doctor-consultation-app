import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/review_controller.dart';
import 'package:doctor_consultation_app/models/review_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatelessWidget {
  final controller = Get.find<ReviewController>();

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
              ...controller.allReviews.map((review) {
                return _buildReviewCard(review);
              }).toList(),
            ],
          );
        },
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
                      backgroundImage: NetworkImage(review.patientAvatar),
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
                    Text(
                      '${review.helpfulCount} found this helpful',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
}

class WriteReviewScreen extends StatefulWidget {
  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final controller = Get.find<ReviewController>();
  late double _rating;
  final titleController = TextEditingController();
  final reviewController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> availableTags = [
    'communication',
    'expertise',
    'cleanliness',
    'punctuality',
  ];

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
          icon: Icon(Icons.arrow_back, color: kTitleTextColor),
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

  void _submitReview() {
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

    final review = ReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      appointmentId: 'apt_123',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      doctorAvatar:
          'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=400',
      patientName: 'You',
      patientAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      rating: _rating,
      title: titleController.text,
      reviewText: reviewController.text,
      tags: _selectedTags,
      createdAt: DateTime.now(),
      helpfulCount: 0,
      isVerifiedAppointment: true,
    );

    controller.addReview(review);
    Get.back();
  }

  @override
  void dispose() {
    titleController.dispose();
    reviewController.dispose();
    super.dispose();
  }
}
