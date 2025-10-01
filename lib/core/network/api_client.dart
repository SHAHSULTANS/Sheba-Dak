import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsheba/features/chat/domain/entities/chat_message.dart';
import 'package:uuid/uuid.dart';

import '../../features/booking/domain/entities/booking_entity.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import '../../features/provider/domain/entities/provider_application.dart';

class ApiClient {
  static const String baseUrl = 'https://dummyapi.example.com';

  // -------------------- OTP পাঠানো --------------------
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'message': 'OTP sent to $phoneNumber (dummy: 123456)'
    };
  }

  // -------------------- OTP ভেরিফাই --------------------
  static Future<Map<String, dynamic>> verifyOtp(
      String phoneNumber, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '123456') {
      return {
        'success': true,
        'token': 'dummy_jwt_token',
        'user': {
          'id': 'provider1',
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
    await Future.delayed(const Duration(seconds: 1));
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
    await Future.delayed(const Duration(seconds: 1));

    final id = const Uuid().v4();

    final booking = BookingEntity(
      id: id,
      customerId: customerId,
      providerId: providerId,
      serviceCategory: serviceCategory,
      scheduledAt: scheduledAt,
      status: BookingStatus.pending,
      price: price,
      description: description,
    );

    DummyData.addBooking(booking);

    return {
      'success': true,
      'id': id,
      'status': 'pending',
      'message': 'বুকিং সফলভাবে তৈরি হয়েছে (নিশ্চিতকরণের অপেক্ষায়)',
    };
  }

  // ============================
  // 🆕 Update Booking Status API
  // ============================
  static Future<Map<String, dynamic>> updateBookingStatus(
    String id,
    BookingStatus newStatus,
    String authRole,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    // RBAC Check
    if (authRole != 'provider') {
      throw Exception(
          'Unauthorized (403 Forbidden): শুধুমাত্র প্রদানকারীরা স্ট্যাটাস আপডেট করতে পারে।');
    }

    final bookings = DummyData.getInternalBookingsList();
    final index = bookings.indexWhere((b) => b.id == id);

    if (index != -1) {
      final updatedBooking = bookings[index].copyWith(status: newStatus);
      bookings[index] = updatedBooking;

      return {
        'success': true,
        'id': id,
        'new_status': newStatus.toString().split('.').last,
        'message': 'বুকিং স্ট্যাটাস সফলভাবে আপডেট করা হয়েছে।',
      };
    }

    throw Exception('Booking not found: বুকিং আইডি খুঁজে পাওয়া যায়নি।');
  }


    // ============================
  // 🆕 Get Bookings By User API
  // ============================
  static Future<List<BookingEntity>> getBookingsByUser(
      String userId, String role) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay

    final bookings = DummyData.getInternalBookingsList();

    if (role == 'provider' || role == 'provider') {
      // provider হিসেবে শুধুমাত্র providerId ম্যাচ করুন
      return bookings.where((b) => b.providerId == userId).toList();
    } else {
      // customer হিসেবে শুধুমাত্র customerId ম্যাচ করুন
      return bookings.where((b) => b.customerId == userId).toList();
    }
  }





  static Future<Map<String, dynamic>> sendMessage(ChatMessage message, String authUserId, String bookingCustomerId, String bookingProviderId) async {
    await Future.delayed(const Duration(seconds: 1));
    if (authUserId != bookingCustomerId && authUserId != bookingProviderId) {
      throw Exception('Unauthorized: User not part of this booking');
    }
    final newMessage = ChatMessage(
      id: const Uuid().v4(),
      bookingId: message.bookingId,
      senderId: message.senderId,
      recipientId: message.recipientId,
      message: message.message,
      timestamp: DateTime.now(),
    );
    DummyData.addMessage(newMessage);
    return {'success': true, 'message': 'Message sent'};
  }

  static Future<List<ChatMessage>> fetchMessages(String bookingId, String authUserId, String bookingCustomerId, String bookingProviderId) async {
    await Future.delayed(const Duration(seconds: 1));
    if (authUserId != bookingCustomerId && authUserId != bookingProviderId) {
      throw Exception('Unauthorized: User not part of this booking');
    }
    return DummyData.getMessagesByBooking(bookingId);
  }


}
