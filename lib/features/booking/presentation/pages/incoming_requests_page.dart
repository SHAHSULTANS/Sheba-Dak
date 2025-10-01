import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';

// import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dummy_data.dart';
import '../../domain/entities/booking_entity.dart';

class IncomingRequestsPage extends StatelessWidget {
  const IncomingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
            ),
          ),
        ),
        title: const Text('নতুন বুকিং রিকোয়েস্ট',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/provider-dashboard'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ বুকিং স্ট্যাটাস আপডেট সফল'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ত্রুটি: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is Authenticated && state.user.role == Role.provider) {
            final bookings =
                DummyData.getPendingBookingsByProvider(state.user.id);

            if (bookings.isEmpty) {
              return Center(
                child: Text(
                  'কোনো নতুন রিকোয়েস্ট নেই',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _buildBookingCard(context, booking, theme);
              },
            );
          }

          return Center(
            child: Text(
              'অনুমোদিত নয়: শুধুমাত্র প্রোভাইডাররা দেখতে পারেন',
              style:
                  theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, BookingEntity booking, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.serviceCategory,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.circle,
                    color: Colors.orange, size: 12), // Pending indicator
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'তারিখ: ${booking.scheduledAt.toString().substring(0, 16)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'মূল্য: ৳${booking.price.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            if (booking.description != null) ...[
              const SizedBox(height: 4),
              Text(
                'বিবরণ: ${booking.description}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildAcceptButton(context, booking),
                const SizedBox(width: 8),
                _buildDeclineButton(context, booking),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, BookingEntity booking) {
    return ElevatedButton(
      onPressed: () {
        context
            .read<AuthBloc>()
            .add(UpdateBookingStatusEvent(booking.id, BookingStatus.confirmed));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('গ্রহণ করুন', style: TextStyle(fontSize: 14)),
    );
  }

  Widget _buildDeclineButton(BuildContext context, BookingEntity booking) {
    return OutlinedButton(
      onPressed: () {
        context
            .read<AuthBloc>()
            .add(UpdateBookingStatusEvent(booking.id, BookingStatus.cancelled));
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('প্রত্যাখ্যান করুন',
          style: TextStyle(fontSize: 14, color: Colors.red)),
    );
  }
}
