import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import '../../domain/entities/booking_entity.dart';

class IncomingRequestsPage extends StatelessWidget {
  const IncomingRequestsPage({super.key});

  Future<void> _updateBookingStatus(BuildContext context, String bookingId, BookingStatus status) async {
    try {
      final state = context.read<AuthBloc>().state;
      if (state is Authenticated) {
        final result = await ApiClient.updateBookingStatus(bookingId, status, 'provider');
        print('DEBUG: Booking $bookingId updated to $status');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: status == BookingStatus.cancelled ? AppColors.error : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error updating booking $bookingId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ত্রুটি: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
          'নতুন বুকিং রিকোয়েস্ট',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/provider-dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _refreshBookings(context),
            tooltip: 'রিফ্রেশ করুন',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated && state.user.role == Role.provider) {
            final bookings = DummyData.getPendingBookingsByProvider(state.user.id);
            print('DEBUG: Bookings found for provider ${state.user.id}: ${bookings.length}');

            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'কোনো নতুন রিকোয়েস্ট নেই',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'গ্রাহকদের রিকোয়েস্ট এলে এখানে দেখানো হবে',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/provider-dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ড্যাশবোর্ডে ফিরুন'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refreshBookings(context),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildBookingCard(context, booking, theme);
                },
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'অনুমোদিত নয়: শুধুমাত্র প্রোভাইডাররা দেখতে পারেন',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/provider-dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ড্যাশবোর্ডে ফিরুন'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshBookings(BuildContext context) async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated && state.user.role == Role.provider) {
      try {
        final bookings = await ApiClient.getBookingsByUser(state.user.id, 'provider');
        print('DEBUG: Refreshed bookings: ${bookings.length}');
        // DummyData আপডেট করার জন্য অ্যাপ্লিকেশন স্টেট ম্যানেজ করতে হবে
        // এখানে আমরা শুধুমাত্র UI রিফ্রেশ করছি
      } catch (e) {
        print('DEBUG: Error refreshing bookings: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('রিফ্রেশ করতে সমস্যা: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBookingCard(BuildContext context, BookingEntity booking, ThemeData theme) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            print('DEBUG: Navigating to chat for booking ${booking.id}');
            context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        _getCategoryIcon(booking.serviceCategory),
                        color: theme.primaryColor,
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
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'অপেক্ষমাণ',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'তারিখ: ${_formatDate(booking.scheduledAt)}',
                  theme,
                ),
                _buildInfoRow(
                  Icons.access_time,
                  'সময়: ${_formatTime(booking.scheduledAt)}',
                  theme,
                ),
                _buildInfoRow(
                  Icons.attach_money,
                  'মূল্য: ৳${booking.price.toStringAsFixed(0)}',
                  theme,
                ),
                if (booking.description != null && booking.description!.isNotEmpty)
                  _buildInfoRow(
                    Icons.description,
                    'বিবরণ: ${booking.description}',
                    theme,
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChatButton(context, booking),
                    Row(
                      children: [
                        _buildAcceptButton(context, booking),
                        const SizedBox(width: 8),
                        _buildDeclineButton(context, booking),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildChatButton(BuildContext context, BookingEntity booking) {
    return IconButton(
      icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
      onPressed: () {
        print('DEBUG: Chat button clicked for booking ${booking.id}');
        print('DEBUG: Navigating to /chat/${booking.id}/${booking.customerId}/${booking.providerId}');
        print('DEBUG: Current user: ${context.read<AuthBloc>().state is Authenticated ? (context.read<AuthBloc>().state as Authenticated).user.id : 'Not authenticated'}');
      // context
        GoRouter.of(context).go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}');
      },
      tooltip: 'গ্রাহকের সাথে চ্যাট করুন',
    );
  }

  Widget _buildAcceptButton(BuildContext context, BookingEntity booking) {
    return ElevatedButton(
      onPressed: () => _updateBookingStatus(context, booking.id, BookingStatus.confirmed),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('গ্রহণ করুন', style: TextStyle(fontSize: 14)),
    );
  }

  Widget _buildDeclineButton(BuildContext context, BookingEntity booking) {
    return OutlinedButton(
      onPressed: () => _updateBookingStatus(context, booking.id, BookingStatus.cancelled),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('প্রত্যাখ্যান করুন', style: TextStyle(fontSize: 14, color: Colors.red)),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  String _formatTime(DateTime date) {
    final time = TimeOfDay.fromDateTime(date);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}