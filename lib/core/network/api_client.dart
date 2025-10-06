import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/chat/domain/entities/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';
import 'package:smartsheba/features/provider/domain/entities/provider_application.dart';

class ApiClient {
  static const String baseUrl = 'https://dummyapi.example.com';

  static Future<UserEntity> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final isCustomer = userId.startsWith('c');
    final Map<String, dynamic> mockJson = {
      'id': userId,
      'name': isCustomer ? 'Md. Karim' : 'Service Provider Ltd.',
      'phone_number': isCustomer ? '01712345678' : '01898765432',
      'email': isCustomer ? 'customer@example.com' : 'provider@example.com',
      'token': 'mock_token_$userId',
      'role': isCustomer ? 'customer' : 'provider',
      'address': 'Dhanmondi, Dhaka',
      'city': 'Dhaka',
      'postal_code': '1205',
      'gender': isCustomer ? 'male' : 'other',
      'date_of_birth': '1985-10-25T00:00:00.000Z',
      'profile_image_url': null,
      'is_verified': true,
      'created_at': DateTime.now().toIso8601String(),
    };
    return UserEntity.fromJson(mockJson);
  }

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'success': true,
      'message': 'OTP sent to $phoneNumber (dummy: 123456)'
    };
  }

  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '123456') {
      return {
        'success': true,
        'token': 'dummy_jwt_token',
        'user': {
          'id': 'provider1',
          'name': 'Test User',
          'phone_number': phoneNumber,
          'role': 'provider'
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

  static Future<Map<String, dynamic>> submitProviderApplication(
      ProviderApplication application) async {
    await Future.delayed(const Duration(seconds: 1));
    DummyData.addProviderApplication(application);
    return {
      'success': true,
      'message': 'Application submitted (pending approval)'
    };
  }

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

  static Future<Map<String, dynamic>> updateBookingStatus(
    String id,
    BookingStatus newStatus,
    String authRole,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    print('DEBUG: updateBookingStatus called with id: $id, newStatus: $newStatus, authRole: $authRole');

    // Role-based access control
    if (newStatus == BookingStatus.paymentPending && authRole != 'customer') {
      print('DEBUG: RBAC failure: paymentPending requires customer role');
      return {
        'success': false,
        'message': 'Unauthorized: শুধুমাত্র কাস্টমাররা পেমেন্ট শুরু করতে পারে।'
      };
    }
    if (newStatus == BookingStatus.confirmed && authRole != 'provider') {
      print('DEBUG: RBAC failure: confirmed requires provider role');
      return {
        'success': false,
        'message': 'Unauthorized: শুধুমাত্র প্রোভাইডাররা বুকিং কনফার্ম করতে পারে।'
      };
    }

    // Use the new public method to update booking status
    try {
      DummyData.updateBookingStatus(id, newStatus);
      print('DEBUG: Successfully updated booking: $id to status: $newStatus');
      
      return {
        'success': true,
        'id': id,
        'new_status': newStatus.toString().split('.').last,
        'message': 'বুকিং স্ট্যাটাস সফলভাবে আপডেট করা হয়েছে।',
      };
    } catch (e) {
      print('DEBUG: Error updating booking status: $e');
      return {
        'success': false,
        'message': 'বুকিং স্ট্যাটাস আপডেট করতে সমস্যা হয়েছে: $e'
      };
    }
  }

  static Future<List<BookingEntity>> getBookingsByUser(
      String userId, String role) async {
    await Future.delayed(const Duration(seconds: 1));
    if (role == 'provider') {
      return DummyData.getBookingsByProvider(userId);
    } else {
      return DummyData.getBookingsByCustomer(userId);
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
    ChatMessage message,
    String authUserId,
    String bookingCustomerId,
    String bookingProviderId,
  ) async {
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

  static Future<List<ChatMessage>> fetchMessages(
    String bookingId,
    String authUserId,
    String bookingCustomerId,
    String bookingProviderId,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    if (authUserId != bookingCustomerId && authUserId != bookingProviderId) {
      throw Exception('Unauthorized: User not part of this booking');
    }
    return DummyData.getMessagesByBooking(bookingId);
  }

  // Additional helper methods for better data access
  static Future<List<BookingEntity>> getPendingBookingsForProvider(String providerId) async {
    await Future.delayed(const Duration(seconds: 1));
    return DummyData.getPendingBookingsByProvider(providerId);
  }

  static Future<List<BookingEntity>> getCustomerBookingsWithStatus(
      String customerId, BookingStatus? status) async {
    await Future.delayed(const Duration(seconds: 1));
    return DummyData.getCustomerBookings(customerId, status: status);
  }

  static Future<List<ProviderApplication>> getPendingApplications() async {
    await Future.delayed(const Duration(seconds: 1));
    return DummyData.getPendingApplications();
  }

  static Future<UserEntity> getAuthenticatedUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return a default authenticated user (customer1)
    return DummyData.getUserById('customer1');
  }
}