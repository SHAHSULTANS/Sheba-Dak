// lib/features/booking/presentation/pages/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../../../core/utils/dummy_data.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  List<BookingEntity> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;
  final Set<String> _cancellingBookings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  List<BookingEntity> get _activeBookings => _bookings
      .where((b) =>
          b.status.index <= BookingStatus.paymentCompleted.index &&
          b.status != BookingStatus.cancelled)
      .toList();

  List<BookingEntity> get _completedBookings => _bookings
      .where((b) => b.status == BookingStatus.completed)
      .toList();

  List<BookingEntity> get _cancelledBookings => _bookings
      .where((b) => b.status == BookingStatus.cancelled)
      .toList();

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'আমার বুকিংস',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBookings,
            tooltip: 'রিফ্রেশ',
          ),
        ],
        bottom: _isLoading || _errorMessage.isNotEmpty || _bookings.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'সক্রিয়'),
                  Tab(text: 'সম্পন্ন'),
                  Tab(text: 'বাতিল'),
                ],
              ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _bookings.isEmpty
                  ? _buildEmptyView()
                  : _buildTabView(),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    child: const SizedBox(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('আবার চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'আপনার কোনো বুকিং নেই',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার প্রথম সেবা বুক করুন এবং এখানে ট্র্যাক করুন',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/services'),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('সেবা খুঁজুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(_activeBookings, 'সক্রিয় বুকিং নেই'),
              _buildBookingList(_completedBookings, 'কোনো সম্পন্ন বুকিং নেই'),
              _buildBookingList(_cancelledBookings, 'কোনো বাতিল বুকিং নেই'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(List<BookingEntity> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return _buildEmptyTabView(
        icon: Icons.calendar_today,
        message: emptyMessage,
        subtitle: 'এখানে আপনার বুকিংগুলি দেখানো হবে',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      backgroundColor: Colors.white,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildEmptyTabView(
      {required IconData icon, required String message, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingEntity booking) {
    final isCancelling = _cancellingBookings.contains(booking.id);
    final provider = DummyData.getProviderById(booking.providerId);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isCancelling ? null : () => _handleCardTap(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
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
                      if (isCancelling)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceCategory,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'প্রোভাইডার: ${provider.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(booking.scheduledAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '৳${booking.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  _buildActionButtons(booking, isCancelling),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BookingEntity booking, bool isCancelling) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: isCancelling ? null : () => _openChat(booking),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('মেসেজ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: isCancelling ? null : () => _showCancelConfirmation(booking),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('বাতিল'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        );
      case BookingStatus.paymentPending:
        return ElevatedButton.icon(
          onPressed: isCancelling ? null : () => _initiatePayment(booking.id),
          icon: const Icon(Icons.payment, size: 16),
          label: const Text('পেমেন্ট সম্পন্ন করুন'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      case BookingStatus.confirmed:
        return Row(
          children: [
            IconButton(
              onPressed: isCancelling ? null : () => _openChat(booking),
              icon: const Icon(Icons.chat, size: 20),
              tooltip: 'চ্যাট',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isCancelling ? null : () => _initiatePayment(booking.id),
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('পেমেন্ট শুরু'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        );
      case BookingStatus.paymentCompleted:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: isCancelling ? null : () => _openChat(booking),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('চ্যাট'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'পেমেন্ট সম্পন্ন',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case BookingStatus.inProgress:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: isCancelling ? null : () => _openChat(booking),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('চ্যাট'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        );
      case BookingStatus.completed:
        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: isCancelling ? null : () => _openChat(booking),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('চ্যাট'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: isCancelling ? null : () => _submitReview(booking),
              icon: const Icon(Icons.star_border, size: 16),
              label: const Text('রিভিউ দিন'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        );
      case BookingStatus.cancelled:
        return Text(
          'বাতিল হয়েছে',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
        );
    }
  }

  void _handleCardTap(BookingEntity booking) {
    if (booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.paymentPending) {
      _initiatePayment(booking.id);
    } else if (booking.status == BookingStatus.completed) {
      _submitReview(booking);
    } else {
      _openChat(booking);
    }
  }

  void _openChat(BookingEntity booking) {
    context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}');
  }

  void _initiatePayment(String bookingId) {
    context.go('/payment/$bookingId');
  }

  void _submitReview(BookingEntity booking) {
    context.go('/review/${booking.id}');
  }

  void _showCancelConfirmation(BookingEntity booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('বুকিং বাতিল করুন'),
        content: const Text('আপনি কি নিশ্চিত যে আপনি এই বুকিংটি বাতিল করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus(booking.id, BookingStatus.cancelled);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
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
        return Colors.blue; // Changed to blue to avoid implying payment completion
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

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.pending_actions;
      case BookingStatus.paymentPending:
        return Icons.payment;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.paymentCompleted:
        return Icons.verified;
      case BookingStatus.inProgress:
        return Icons.build_circle_outlined;
      case BookingStatus.completed:
        return Icons.assignment_turned_in;
      case BookingStatus.cancelled:
        return Icons.cancel;
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

  Future<void> _updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    final state = context.read<AuthBloc>().state;

    if (state is Authenticated) {
      try {
        setState(() {
          _cancellingBookings.add(bookingId);
        });

        final result = await ApiClient.updateBookingStatus(
          bookingId,
          newStatus,
          'customer',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: newStatus == BookingStatus.cancelled ? AppColors.error : AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        await _loadBookings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('স্ট্যাটাস আপডেট করতে সমস্যা: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } finally {
        setState(() {
          _cancellingBookings.remove(bookingId);
        });
      }
    }
  }
}