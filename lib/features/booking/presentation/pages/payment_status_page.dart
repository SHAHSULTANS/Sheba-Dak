import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';
import 'package:smartsheba/core/theme/app_theme.dart';

class PaymentStatusPage extends StatelessWidget {
  final String id;

  const PaymentStatusPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
            ),
          ),
        ),
        title: const Text(
          'পেমেন্ট স্ট্যাটাস',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.push('/provider-dashboard'),
        ),
      ),
      body: FutureBuilder<List<BookingEntity>>(
        future: ApiClient.getBookingsByUser('provider1', 'provider'), // Adjust based on AuthBloc
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
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
                Text(
                  'স্ট্যাটাস: ${_getStatusText(booking.status)}',
                  style: TextStyle(color: _getStatusColor(booking.status), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (booking.status == BookingStatus.paymentPending)
                  const Text('পেমেন্ট প্রক্রিয়াধীন। অনুগ্রহ করে অপেক্ষা করুন।'),
                if (booking.status == BookingStatus.confirmed)
                  const Text('পেমেন্ট শুরু হয়নি। গ্রাহকের পেমেন্ট শুরু করার অপেক্ষায়।'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('গ্রাহকের সাথে চ্যাট করুন'),
                  onPressed: () => context.push('/chat/${booking.id}/${booking.customerId}/${booking.providerId}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.paymentPending:
        return Colors.deepOrange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.paymentCompleted:
        return Colors.green.shade700;
      case BookingStatus.inProgress:
        return AppColors.primary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
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