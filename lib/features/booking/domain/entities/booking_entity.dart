// lib/features/booking/domain/entities/booking_entity.dart

enum BookingStatus { 
  pending, 
  confirmed, 
  in_progress, 
  completed, 
  cancelled 
}

class BookingEntity {
  final String id;
  final String customerId; // From UserEntity.id.
  final String providerId; // From ServiceProvider.id.
  final String serviceCategory; // From ServiceCategory.id.
  final DateTime scheduledAt; // Booking time.
  final BookingStatus status; // Enum for lifecycle.
  final double price; // From Service.price.
  final String? description; // Optional details.

  const BookingEntity({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceCategory,
    required this.scheduledAt,
    required this.status,
    required this.price,
    this.description,
  });

  factory BookingEntity.fromJson(Map<String, dynamic> json) {
    return BookingEntity(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      serviceCategory: json['service_category'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: BookingStatus.values.firstWhere(
        // Find the enum value from the string (e.g., 'pending')
        (s) => s.toString().split('.').last == (json['status'] as String),
      ),
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'provider_id': providerId,
    'service_category': serviceCategory,
    'scheduled_at': scheduledAt.toIso8601String(),
    'status': status.toString().split('.').last, // Convert enum to string ('pending')
    'price': price,
    'description': description,
  };
}