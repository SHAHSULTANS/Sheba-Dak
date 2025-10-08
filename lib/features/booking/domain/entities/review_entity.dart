// lib/features/booking/domain/entities/review_entity.dart
import 'package:uuid/uuid.dart';

class ReviewEntity {
  final String id;
  final String bookingId;
  final String providerId;
  final String customerId;
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.customerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    return ReviewEntity(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      providerId: json['provider_id'] as String,
      customerId: json['customer_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'provider_id': providerId,
        'customer_id': customerId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };

  ReviewEntity copyWith({
    String? id,
    String? bookingId,
    String? providerId,
    String? customerId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewEntity(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      providerId: providerId ?? this.providerId,
      customerId: customerId ?? this.customerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}