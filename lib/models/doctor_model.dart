import 'package:flutter/painting.dart';

import 'package:doctor_consultation_app/utils/profile_image_provider.dart';

class DoctorModel {
  static const String fallbackImagePath = 'assets/images/doctor1.png';

  final String id;
  final String name;
  final String specialty;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double consultationFee;
  final String experience;
  final String hospital;
  final bool available;
  final List<String> availableTimes;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.description,
    required this.imageUrl,
    this.rating = 4.5,
    this.reviewCount = 0,
    required this.consultationFee,
    required this.experience,
    required this.hospital,
    this.available = true,
    this.availableTimes = const [],
  });

  ImageProvider<Object> get imageProvider {
    return profileImageProvider(imageUrl) ??
        const AssetImage(fallbackImagePath);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'consultation_fee': consultationFee,
      'experience': experience,
      'hospital': hospital,
      'available': available,
      'available_times': availableTimes,
    };
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final availability = json['availability'] ?? json['available_times'] ?? [];
    return DoctorModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      specialty: (json['specialty'] ?? json['specialization'] ?? '').toString(),
      description: (json['description'] ?? json['bio'] ?? '').toString(),
      imageUrl:
          (json['image_url'] ?? json['imageUrl'] ?? json['profile_image'] ?? '')
              .toString(),
      rating: (json['rating'] ?? json['average_rating'] ?? 4.5).toDouble(),
      reviewCount: json['review_count'] ??
          json['reviewCount'] ??
          json['reviews_count'] ??
          0,
      consultationFee:
          (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toDouble(),
      experience:
          (json['experience'] ?? json['experience_years'] ?? '').toString(),
      hospital: (json['hospital'] ?? 'MediConnect Clinic').toString(),
      available: json['available'] == true ||
          json['available']?.toString() == '1' ||
          json['available'] == null,
      availableTimes: _parseAvailability(availability),
    );
  }

  static List<String> _parseAvailability(dynamic availability) {
    if (availability is List) {
      return availability.map((entry) {
        if (entry is Map) {
          final weekday = entry['weekday'];
          final start = entry['start_time'] ?? entry['startTime'] ?? '';
          final end = entry['end_time'] ?? entry['endTime'] ?? '';
          if (weekday != null) {
            return 'Day $weekday $start-$end';
          }
          return '$start-$end';
        }
        return entry.toString();
      }).toList();
    }

    return const [];
  }

  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? description,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    double? consultationFee,
    String? experience,
    String? hospital,
    bool? available,
    List<String>? availableTimes,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      consultationFee: consultationFee ?? this.consultationFee,
      experience: experience ?? this.experience,
      hospital: hospital ?? this.hospital,
      available: available ?? this.available,
      availableTimes: availableTimes ?? this.availableTimes,
    );
  }
}
