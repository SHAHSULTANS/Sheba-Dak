import 'package:smartsheba/features/provider/domain/entities/service_provider.dart'; // Assuming this exists from Day 22

class ProviderApplication {
  final String userId;  // Current user's ID (customer applying).
  final String name;
  final List<String> documents; // File paths/URLs (simulated local paths for now).
  final List<String> services;  // Selected service IDs (e.g., ['cat_1', 'cat_3']).
  final String description;

  const ProviderApplication({
    required this.userId,
    required this.name,
    required this.documents,
    required this.services,
    required this.description,
  });

  // Helper method for submission (serialization)
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'documents': documents,
    'services': services,
    'description': description,
  };
}