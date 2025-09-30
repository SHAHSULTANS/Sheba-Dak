// lib/features/booking/presentation/pages/my_bookings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

        final bookings = await ApiClient.getBookingsByUser(
          state.user.id,
          state.user.role == Role.provider ? 'provider' : 'customer',
        );

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

  // ✅ Helper function to get status text in Bengali
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার বুকিংস', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }

          if (state is! Authenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'বুকিং দেখতে লগইন করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final user = state.user;

          if (_bookings.isEmpty) {
            return _buildEmptyView(user.role);
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
              children: [
                if (user.role == Role.provider) _buildProviderHeader(),

                if (activeBookings.isNotEmpty)
                  _buildSectionHeader(
                      user.role == Role.provider
                          ? 'সক্রিয় বুকিংস (${activeBookings.length})'
                          : 'আসন্ন ও চলমান বুকিংস (${activeBookings.length})'),
                ...activeBookings.map((b) => _buildBookingCard(context, b, user.role)),

                if (historyBookings.isNotEmpty)
                  _buildSectionHeader(
                      user.role == Role.provider
                          ? 'সম্পন্ন বুকিংস (${historyBookings.length})'
                          : 'ইতিহাস (${historyBookings.length})'),
                ...historyBookings.map((b) => _buildBookingCard(context, b, user.role)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(Role role) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            role == Role.provider
                ? 'আপনার কোনো বুকিং রিকোয়েস্ট নেই'
                : 'আপনার কোনো বুকিং নেই',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            role == Role.provider
                ? 'গ্রাহকরা যখন আপনার সেবা বুক করবে, তা এখানে দেখানো হবে'
                : 'নতুন সেবা বুক করে শুরু করুন',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (role == Role.customer)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/services');
              },
              child: const Text('সেবা খুঁজুন'),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderHeader() {
    final pendingCount =
        _bookings.where((b) => b.status == BookingStatus.pending).length;

    if (pendingCount > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$pendingCountটি নতুন বুকিং রিকোয়েস্ট অপেক্ষা করছে',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingEntity booking, Role userRole) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.serviceCategory,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            _buildInfoRow(Icons.calendar_today,
                'তারিখ: ${_formatDate(booking.scheduledAt)}'),
            _buildInfoRow(
                Icons.access_time, 'সময়: ${_formatTime(booking.scheduledAt)}'),
            _buildInfoRow(
                Icons.attach_money, 'মূল্য: ৳${booking.price.toStringAsFixed(0)}'),
            if (booking.description?.isNotEmpty ?? false)
              _buildInfoRow(Icons.description, 'বিবরণ: ${booking.description}'),
            const SizedBox(height: 12),
            if (userRole == Role.provider &&
                booking.status == BookingStatus.pending)
              _buildProviderActions(booking),
            if (userRole == Role.customer &&
                (booking.status == BookingStatus.pending ||
                    booking.status == BookingStatus.confirmed))
              _buildCustomerActions(booking),
          ],
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

  Widget _buildProviderActions(BookingEntity booking) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () =>
                _updateBookingStatus(booking.id, BookingStatus.confirmed),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: BorderSide(color: AppColors.success),
            ),
            child: const Text('গ্রহণ করুন'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () =>
                _updateBookingStatus(booking.id, BookingStatus.cancelled),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
            ),
            child: const Text('বাতিল করুন'),
          ),
        ),
      ],
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
            state.user.role == Role.provider ? 'provider' : 'customer');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: newStatus == BookingStatus.cancelled
                ? AppColors.error
                : AppColors.success,
          ),
        );

        _loadBookings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('স্ট্যাটাস আপডেট করতে সমস্যা: ${e.toString()}'),
            backgroundColor: AppColors.error,
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
