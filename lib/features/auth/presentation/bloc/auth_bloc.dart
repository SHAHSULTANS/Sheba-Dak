import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🆕 ApiClient ও BookingEntity ইম্পোর্ট
import 'package:smartsheba/core/network/api_client.dart';
import '../../../../features/booking/domain/entities/booking_entity.dart';

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

class SubmitProviderApplicationEvent extends AuthEvent {
  final ProviderApplication application;
  SubmitProviderApplicationEvent(this.application);
}

/// 🆕 CreateBooking Event
class CreateBookingEvent extends AuthEvent {
  final String providerId;
  final String serviceCategory;
  final DateTime scheduledAt;
  final double price;
  final String? description;

  CreateBookingEvent({
    required this.providerId,
    required this.serviceCategory,
    required this.scheduledAt,
    required this.price,
    this.description,
  });
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

/// ✅ OTP পাঠানো হলে নতুন State
class OtpSent extends AuthState {
  final String phoneNumber;
  OtpSent(this.phoneNumber);
}

/// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    /// ✅ OTP পাঠানো
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.sendOtp(event.phoneNumber);

        if (response['success']) {
          print('✅ OTP sent successfully to ${event.phoneNumber}');
          emit(OtpSent(event.phoneNumber));
        } else {
          emit(AuthError('OTP পাঠানো ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('OTP পাঠানোর সময় ত্রুটি: $e'));
      }
    });

    /// ✅ OTP ভেরিফিকেশন
    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.verifyOtp(event.phoneNumber, event.otp);
        if (response['success']) {
          final userJson = response['user'] as Map<String, dynamic>;
          final user =
              UserEntity.fromJson({...userJson, 'token': response['token']});
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

    /// ✅ Logout
    on<LogoutEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('user');
      emit(Unauthenticated());
    });

    /// ✅ Profile Update
    on<UpdateProfileEvent>((event, emit) async {
      final currentState = state;
      if (currentState is Authenticated) {
        emit(AuthLoading());
        try {
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
          emit(AuthError('প্রোফাইল আপডেটে ত্রুটি: $e'));
        }
      }
    });

    /// ✅ Provider Application
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
          emit(AuthError(response['message'] ?? 'অ্যাপ্লিকেশন ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('অ্যাপ্লিকেশন ত্রুটি: $e'));
      }
    });

    /// 🆕 Create Booking Handler
    on<CreateBookingEvent>((event, emit) async {
      final currentState = state;

      if (currentState is Authenticated) {
        // Optional: Role Check করতে চাইলে uncomment করো
        // if (currentState.user.role != Role.customer) {
        //   emit(AuthError('শুধুমাত্র গ্রাহকরাই বুকিং করতে পারবেন।'));
        //   return;
        // }

        emit(AuthLoading());
        try {
          final response = await ApiClient.createBooking(
            currentState.user.id,
            event.providerId,
            event.serviceCategory,
            event.scheduledAt,
            event.price,
            event.description,
          );

          if (response['success']) {
            emit(Authenticated(currentState.user));
          } else {
            emit(AuthError('বুকিং ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'));
          }
        } catch (e) {
          emit(AuthError('বুকিং করার সময় ত্রুটি: $e'));
        }
      } else {
        emit(AuthError('বুকিং দিতে লগইন করতে হবে।'));
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
