enum Role { customer, provider, admin }  // RBAC roles, extensible for superAdmin.

class UserEntity {
  final String id;  // UUID from backend (e.g., 'e8e616e0-d894-4936-a3f5-391682ee794c').
  final String name;  // User’s full name.
  final String phoneNumber;  // Primary auth identifier (Bangladesh format, e.g., '+8801XXXXXXXXX').
  final String? email;  // Optional for multi-modal auth (FR-001).
  final String token;  // JWT for API auth (includes role in payload).
  final Role role;  // Core of RBAC, determines permissions.

  const UserEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.token,
    required this.role,
  });

  // Factory for JSON deserialization (from API response).
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      token: json['token'] as String,
      role: Role.values.firstWhere(
        (r) => r.toString() == 'Role.${json['role']}',
        orElse: () => Role.customer,  // Default to customer for safety.
      ),
    );
  }

  // Serialize to JSON for storage or API.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'token': token,
        'role': role.toString().split('.').last,
      };
}