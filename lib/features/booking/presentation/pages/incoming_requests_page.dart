// lib/features/booking/presentation/pages/incoming_requests_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';

class IncomingRequestsPage extends StatelessWidget {
  const IncomingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইনকামিং রিকোয়েস্ট'),
      ),
      body: FutureBuilder<List<BookingEntity>>(
        future: ApiClient.getBookingsByUser('provider1', 'provider'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('কোনো ইনকামিং রিকোয়েস্ট নেই'));
          }
          final bookings = snapshot.data!.where((b) => b.status == BookingStatus.pending).toList();
          if (bookings.isEmpty) {
            return const Center(child: Text('কোনো ইনকামিং রিকোয়েস্ট নেই'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final customer = DummyData.getUserById(booking.customerId);
              return Card(
                child: ListTile(
                  title: Text(booking.serviceCategory),
                  subtitle: Text('গ্রাহক: ${customer.name}'),
                  onTap: () => context.go('/incoming-requests/${booking.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}