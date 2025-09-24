import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://dummyapi.example.com';  // Replace with real backend URL in production.

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    // Dummy API simulation for dev.
    await Future.delayed(const Duration(seconds: 1));  // Simulate network delay.
    return {'success': true, 'message': 'OTP sent to $phoneNumber (dummy: 123456)'};
    // Real: http.post(Uri.parse('$baseUrl/auth/send-otp'), body: {'phone': phoneNumber});
  }

  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
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
          'role': 'customer'  // Backend returns role (e.g., 'customer' default).
        }
      };
    } else {
      throw Exception('Invalid OTP');
    }
    // Real: http.post(Uri.parse('$baseUrl/auth/verify-otp'), body: {'phone': phoneNumber, 'otp': otp});
  }
}