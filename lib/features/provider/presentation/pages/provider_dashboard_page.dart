import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> 
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  List<BookingEntity> _bookings = [];
  final Set<String> _processingBookings = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    DummyData.initializeAllData();
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated && state.user.role == Role.provider) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        final bookings = await ApiClient.getBookingsByUser(state.user.id, 'provider');

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
        _errorMessage = 'অনুমোদিত নয়। এই ড্যাশবোর্ড শুধুমাত্র প্রোভাইডারদের জন্য।';
        _isLoading = false;
      });
    }
  }

  // Booking categorization
  List<BookingEntity> get _incomingBookings => _bookings
      .where((b) => b.status == BookingStatus.pending)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<BookingEntity> get _paymentPendingBookings => _bookings
      .where((b) => b.status == BookingStatus.paymentPending)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<BookingEntity> get _confirmedBookings => _bookings
      .where((b) => b.status == BookingStatus.confirmed)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<BookingEntity> get _readyToStartBookings => _bookings
      .where((b) => b.status == BookingStatus.paymentCompleted)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<BookingEntity> get _activeBookings => _bookings
      .where((b) => b.status == BookingStatus.inProgress)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<BookingEntity> get _completedBookings => _bookings
      .where((b) => b.status == BookingStatus.completed)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

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
          'প্রোভাইডার ড্যাশবোর্ড',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'রিফ্রেশ',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // FIXED: Make tabs scrollable for mobile
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'ইনকামিং'),
                Tab(text: 'পেমেন্ট অপেক্ষমাণ'),
                Tab(text: 'গ্রহণকৃত'),
                Tab(text: 'প্রস্তুত'),
                Tab(text: 'চলমান'),
                Tab(text: 'সম্পন্ন'),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated || state.user.role != Role.provider) {
            return _buildUnauthorizedView(theme);
          }
          if (_isLoading) {
            return _buildLoadingView();
          }
          if (_errorMessage.isNotEmpty) {
            return _buildErrorView(theme);
          }
          return _buildTabView(context, state.user, theme);
        },
      ),
    );
  }

  Widget _buildUnauthorizedView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            Text(
              'অনুমোদিত নয়। এই ড্যাশবোর্ড শুধুমাত্র প্রোভাইডারদের জন্য।',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
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

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 80),
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

  Widget _buildTabView(BuildContext context, UserEntity user, ThemeData theme) {
    final totalEarnings = _bookings
        .where((b) => b.status == BookingStatus.completed)
        .fold(0.0, (sum, b) => sum + b.price);

    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('মোট আয়', '৳${totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green),
              _buildStatItem('ইনকামিং', _incomingBookings.length.toString(), Icons.pending_actions, Colors.orange),
              _buildStatItem('পেমেন্ট অপেক্ষমাণ', _paymentPendingBookings.length.toString(), Icons.payment, Colors.deepOrange),
              _buildStatItem('গ্রহণকৃত', _confirmedBookings.length.toString(), Icons.check_circle, Colors.blue),
              _buildStatItem('প্রস্তুত', _readyToStartBookings.length.toString(), Icons.play_circle, Colors.purple),
              _buildStatItem('চলমান', _activeBookings.length.toString(), Icons.build_circle, AppColors.primary),
              _buildStatItem('সম্পন্ন', _completedBookings.length.toString(), Icons.verified, AppColors.success),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(_incomingBookings, 'কোনো নতুন রিকোয়েস্ট নেই', 'নতুন রিকোয়েস্টের জন্য অপেক্ষা করুন'),
              _buildBookingList(_paymentPendingBookings, 'কোনো পেমেন্ট অপেক্ষমাণ বুকিং নেই', 'পেমেন্টের জন্য অপেক্ষা করুন'),
              _buildBookingList(_confirmedBookings, 'কোনো গ্রহণকৃত বুকিং নেই', 'ইনকামিং রিকোয়েস্ট থেকে বুকিং গ্রহণ করুন'),
              _buildBookingList(_readyToStartBookings, 'কোনো প্রস্তুত বুকিং নেই', 'পেমেন্ট সম্পন্ন বুকিং থেকে সেবা শুরু করুন'),
              _buildBookingList(_activeBookings, 'কোনো চলমান বুকিং নেই', 'প্রস্তুত বুকিং থেকে সেবা শুরু করুন'),
              _buildBookingList(_completedBookings, 'কোনো সম্পন্ন বুকিং নেই', 'চলমান বুকিং সম্পন্ন করুন'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(List<BookingEntity> bookings, String emptyMessage, String emptySubtitle) {
    if (bookings.isEmpty) {
      return _buildEmptyTabView(
        icon: Icons.inbox_outlined,
        message: emptyMessage,
        subtitle: emptySubtitle,
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

  Widget _buildEmptyTabView({required IconData icon, required String message, required String subtitle}) {
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
    final isProcessing = _processingBookings.contains(booking.id);
    final customer = DummyData.getUserById(booking.customerId);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isProcessing ? null : () => _handleCardTap(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (isProcessing)
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
                          'গ্রাহক: ${customer.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ঠিকানা: ${customer.address}, ${customer.city}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(booking.scheduledAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.description ?? 'বিবরণ নেই',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontStyle: booking.description == null ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                  _buildActionButtons(booking, isProcessing),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BookingEntity booking, bool isProcessing) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Row(
          children: [
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => _updateBookingStatus(booking.id, BookingStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('প্রত্যাখ্যান'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () => _updateBookingStatus(booking.id, BookingStatus.confirmed),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('গ্রহণ করুন'),
            ),
          ],
        );

      case BookingStatus.paymentPending:
        return Row(
          children: [
            OutlinedButton(
              onPressed: isProcessing ? null : () => _handleCardTap(booking),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('পেমেন্ট স্ট্যাটাস দেখুন'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('চ্যাট'),
            ),
          ],
        );

      case BookingStatus.confirmed:
        return Row(
          children: [
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () => _updateBookingStatus(booking.id, BookingStatus.inProgress),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('সেবা শুরু'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('চ্যাট'),
            ),
          ],
        );

      case BookingStatus.paymentCompleted:
        return ElevatedButton(
          onPressed: isProcessing
              ? null
              : () => _updateBookingStatus(booking.id, BookingStatus.inProgress),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('সেবা শুরু'),
        );

      case BookingStatus.inProgress:
        return Row(
          children: [
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('চ্যাট'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () => _updateBookingStatus(booking.id, BookingStatus.completed),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('সম্পন্ন করুন'),
            ),
          ],
        );

      case BookingStatus.completed:
        return OutlinedButton(
          onPressed: isProcessing ? null : () => _viewFeedback(booking),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('ফিডব্যাক'),
        );

      case BookingStatus.cancelled:
        return Text(
          'বাতিল হয়েছে',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  void _handleCardTap(BookingEntity booking) {
    print('DEBUG: Handling card tap for booking: ${booking.id}, status: ${booking.status}');
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      print('DEBUG: Current user role: ${authState.user.role}, ID: ${authState.user.id}');
    } else {
      print('DEBUG: User not authenticated');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('অনুগ্রহ করে লগইন করুন'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      if (booking.status == BookingStatus.pending) {
        print('DEBUG: Navigating to /incoming-requests/${booking.id}');
        context.go('/incoming-requests/${booking.id}');
      } else if (booking.status == BookingStatus.paymentPending) {
        print('DEBUG: Navigating to /payment-status/${booking.id}');
        context.go('/payment-status/${booking.id}');
      } else if (booking.status == BookingStatus.confirmed || 
                 booking.status == BookingStatus.paymentCompleted || 
                 booking.status == BookingStatus.inProgress) {
        print('DEBUG: Navigating to /chat/${booking.id}/${booking.customerId}/${booking.providerId}');
        context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}');
      } else if (booking.status == BookingStatus.completed) {
        print('DEBUG: Showing feedback for booking ${booking.id}');
        _viewFeedback(booking);
      } else {
        print('DEBUG: No action for cancelled booking ${booking.id}');
      }
    } catch (e) {
      print('DEBUG: Navigation error for booking ${booking.id}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('নেভিগেশন ত্রুটি: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _viewFeedback(BookingEntity booking) {
    final customer = DummyData.getUserById(booking.customerId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('গ্রাহক ফিডব্যাক - ${booking.serviceCategory}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('গ্রাহক: ${customer.name}'),
            const SizedBox(height: 8),
            Text('বুকিং আইডি: ${booking.id}'),
            const SizedBox(height: 8),
            const Text('ফিডব্যাক: এই বুকিংয়ের জন্য ফিডব্যাক সিস্টেম আসছে!'),
            const SizedBox(height: 8),
            Text(
              'সময়: ${_formatDateTime(booking.scheduledAt)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) return;

    setState(() {
      _processingBookings.add(bookingId);
    });

    try {
      final result = await ApiClient.updateBookingStatus(bookingId, newStatus, 'provider');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'স্ট্যাটাস আপডেট করা হয়েছে'),
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
        _processingBookings.remove(bookingId);
      });
    }
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

  String _formatDateTime(DateTime date) {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr, $timeStr';
  }
}