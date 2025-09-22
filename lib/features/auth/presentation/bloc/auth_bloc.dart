import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';

// Events
abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String phoneNumber;
  final String otp; // Placeholder for Week 2 OTP logic.
  LoginEvent(this.phoneNumber, this.otp);
}

class LogoutEvent extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      // Placeholder: Week 2 will add API call to /auth/login.
      // For now, simulate success with dummy user.
      try {
        final user = UserEntity(
          id: 'e8e616e0-d894-4936-a3f5-391682ee794c',
          name: 'Test User',
          phoneNumber: event.phoneNumber,
          token: 'dummy_jwt',
          role: Role.customer,
        );
        emit(Authenticated(user));
      } catch (e) {
        emit(AuthError('Login failed: $e'));
      }
    });

    on<LogoutEvent>((event, emit) {
      emit(Unauthenticated());
    });
  }
}