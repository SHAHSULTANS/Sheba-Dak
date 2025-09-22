import 'package:equatable/equatable.dart';
import 'package:smartsheba/core/utils/enums.dart';

class UserEntity extends Equatable {
  final String id;
  final String? name;
  final String phone;
  final String? authToken;
  final Role role;

  const UserEntity({
    required this.id,
    this.name,
    required this.phone,
    this.authToken,
    this.role = Role.unassigned,
  });

  @override
  List<Object?> get props => [id, name, phone, authToken, role];

  UserEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? authToken,
    Role? role,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      authToken: authToken ?? this.authToken,
      role: role ?? this.role,
    );
  }
}