import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsheba/core/network/api_client.dart';
import '../../../provider/domain/entities/provider_application.dart';
import '../../domain/entities/user_entity.dart';

/// --- EVENTS ---
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

class UpdateProfileEvent extends AuthEvent {
  final String name;
  final String? email;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? profileImageUrl;

  UpdateProfileEvent({
    required this.name,
    this.email,
    this.address,
    this.city,
    this.postalCode,
    this.gender,
    this.dateOfBirth,
    this.profileImageUrl,
  });
}

class SubmitProviderApplicationEvent extends AuthEvent {
  final ProviderApplication application;
  SubmitProviderApplicationEvent(this.application);
}

/// --- STATES ---
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

class OtpSent extends AuthState {
  final String phoneNumber;
  OtpSent(this.phoneNumber);
}

/// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    /// Send OTP
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.sendOtp(event.phoneNumber);

        if (response['success']) {
          print('✅ OTP sent successfully to ${event.phoneNumber}');
          emit(OtpSent(event.phoneNumber));
        } else {
          emit(AuthError('OTP পাঠানো ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('OTP পাঠানোর সময় ত্রুটি: $e'));
      }
    });

    /// Verify OTP
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
          emit(AuthError('OTP ভুল হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('ভেরিফিকেশনে ত্রুটি: $e'));
      }
    });

    /// Logout
    on<LogoutEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('user');
      emit(Unauthenticated());
    });

    /// Enhanced Profile Update
    on<UpdateProfileEvent>((event, emit) async {
      final currentState = state;
      if (currentState is Authenticated) {
        emit(AuthLoading());
        try {
          Gender? genderEnum;
          if (event.gender != null) {
            genderEnum = UserEntity.genderFromString(event.gender);
          }

          final updatedUser = currentState.user.copyWith(
            name: event.name,
            email: event.email,
            address: event.address,
            city: event.city,
            postalCode: event.postalCode,
            gender: genderEnum,
            dateOfBirth: event.dateOfBirth,
            profileImageUrl: event.profileImageUrl,
            updatedAt: DateTime.now(),
          );

          final prefs = await SharedPreferences.getInstance();
          prefs.setString('user', jsonEncode(updatedUser.toJson()));

          await Future.delayed(const Duration(seconds: 1));

          emit(Authenticated(updatedUser));
        } catch (e) {
          emit(AuthError('প্রোফাইল আপডেটে ত্রুটি: $e'));
        }
      } else {
        emit(AuthError('প্রোফাইল আপডেট করতে লগইন করতে হবে'));
      }
    });

    /// Provider Application
    on<SubmitProviderApplicationEvent>((event, emit) async {
      final currentState = state;

      if (currentState is! Authenticated) {
        emit(AuthError('অ্যাপ্লিকেশন সাবমিট করতে লগইন প্রয়োজন।'));
        return;
      }

      emit(AuthLoading());
      try {
        final response =
            await ApiClient.submitProviderApplication(event.application);

        if (response['success']) {
          emit(Authenticated(currentState.user));
        } else {
          emit(AuthError(response['message'] ?? 'অ্যাপ্লিকেশন ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('অ্যাপ্লিকেশন ত্রুটি: $e'));
      }
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