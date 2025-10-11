// 📁 lib/features/booking/domain/entities/booking_entity.dart

enum BookingStatus {
  pending,
  paymentPending, // Added for payment initiation
  paymentCompleted, // New status for payment completion
  confirmed,
  inProgress,
  completed,
  cancelled,
}

class BookingEntity {
  final String id;
  final String customerId;
  final String providerId;
  final String serviceCategory;
  final DateTime scheduledAt;
  final BookingStatus status;
  final double price;
  final String? description;

  // ✅ Newly added field
  final String? location;

  const BookingEntity({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceCategory,
    required this.scheduledAt,
    required this.status,
    required this.price,
    this.description,
    this.location,
  });

  factory BookingEntity.fromJson(Map<String, dynamic> json) {
    return BookingEntity(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      serviceCategory: json['service_category'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: BookingStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (json['status'] as String),
        orElse: () => BookingStatus.pending,
      ),
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      location: json['location'] as String?, // ✅ Added
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'provider_id': providerId,
        'service_category': serviceCategory,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.toString().split('.').last,
        'price': price,
        'description': description,
        'location': location, // ✅ Added
      };

  BookingEntity copyWith({
    String? id,
    String? customerId,
    String? providerId,
    String? serviceCategory,
    DateTime? scheduledAt,
    BookingStatus? status,
    double? price,
    String? description,
    String? location, // ✅ Added
  }) {
    return BookingEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      price: price ?? this.price,
      description: description ?? this.description,
      location: location ?? this.location, // ✅ Added
    );
  }
}
