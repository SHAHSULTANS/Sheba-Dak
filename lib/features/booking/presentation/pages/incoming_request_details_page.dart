import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';

class IncomingRequestDetailsPage extends StatelessWidget {
  final String id;

  const IncomingRequestDetailsPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Rendering IncomingRequestDetailsPage for booking ID: $id');
    // Get current user's role from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final authRole = authState is Authenticated ? authState.user.role.toString().split('.').last : 'unknown';
    print('DEBUG: Current user role: $authRole');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ইনকামিং রিকোয়েস্ট'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.push('/provider-dashboard'),
        ),
      ),
      body: FutureBuilder<List<BookingEntity>>(
        future: ApiClient.getBookingsByUser('provider1', 'provider'), // Adjust for dynamic user
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            print('DEBUG: Error loading bookings: ${snapshot.error}');
            return const Center(child: Text('বুকিং খুঁজে পাওয়া যায়নি'));
          }
          final booking = snapshot.data!.firstWhere(
            (b) => b.id == id,
            orElse: () => BookingEntity(
              id: 'error',
              customerId: '',
              providerId: '',
              serviceCategory: '',
              scheduledAt: DateTime.now(),
              status: BookingStatus.cancelled,
              price: 0.0,
            ),
          );
          if (booking.id == 'error') {
            print('DEBUG: Booking not found for ID: $id');
            return const Center(child: Text('বুকিং খুঁজে পাওয়া যায়নি'));
          }
          final customer = DummyData.getUserById(booking.customerId);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('বুকিং আইডি: ${booking.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('সেবা: ${booking.serviceCategory}'),
                const SizedBox(height: 8),
                Text('গ্রাহক: ${customer.name}'),
                const SizedBox(height: 8),
                Text('ঠিকানা: ${customer.address}, ${customer.city}'),
                const SizedBox(height: 8),
                Text('বিবরণ: ${booking.description ?? "বিবরণ নেই"}'),
                const SizedBox(height: 8),
                Text('মূল্য: ৳${booking.price.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                Text('সময়: ${_formatDateTime(booking.scheduledAt)}'),
                const SizedBox(height: 8),
                Text('স্ট্যাটাস: ${_getStatusText(booking.status)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        print('DEBUG: Accepting booking ${booking.id}');
                        try {
                          final result = await ApiClient.updateBookingStatus(
                            booking.id,
                            BookingStatus.confirmed,
                            authRole,
                          );
                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('বুকিং গ্রহণ করা হয়েছে')),
                            );
                            context.push('/provider-dashboard');
                          } else {
                            throw Exception(result['message']);
                          }
                        } catch (e) {
                          print('DEBUG: Error accepting booking: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ত্রুটি: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('গ্রহণ করুন'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        print('DEBUG: Rejecting booking ${booking.id}');
                        try {
                          final result = await ApiClient.updateBookingStatus(
                            booking.id,
                            BookingStatus.cancelled,
                            authRole,
                          );
                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('বুকিং প্রত্যাখ্যান করা হয়েছে')),
                            );
                            context.push('/provider-dashboard');
                          } else {
                            throw Exception(result['message']);
                          }
                        } catch (e) {
                          print('DEBUG: Error rejecting booking: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ত্রুটি: $e')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('প্রত্যাখ্যান করুন'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr, $timeStr';
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'অপেক্ষমাণ';
      case BookingStatus.paymentPending:
        return 'পেমেন্ট অপেক্ষমাণ';
      case BookingStatus.confirmed:
        return 'গ্রহণ করা হয়েছে';
      case BookingStatus.paymentCompleted:
        return 'পেমেন্ট সম্পন্ন';
      case BookingStatus.inProgress:
        return 'চলমান';
      case BookingStatus.completed:
        return 'সম্পন্ন';
      case BookingStatus.cancelled:
        return 'বাতিল';
    }
  }
}