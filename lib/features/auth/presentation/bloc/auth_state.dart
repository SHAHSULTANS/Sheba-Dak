import 'package:equatable/equatable.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

// Initial state, before any checks.
class AuthInitial extends AuthState {}

// State when authentication is in progress.
class AuthLoading extends AuthState {}

// State for an authenticated user.
class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated(this.user);
  @override
  List<Object> get props => [user];
}

// State for a user who is not authenticated.
class Unauthenticated extends AuthState {}

// State for an authentication error.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}