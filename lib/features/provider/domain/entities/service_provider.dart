class ServiceProvider {
  final String id;        // Unique ID.
  final String name;      // Provider name (Bangla/English).
  final double rating;    // Average rating (0-5).
  final bool isVerified;  // Admin-verified flag.
  final List<String> services; // List of service IDs (link to Service model).
  final String description; // Bio.

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.rating,
    required this.isVerified,
    required this.services,
    required this.description,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      // Ensure rating is always a double, handling both int and double input from JSON
      rating: (json['rating'] as num).toDouble(), 
      isVerified: json['is_verified'] as bool,
      // Ensure the list is cast correctly
      services: (json['services'] as List).cast<String>(), 
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rating': rating,
    'is_verified': isVerified,
    'services': services,
    'description': description,
  };
}