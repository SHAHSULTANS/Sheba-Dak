enum Role { customer, provider, admin }

class UserEntity {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String token;
  final Role role;
  final String? address;  // Added for profile (editable).

  const UserEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.token,
    required this.role,
    this.address,
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
      };

  // Copy method for updates (immutable entity).
  UserEntity copyWith({
    String? name,
    String? email,
    String? address,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber,
      email: email ?? this.email,
      token: token,
      role: role,
      address: address ?? this.address,
    );
  }
}