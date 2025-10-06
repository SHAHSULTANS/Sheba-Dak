import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/theme/colors.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';
import 'package:smartsheba/features/booking/presentation/bloc/booking_bloc.dart';

// Localization for consistency
class AppStrings {
  static const paymentOptions = 'পেমেন্ট অপশন';
  static const service = 'সেবা';
  static const price = 'মূল্য';
  static const date = 'তারিখ';
  static const selectPaymentMethod = 'পেমেন্ট মেথড নির্বাচন করুন';
  static const cashOnDelivery = 'ক্যাশ অন ডেলিভারি';
  static const mobileBanking = 'মোবাইল ব্যাংকিং (শীঘ্রই আসছে)';
  static const startPayment = 'পেমেন্ট শুরু করুন';
  static const completePayment = 'পেমেন্ট সম্পন্ন করুন';
  static const paymentStatus = 'পেমেন্ট স্ট্যাটাস';
  static const bookingNotFound = 'বুকিং পাওয়া যায়নি';
  static const unauthorized = 'অনুমোদিত নয়: শুধুমাত্র গ্রাহকরা পেমেন্ট করতে পারেন';
  static const paymentSuccess = '✅ পেমেন্ট স্ট্যাটাস আপডেট সফল';
  static const paymentError = '❌ পেমেন্ট ত্রুটি';
  static const retry = 'আবার চেষ্টা করুন';
}

class PaymentPage extends StatefulWidget {
  final String bookingId;
  const PaymentPage({super.key, required this.bookingId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'cash_on_delivery';
  BookingEntity? _booking;
  bool _isLoadingBooking = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      setState(() {
        _isLoadingBooking = true;
        _errorMessage = '';
      });

      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        setState(() {
          _errorMessage = AppStrings.unauthorized;
          _isLoadingBooking = false;
        });
        return;
      }

      final bookings = await ApiClient.getBookingsByUser(authState.user.id, 'customer');
      final booking = bookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => BookingEntity(
          id: '',
          customerId: '',
          providerId: '',
          serviceCategory: 'Unknown',
          scheduledAt: DateTime(1970, 1, 1),
          status: BookingStatus.pending,
          price: 0,
        ),
      );

      setState(() {
        _booking = booking;
        _isLoadingBooking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'বুকিং লোড করতে সমস্যা: ${e.toString()}';
        _isLoadingBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
        title: Text(
          AppStrings.paymentOptions,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textInverse),
          onPressed: () => context.go('/my-bookings'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppStrings.paymentError}: ${authState.message}'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        builder: (context, authState) {
          if (authState is! Authenticated || authState.user.role != Role.customer) {
            print('DEBUG: Allowing customer access to /payment/${widget.bookingId}');
            return Center(
              child: Text(
                AppStrings.unauthorized,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (_isLoadingBooking) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (_errorMessage.isNotEmpty || _booking?.id.isEmpty == true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage.isNotEmpty ? _errorMessage : AppStrings.bookingNotFound,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadBooking,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(AppStrings.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocConsumer<BookingBloc, BookingState>(
            listener: (context, bookingState) {
              if (bookingState is BookingSuccess && bookingState.bookingId == widget.bookingId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$AppStrings.paymentSuccess: ${_selectedMethod == 'cash_on_delivery' ? AppStrings.cashOnDelivery : AppStrings.mobileBanking}',
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
                context.go('/my-bookings');
              } else if (bookingState is BookingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppStrings.paymentError}: ${bookingState.message}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
            builder: (context, bookingState) {
              final isLoading = bookingState is BookingLoading;
              final currentStatus = _booking!.status;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.service}: ${_booking!.serviceCategory}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppStrings.price}: ৳${_booking!.price.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppStrings.date}: ${_formatDateTime(_booking!.scheduledAt)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.selectPaymentMethod,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: Text(
                        AppStrings.cashOnDelivery,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      value: 'cash_on_delivery',
                      groupValue: _selectedMethod,
                      onChanged: (value) => setState(() => _selectedMethod = value!),
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    RadioListTile<String>(
                      title: Text(
                        AppStrings.mobileBanking,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: 'mobile_banking',
                      groupValue: _selectedMethod,
                      onChanged: null,
                      tileColor: AppColors.grey100,
                      activeColor: AppColors.grey500,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ||
                                (currentStatus != BookingStatus.confirmed &&
                                    currentStatus != BookingStatus.paymentPending)
                            ? null
                            : () {
                                final newStatus = _selectedMethod == 'cash_on_delivery'
                                    ? BookingStatus.paymentCompleted
                                    : BookingStatus.paymentPending;
                                context.read<BookingBloc>().add(
                                      UpdateBookingStatusEvent(
                                        id: widget.bookingId,
                                        newStatus: newStatus,
                                        authRole: 'customer',
                                      ),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
                                ),
                              )
                            : Text(
                                _selectedMethod == 'cash_on_delivery'
                                    ? AppStrings.completePayment
                                    : AppStrings.startPayment,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.paymentStatus,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          currentStatus == BookingStatus.paymentPending
                              ? Icons.hourglass_empty
                              : currentStatus == BookingStatus.paymentCompleted
                                  ? Icons.check_circle
                                  : currentStatus == BookingStatus.confirmed
                                      ? Icons.pending_actions
                                      : Icons.pending,
                          color: _getStatusColor(currentStatus),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentStatus == BookingStatus.paymentPending
                              ? 'পেমেন্ট অপেক্ষমাণ'
                              : currentStatus == BookingStatus.paymentCompleted
                                  ? 'পেমেন্ট সম্পন্ন'
                                  : currentStatus == BookingStatus.confirmed
                                      ? 'প্রোভাইডার গ্রহণ করেছে'
                                      : currentStatus.toString().split('.').last.toUpperCase(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _getStatusColor(currentStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.paymentPending:
        return AppColors.accent;
      case BookingStatus.confirmed:
        return AppColors.primary;
      case BookingStatus.paymentCompleted:
        return AppColors.success;
      case BookingStatus.inProgress:
        return AppColors.primary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime date) {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr, $timeStr';
  }
}