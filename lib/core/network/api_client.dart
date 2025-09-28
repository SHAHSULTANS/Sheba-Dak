// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// 🆕 Uuid & BookingEntity ইমপোর্ট
import 'package:uuid/uuid.dart';
import '../../features/booking/domain/entities/booking_entity.dart';

import 'package:smartsheba/core/utils/dummy_data.dart';
import '../../features/provider/domain/entities/provider_application.dart';

class ApiClient {
  static const String baseUrl = 'https://dummyapi.example.com';

  // -------------------- OTP পাঠানো --------------------
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    // Dummy API simulation for dev.
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'message': 'OTP sent to $phoneNumber (dummy: 123456)'
    };
  }

  // -------------------- OTP ভেরিফাই --------------------
  static Future<Map<String, dynamic>> verifyOtp(
      String phoneNumber, String otp) async {
    // Dummy verification: Success if OTP is '123456'.
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '123456') {
      return {
        'success': true,
        'token': 'dummy_jwt_token',
        'user': {
          'id': 'e8e616e0-d894-4936-a3f5-391682ee794c',
          'name': 'Test User',
          'phone_number': phoneNumber,
          'role': 'customer'
        }
      };
    } else {
      throw Exception('Invalid OTP');
    }
  }

  // -------------------- প্রোফাইল আপডেট --------------------
  static Future<Map<String, dynamic>> updateProfile(
      String id, String name, String? email, String? address) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'user': {
        'id': id,
        'name': name,
        'phone_number': 'dummy_phone',
        'email': email,
        'role': 'customer',
        'address': address,
      },
      'token': 'updated_dummy_jwt',
    };
  }

  // -------------------- প্রোভাইডার অ্যাপ্লিকেশন সাবমিট --------------------
  static Future<Map<String, dynamic>> submitProviderApplication(
      ProviderApplication application) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate successful submission and save to DummyData for admin review
    DummyData.addProviderApplication(application);

    return {
      'success': true,
      'message': 'Application submitted (pending approval)'
    };
  }

  // ============================
  // 🆕 Booking API Simulation
  // ============================
  static Future<Map<String, dynamic>> createBooking(
    String customerId,
    String providerId,
    String serviceCategory,
    DateTime scheduledAt,
    double price,
    String? description,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate a unique ID for the new booking
    final id = const Uuid().v4();

    // Create the Booking Entity
    final booking = BookingEntity(
      id: id,
      customerId: customerId,
      providerId: providerId,
      serviceCategory: serviceCategory,
      scheduledAt: scheduledAt,
      status: BookingStatus.pending, // Default status for new bookings
      price: price,
      description: description,
    );

    // Store the booking in our dummy database
    DummyData.addBooking(booking);

    // Return the simulated API response
    return {
      'success': true,
      'id': id,
      'status': 'pending',
      'message': 'বুকিং সফলভাবে তৈরি হয়েছে (নিশ্চিতকরণের অপেক্ষায়)',
    };
  }
}
