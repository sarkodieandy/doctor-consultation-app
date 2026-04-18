import 'package:flutter/painting.dart';

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
    final resolvedImageUrl = imageUrl.trim();

    if (resolvedImageUrl.isEmpty) {
      return const AssetImage(fallbackImagePath);
    }

    if (resolvedImageUrl.startsWith('assets/')) {
      return AssetImage(resolvedImageUrl);
    }

    return NetworkImage(resolvedImageUrl);
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
    return DoctorModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      consultationFee:
          (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toDouble(),
      experience: json['experience'] ?? '',
      hospital: json['hospital'] ?? '',
      available: json['available'] ?? true,
      availableTimes: List<String>.from(
          json['available_times'] ?? json['availableTimes'] ?? []),
    );
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
