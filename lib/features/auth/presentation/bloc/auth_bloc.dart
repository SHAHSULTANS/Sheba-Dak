import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsheba/core/network/api_client.dart';
// import '../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  SendOtpEvent(this.phoneNumber);
}

class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;
  VerifyOtpEvent(this.phoneNumber, this.otp);
}

class LogoutEvent extends AuthEvent {}

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
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.sendOtp(event.phoneNumber);
        if (response['success']) {
          emit(AuthInitial()); // Or OtpSent state.
        } else {
          emit(AuthError('OTP send failed'));
        }
      } catch (e) {
        emit(AuthError('OTP send error: $e'));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.verifyOtp(event.phoneNumber, event.otp);
        if (response['success']) {
          final userJson = response['user'] as Map<String, dynamic>;
          final user = UserEntity.fromJson({...userJson, 'token': response['token']});
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('user', jsonEncode(user.toJson()));
          emit(Authenticated(user));
        } else {
          emit(AuthError('Invalid OTP'));
        }
      } catch (e) {
        emit(AuthError('Verification error: $e'));
      }
    });

    on<LogoutEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('user');
      emit(Unauthenticated());
    });

    _loadSavedUser();
  }

  void _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserJson = prefs.getString('user');
    if (savedUserJson != null) {
      try {
        final userMap = jsonDecode(savedUserJson) as Map<String, dynamic>;
        final user = UserEntity.fromJson(userMap);
        emit(Authenticated(user));
      } catch (e) {
        emit(Unauthenticated());
      }
    }
  }
}