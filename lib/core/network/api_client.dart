// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsheba/core/utils/dummy_data.dart';

import '../../features/provider/domain/entities/provider_application.dart'; // New Import

class ApiClient {
  static const String baseUrl = 'https://dummyapi.example.com';

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    // Dummy API simulation for dev.
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'message': 'OTP sent to $phoneNumber (dummy: 123456)'
    };
  }

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

  /// 🆕 Provider Application Submit
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
}
