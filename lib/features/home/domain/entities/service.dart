class Service {
  final String id;        // Unique ID (e.g., 'pipe-repair').
  final String categoryId;  // Link to ServiceCategory (e.g., 'plumbing').
  final String name;      // Bangla/English (e.g., 'পাইপ মেরামত').
  final String description; // Details (e.g., 'লিকিং পাইপ ফিক্স করুন').
  final double price;     // BDT (e.g., 500.0).
  final String providerName; // Placeholder provider (real in Week 4).

  const Service({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.providerName,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      providerName: json['provider_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'provider_name': providerName,
      };
}