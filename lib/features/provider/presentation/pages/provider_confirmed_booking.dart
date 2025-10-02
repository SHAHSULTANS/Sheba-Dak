import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';

class ConfirmedBookingsPage extends StatelessWidget {
  const ConfirmedBookingsPage({super.key});

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
          'গ্রহণকৃত বুকিংস',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/provider-dashboard'),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated && state.user.role == Role.provider) {
            // Get confirmed and in-progress bookings
            final confirmedBookings = DummyData.getBookingsByProvider(state.user.id)
                .where((booking) =>
                    booking.status == BookingStatus.confirmed ||
                    booking.status == BookingStatus.inProgress)
                .toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            if (confirmedBookings.isEmpty) {
              return _buildEmptyState(context, theme);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: confirmedBookings.length,
              itemBuilder: (context, index) {
                final booking = confirmedBookings[index];
                return _buildConfirmedBookingCard(context, booking, theme);
              },
            );
          }

          return _buildUnauthorizedState(context, theme);
        },
      ),
    );
  }

  Widget _buildConfirmedBookingCard(BuildContext context, BookingEntity booking, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getStatusColor(booking.status).withOpacity(0.1),
                  child: Icon(
                    _getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.serviceCategory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            _buildInfoRow(Icons.calendar_today, 'তারিখ: ${_formatDate(booking.scheduledAt)}', theme),
            _buildInfoRow(Icons.access_time, 'সময়: ${_formatTime(booking.scheduledAt)}', theme),
            _buildInfoRow(Icons.attach_money, 'মূল্য: ৳${booking.price.toStringAsFixed(0)}', theme),
            if (booking.description != null && booking.description!.isNotEmpty)
              _buildInfoRow(Icons.description, 'বিবরণ: ${booking.description!}', theme),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(context, booking),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingEntity booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Chat Button
        IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
          onPressed: () {
            // Assuming chat route is implemented
            context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}');
          },
          tooltip: 'গ্রাহকের সাথে চ্যাট করুন',
        ),

        // Status Update Buttons
        Row(
          children: [
            if (booking.status == BookingStatus.confirmed)
              ElevatedButton.icon(
                onPressed: () => _updateToInProgress(context, booking),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('কাজ শুরু করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),

            if (booking.status == BookingStatus.inProgress) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _updateToCompleted(context, booking),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('সম্পন্ন করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _updateToInProgress(BuildContext context, BookingEntity booking) {
    // TODO: Implement BLoC event to update booking status to inProgress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('কাজ শুরু করা হয়েছে'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _updateToCompleted(BuildContext context, BookingEntity booking) {
    // TODO: Implement BLoC event to update booking status to completed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('কাজ সম্পন্ন করা হয়েছে'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'কোনো গ্রহণকৃত বুকিং নেই',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'ইনকামিং রিকোয়েস্ট থেকে বুকিং গ্রহণ করুন',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/incoming-requests'),
            icon: const Icon(Icons.list_alt),
            label: const Text('ইনকামিং রিকোয়েস্ট দেখুন'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'অনুমোদিত নয়',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'শুধুমাত্র প্রোভাইডাররা এই পৃষ্ঠাটি দেখতে পারেন',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Helper methods for status display
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green.shade700;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.inProgress:
        return Icons.build_circle_outlined;
      case BookingStatus.completed:
        return Icons.verified;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.pending:
        return Icons.pending_actions;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'গ্রহণ করা হয়েছে';
      case BookingStatus.inProgress:
        return 'চলমান';
      case BookingStatus.completed:
        return 'সম্পন্ন';
      case BookingStatus.cancelled:
        return 'বাতিল';
      case BookingStatus.pending:
        return 'অপেক্ষমাণ';
    }
  }

  String _formatDate(DateTime date) => '${date.day}-${date.month}-${date.year}';

  String _formatTime(DateTime date) {
    final time = TimeOfDay.fromDateTime(date);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
