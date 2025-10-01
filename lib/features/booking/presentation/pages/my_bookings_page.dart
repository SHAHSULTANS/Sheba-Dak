import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import '../../domain/entities/booking_entity.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  List<BookingEntity> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final state = context.read<AuthBloc>().state;

    if (state is Authenticated) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        final bookings = await ApiClient.getBookingsByUser(state.user.id, 'customer');

        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'বুকিং লোড করতে সমস্যা হয়েছে: ${e.toString()}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'লগইন প্রয়োজন';
        _isLoading = false;
      });
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'অপেক্ষমাণ';
      case BookingStatus.confirmed:
        return 'নিশ্চিত';
      case BookingStatus.inProgress:
        return 'চলমান';
      case BookingStatus.completed:
        return 'সম্পন্ন';
      case BookingStatus.cancelled:
        return 'বাতিল';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return AppColors.primary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.pending_actions;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.inProgress:
        return Icons.build_circle_outlined;
      case BookingStatus.completed:
        return Icons.verified;
      case BookingStatus.cancelled:
        return Icons.cancel;
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
          'আমার বুকিংস',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (context.read<AuthBloc>().state is Authenticated &&
              (context.read<AuthBloc>().state as Authenticated).user.role == Role.provider)
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () => context.go('/incoming-requests'),
              tooltip: 'ইনকামিং রিকোয়েস্ট দেখুন',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'রিফ্রেশ করুন',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('বুকিং লোড হচ্ছে...'),
                ],
              ),
            );
          }

          if (_errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }

          if (state is! Authenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'বুকিং দেখতে লগইন করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('লগইন করুন'),
                  ),
                ],
              ),
            );
          }

          final user = state.user;
          final isProvider = user.role == Role.provider;

          if (_bookings.isEmpty) {
            return _buildEmptyView(isProvider);
          }

          final activeBookings = _bookings.where((b) =>
              b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.inProgress).toList();

          final historyBookings = _bookings.where((b) =>
              b.status == BookingStatus.completed ||
              b.status == BookingStatus.cancelled).toList();

          return RefreshIndicator(
            onRefresh: _loadBookings,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              children: [
                if (isProvider)
                  _buildProviderHeader(),
                if (activeBookings.isNotEmpty)
                  _buildSectionHeader('আসন্ন ও চলমান বুকিংস (${activeBookings.length})'),
                ...activeBookings.map((b) => _buildBookingCard(context, b)),
                if (historyBookings.isNotEmpty)
                  _buildSectionHeader('ইতিহাস (${historyBookings.length})'),
                ...historyBookings.map((b) => _buildBookingCard(context, b)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(bool isProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isProvider
                ? 'আপনার কোনো বুক করা সেবা নেই'
                : 'আপনার কোনো বুকিং নেই',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            isProvider
                ? 'অন্য প্রোভাইডারের সেবা বুক করুন'
                : 'নতুন সেবা বুক করে শুরু করুন',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('সেবা খুঁজুন'),
          ),
          if (isProvider) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/incoming-requests'),
              child: const Text(
                'ইনকামিং রিকোয়েস্ট দেখুন',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'আপনি এখানে আপনার বুক করা সেবা দেখতে পারেন। ইনকামিং রিকোয়েস্টের জন্য উপরের আইকন ব্যবহার করুন।',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
  Widget _buildBookingCard(BuildContext context, BookingEntity booking) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // 🔥 এখন বুকিং কার্ডে ক্লিক করলে সরাসরি চ্যাট রুটে যাবে
          onTap: () => context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}'),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                _buildInfoRow(
                  Icons.calendar_today,
                  'তারিখ: ${_formatDate(booking.scheduledAt)}',
                ),
                _buildInfoRow(
                  Icons.access_time,
                  'সময়: ${_formatTime(booking.scheduledAt)}',
                ),
                _buildInfoRow(
                  Icons.attach_money,
                  'মূল্য: ৳${booking.price.toStringAsFixed(0)}',
                ),
                if (booking.description?.isNotEmpty ?? false)
                  _buildInfoRow(
                    Icons.description,
                    'বিবরণ: ${booking.description}',
                  ),
                const SizedBox(height: 12),
                if (booking.status == BookingStatus.pending ||
                    booking.status == BookingStatus.confirmed)
                  _buildCustomerActions(booking),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerActions(BookingEntity booking) {
    if (booking.status == BookingStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  _updateBookingStatus(booking.id, BookingStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('বুকিং বাতিল করুন'),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Future<void> _updateBookingStatus(
      String bookingId, BookingStatus newStatus) async {
    final state = context.read<AuthBloc>().state;

    if (state is Authenticated) {
      try {
        final result = await ApiClient.updateBookingStatus(
          bookingId,
          newStatus,
          'customer',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: newStatus == BookingStatus.cancelled
                ? AppColors.error
                : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadBookings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('স্ট্যাটাস আপডেট করতে সমস্যা: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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