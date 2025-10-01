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
              colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('আমার বুকিংস', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'রিফ্রেশ',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _bookings.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSection('চলমান বুকিংস', _bookings.where((b) => b.status.index <= BookingStatus.inProgress.index).toList()),
                          const SizedBox(height: 16),
                          _buildSection('ইতিহাস', _bookings.where((b) => b.status.index > BookingStatus.inProgress.index).toList()),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 70),
          const SizedBox(height: 16),
          Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('আবার চেষ্টা করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('আপনার কোনো বুকিং নেই', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('সেবা খুঁজুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<BookingEntity> bookings) {
    if (bookings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...bookings.map((b) => _buildBookingCard(b)),
      ],
    );
  }

  Widget _buildBookingCard(BookingEntity booking) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getStatusColor(booking.status).withOpacity(0.1),
                    child: Icon(_getStatusIcon(booking.status), color: _getStatusColor(booking.status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(booking.serviceCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: TextStyle(color: _getStatusColor(booking.status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('তারিখ: ${_formatDate(booking.scheduledAt)}'),
                  Text('সময়: ${_formatTime(booking.scheduledAt)}'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('মূল্য: ৳${booking.price.toStringAsFixed(0)}'),
                  if (booking.status == BookingStatus.pending)
                    OutlinedButton.icon(
                      onPressed: () => _updateBookingStatus(booking.id, BookingStatus.cancelled),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('বাতিল করুন'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}-${date.month}-${date.year}';
  String _formatTime(DateTime date) {
    final t = TimeOfDay.fromDateTime(date);
    return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
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

  Future<void> _updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    final state = context.read<AuthBloc>().state;

    if (state is Authenticated) {
      try {
        final result = await ApiClient.updateBookingStatus(bookingId, newStatus, 'customer');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: newStatus == BookingStatus.cancelled ? AppColors.error : AppColors.success,
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
}
