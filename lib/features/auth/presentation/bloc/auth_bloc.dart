import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsheba/core/network/api_client.dart';

// ✅ নতুন ইমপোর্ট
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
  UpdateProfileEvent({required this.name, this.email, this.address});
}

/// ✅ নতুন ইভেন্ট
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

/// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    /// OTP পাঠানো
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.sendOtp(event.phoneNumber);
        if (response['success']) {
          emit(AuthInitial()); // অথবা OtpSent state
        } else {
          emit(AuthError('OTP send failed'));
        }
      } catch (e) {
        emit(AuthError('OTP send error: $e'));
      }
    });

    /// OTP ভেরিফিকেশন
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

    /// লগআউট
    on<LogoutEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('user');
      emit(Unauthenticated());
    });

    /// প্রোফাইল আপডেট
    on<UpdateProfileEvent>((event, emit) async {
      final currentState = state;
      if (currentState is Authenticated) {
        emit(AuthLoading());
        try {
          // Dummy API update.
          await Future.delayed(const Duration(seconds: 1));
          final updatedUser = currentState.user.copyWith(
            name: event.name,
            email: event.email,
            address: event.address,
          );
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('user', jsonEncode(updatedUser.toJson()));
          emit(Authenticated(updatedUser));
        } catch (e) {
          emit(AuthError('Profile update error: $e'));
        }
      }
    });

    /// ✅ নতুন হ্যান্ডলার — প্রোভাইডার অ্যাপ্লিকেশন সাবমিশন
    on<SubmitProviderApplicationEvent>((event, emit) async {
      final currentState = state;

      // আগে চেক করো ইউজার লগইন করেছে কিনা
      if (currentState is! Authenticated) {
        emit(AuthError('Authentication required to submit application.'));
        return;
      }

      emit(AuthLoading());
      try {
        final response = await ApiClient.submitProviderApplication(event.application);

        if (response['success']) {
          // সাবমিট সফল হয়েছে। 
          // অ্যাডমিন অ্যাপ্রুভ করার আগ পর্যন্ত ইউজার customer-ই থাকবে।
          emit(Authenticated(currentState.user));
        } else {
          emit(AuthError(response['message'] ?? 'Application submission failed.'));
        }
      } catch (e) {
        emit(AuthError('Submit error: $e'));
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
