enum Role { customer, provider, admin }

enum Gender { male, female, other }

class UserEntity {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String token;
  final Role role;
  
  // Profile Information
  final String? address;
  final String? city;
  final String? postalCode;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? profileImageUrl;
  
  // Additional Information
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.token,
    required this.role,
    this.address,
    this.city,
    this.postalCode,
    this.gender,
    this.dateOfBirth,
    this.profileImageUrl,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      token: json['token'] as String,
      role: Role.values.firstWhere(
        (r) => r.toString() == 'Role.${json['role']}',
        orElse: () => Role.customer,
      ),
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (g) => g.toString() == 'Gender.${json['gender']}',
              orElse: () => Gender.male,
            )
          : null,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      profileImageUrl: json['profile_image_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'token': token,
        'role': role.toString().split('.').last,
        'address': address,
        'city': city,
        'postal_code': postalCode,
        'gender': gender?.toString().split('.').last,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'profile_image_url': profileImageUrl,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  // Copy method for updates (immutable entity)
  UserEntity copyWith({
    String? name,
    String? email,
    String? address,
    String? city,
    String? postalCode,
    Gender? gender,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    bool? isVerified,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber,
      email: email ?? this.email,
      token: token,
      role: role,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  String get genderDisplay {
    switch (gender) {
      case Gender.male:
        return 'পুরুষ';
      case Gender.female:
        return 'মহিলা';
      case Gender.other:
        return 'অন্যান্য';
      default:
        return 'নির্দিষ্ট করা হয়নি';
    }
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    var age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isProfileComplete {
    return name.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        city != null &&
        city!.isNotEmpty;
  }

  // Convert Gender string (Bengali) to enum
  static Gender? genderFromString(String? genderStr) {
    if (genderStr == null) return null;
    switch (genderStr) {
      case 'পুরুষ':
        return Gender.male;
      case 'মহিলা':
        return Gender.female;
      case 'অন্যান্য':
        return Gender.other;
      default:
        return null;
    }
  }

  // Convert Gender enum to Bengali string
  static String genderToString(Gender? gender) {
    if (gender == null) return '';
    switch (gender) {
      case Gender.male:
        return 'পুরুষ';
      case Gender.female:
        return 'মহিলা';
      case Gender.other:
        return 'অন্যান্য';
    }
  }
}