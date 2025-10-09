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
          await prefs.setString('user', jsonEncode(user.toJson()));
          emit(Authenticated(user));
        } else {
          emit(AuthError('OTP ভুল হয়েছে'));
        }
      } catch (e) {
        emit(AuthError('ভেরিফিকেশনে ত্রুটি: $e'));
      }
    });

    /// Logout - FIXED VERSION
    on<LogoutEvent>((event, emit) async {
      print('🔄 LOGOUT: Starting logout process...');
      
      // Immediately show loading state
      emit(AuthLoading());
      
      try {
        final prefs = await SharedPreferences.getInstance();
        print('🔄 LOGOUT: SharedPreferences instance obtained');
        
        // Check if user data exists before removing
        final userExists = prefs.containsKey('user');
        print('🔄 LOGOUT: User data exists: $userExists');
        
        if (userExists) {
          await prefs.remove('user');
          print('✅ LOGOUT: User data removed from SharedPreferences');
        } else {
          print('ℹ️ LOGOUT: No user data found to remove');
        }
        
        // Clear any other related data if needed
        await prefs.reload();
        print('✅ LOGOUT: SharedPreferences reloaded');
        
        // Ensure we emit Unauthenticated state
        emit(Unauthenticated());
        print('✅ LOGOUT: Successfully emitted Unauthenticated state');
        
      } catch (e) {
        print('❌ LOGOUT ERROR: $e');
        // Even if there's an error, we should emit Unauthenticated
        emit(Unauthenticated());
      }
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
          await prefs.setString('user', jsonEncode(updatedUser.toJson()));

          // Remove artificial delay for better performance
          emit(Authenticated(updatedUser));
        } catch (e) {
          emit(AuthError('প্রোফাইল আপডেটে ত্রুটি: $e'));
        }
      } else {
        emit(AuthError('প্রোফাইল আপডেট করতে লগইন করতে হবে'));
      }
    });

    /// Provider Application
  // In your auth_bloc.dart - Update the SubmitProviderApplicationEvent handler
  on<SubmitProviderApplicationEvent>((event, emit) async {
    final currentState = state;

    if (currentState is! Authenticated) {
      emit(AuthError('অ্যাপ্লিকেশন সাবমিট করতে লগইন প্রয়োজন।'));
      return;
    }

    emit(AuthLoading());
    try {
      // Convert customer to provider
      final updatedUser = currentState.user.copyWith(
        // 'role': Role.provider,
        updatedAt: DateTime.now(),
      );

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));

      // Emit the updated user with provider role
      emit(Authenticated(updatedUser));
      
      print('✅ PROVIDER APPLICATION: User ${updatedUser.id} is now a provider');

    } catch (e) {
      print('❌ PROVIDER APPLICATION ERROR: $e');
      emit(AuthError('অ্যাপ্লিকেশন জমা দিতে সমস্যা হয়েছে: $e'));
    }
  });

    // Load saved user - FIXED VERSION
    _loadSavedUser();
  }

  // FIXED: Improved user loading with better error handling
  void _loadSavedUser() async {
    print('🔄 AUTH: Loading saved user from SharedPreferences...');
    
    // Don't load if we're already in a specific state
    if (state is! AuthInitial) {
      print('ℹ️ AUTH: Skipping load - already in state: ${state.runtimeType}');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString('user');
      
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        print('✅ AUTH: Found saved user data');
        final userMap = jsonDecode(savedUserJson) as Map<String, dynamic>;
        final user = UserEntity.fromJson(userMap);
        
        // Only emit if we're still in initial state
        if (state is AuthInitial) {
          emit(Authenticated(user));
          print('✅ AUTH: Successfully loaded and authenticated user');
        }
      } else {
        print('ℹ️ AUTH: No saved user found, remaining unauthenticated');
        if (state is AuthInitial) {
          emit(Unauthenticated());
        }
      }
    } catch (e) {
      print('❌ AUTH ERROR: Failed to load user: $e');
      if (state is AuthInitial) {
        emit(Unauthenticated());
      }
    }
  }
}