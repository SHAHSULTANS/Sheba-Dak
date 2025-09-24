class ServiceCategory {
  final String id;  // Unique ID (e.g., 'plumbing').
  final String name;  // Bangla/English name (e.g., 'প্লাম্বিং').
  final String iconPath;  // Asset path or URL (e.g., 'assets/icons/plumbing.png').
  final String description;  // Short desc (e.g., 'পাইপ লিক, ড্রেন ব্লক ইত্যাদি').

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconPath: json['icon_path'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon_path': iconPath,
        'description': description,
      };
}