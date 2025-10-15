import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
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
  final Position? location;

  UpdateProfileEvent({
    required this.name,
    this.email,
    this.address,
    this.city,
    this.postalCode,
    this.gender,
    this.dateOfBirth,
    this.profileImageUrl,
    this.location,
  });
}

class SubmitProviderApplicationEvent extends AuthEvent {
  final ProviderApplication application;
  SubmitProviderApplicationEvent(this.application);
}

class SwitchRoleEvent extends AuthEvent {
  final Role newRole;
  SwitchRoleEvent(this.newRole);
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
    /// --- SEND OTP ---
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

    /// --- VERIFY OTP ---
    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await ApiClient.verifyOtp(event.phoneNumber, event.otp);
        if (response['success']) {
          final userJson = response['user'] as Map<String, dynamic>;
          final user = UserEntity.fromJson({...userJson, 'token': response['token']});
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(user.toJson()));
          emit(Authenticated(user));
        } else {
          emit(AuthError('OTP ভুল হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('ভেরিফিকেশনে ত্রুটি: $e'));
      }
    });

    /// --- LOGOUT ---
    on<LogoutEvent>((event, emit) async {
      print('🔄 LOGOUT: Starting logout process...');
      emit(AuthLoading());
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('user')) {
          await prefs.remove('user');
          print('✅ LOGOUT: User data removed');
        } else {
          print('ℹ️ LOGOUT: No user data found');
        }
        await prefs.reload();
        emit(Unauthenticated());
        print('✅ LOGOUT: Successfully emitted Unauthenticated state');
      } catch (e) {
        print('❌ LOGOUT ERROR: $e');
        emit(Unauthenticated());
      }
    });

    /// --- UPDATE PROFILE ---
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
            location: event.location,
            updatedAt: DateTime.now(),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(updatedUser.toJson()));

          emit(Authenticated(updatedUser));
        } catch (e) {
          emit(AuthError('প্রোফাইল আপডেটে ত্রুটি: $e'));
        }
      } else {
        emit(AuthError('প্রোফাইল আপডেট করতে লগইন করতে হবে'));
      }
    });

    /// --- SUBMIT PROVIDER APPLICATION ---
    on<SubmitProviderApplicationEvent>((event, emit) async {
      final currentState = state;

      if (currentState is! Authenticated) {
        emit(AuthError('অ্যাপ্লিকেশন সাবমিট করতে লগইন প্রয়োজন।'));
        return;
      }

      emit(AuthLoading());
      try {
        final updatedUser = currentState.user.copyWith(
          updatedAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(updatedUser.toJson()));

        emit(Authenticated(updatedUser));
        print('✅ PROVIDER APPLICATION: User ${updatedUser.id} is now a provider');
      } catch (e) {
        print('❌ PROVIDER APPLICATION ERROR: $e');
        emit(AuthError('অ্যাপ্লিকেশন জমা দিতে সমস্যা হয়েছে: $e'));
      }
    });

    /// --- SWITCH ROLE ---
    on<SwitchRoleEvent>((event, emit) async {
      final currentState = state;
      
      if (currentState is! Authenticated) {
        emit(AuthError('রোল পরিবর্তন করতে লগইন প্রয়োজন।'));
        return;
      }

      emit(AuthLoading());
      
      try {
        final response = await ApiClient.switchUserRole(
          currentState.user.id, 
          event.newRole
        );

        if (response['success']) {
          final userJson = response['user'] as Map<String, dynamic>;
          
          // Create updated user with new role
          final updatedUser = currentState.user.copyWith(
            id: userJson['id'] as String,
            role: event.newRole,
            updatedAt: DateTime.now(),
          );

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(updatedUser.toJson()));

          emit(Authenticated(updatedUser));
          print('✅ ROLE SWITCH: User role changed to ${event.newRole.name}');
        } else {
          emit(AuthError(response['message'] ?? 'রোল পরিবর্তন ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('রোল পরিবর্তনে ত্রুটি: $e'));
      }
    });

    /// --- LOAD SAVED USER ---
    _loadSavedUser();
  }

  /// Helper: Load saved user from SharedPreferences
  void _loadSavedUser() async {
    print('🔄 AUTH: Loading saved user...');
    if (state is! AuthInitial) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString('user');

      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        final userMap = jsonDecode(savedUserJson) as Map<String, dynamic>;
        final user = UserEntity.fromJson(userMap);
        emit(Authenticated(user));
        print('✅ AUTH: User loaded successfully');
      } else {
        emit(Unauthenticated());
        print('ℹ️ AUTH: No saved user found');
      }
    } catch (e) {
      emit(Unauthenticated());
      print('❌ AUTH ERROR: Failed to load user: $e');
    }
  }
}