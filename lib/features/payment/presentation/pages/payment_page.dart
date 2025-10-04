import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dummy_data.dart';
import '../../../booking/domain/entities/booking_entity.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  const PaymentPage({super.key, required this.bookingId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'cash_on_delivery';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final booking = DummyData.getInternalBookingsList().firstWhere(
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
        title: const Text(
          'পেমেন্ট অপশন',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/my-bookings'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ত্রুটি: ${authState.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, authState) {
          if (authState is! Authenticated || authState.user.role != Role.customer) {
            return const Center(
              child: Text(
                'অনুমোদিত নয়: শুধুমাত্র গ্রাহকরা পেমেন্ট করতে পারেন',
                style: TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          return BlocConsumer<BookingBloc, BookingState>(
            listener: (context, bookingState) {
              if (bookingState is BookingSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ পেমেন্ট স্ট্যাটাস আপডেট সফল: ${_selectedMethod == 'cash_on_delivery' ? 'ক্যাশ অন ডেলিভারি' : 'মোবাইল ব্যাংকিং'}',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Redirect to MyBookings after payment completion
                if (bookingState.bookingId == widget.bookingId) {
                  context.go('/my-bookings');
                }
              } else if (bookingState is BookingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ ত্রুটি: ${bookingState.message}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, bookingState) {
              final isLoading = bookingState is BookingLoading;
              final currentStatus = booking.status;

              if (booking.id.isEmpty) {
                return const Center(
                  child: Text(
                    'বুকিং পাওয়া যায়নি',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'সেবা: ${booking.serviceCategory}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'মূল্য: ৳${booking.price.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'তারিখ: ${booking.scheduledAt.toString().substring(0, 16)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'পেমেন্ট মেথড নির্বাচন করুন',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    RadioListTile<String>(
                      title: const Text('ক্যাশ অন ডেলিভারি'),
                      value: 'cash_on_delivery',
                      groupValue: _selectedMethod,
                      onChanged: currentStatus == BookingStatus.confirmed
                          ? (value) => setState(() => _selectedMethod = value!)
                          : null,
                      activeColor: Colors.blue,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    RadioListTile<String>(
                      title: const Text('মোবাইল ব্যাংকিং (শীঘ্রই আসছে)'),
                      value: 'mobile_banking',
                      groupValue: _selectedMethod,
                      onChanged: null,
                      tileColor: Colors.grey.shade200,
                      activeColor: Colors.grey,
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
                                final newStatus = currentStatus == BookingStatus.confirmed
                                    ? BookingStatus.paymentPending
                                    : BookingStatus.paymentCompleted;
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                currentStatus == BookingStatus.confirmed
                                    ? 'পেমেন্ট শুরু করুন'
                                    : 'পেমেন্ট সম্পন্ন করুন',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'পেমেন্ট স্ট্যাটাস:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
                          color: currentStatus == BookingStatus.paymentPending
                              ? Colors.orange
                              : currentStatus == BookingStatus.paymentCompleted
                                  ? Colors.green
                                  : currentStatus == BookingStatus.confirmed
                                      ? Colors.blue
                                      : Colors.grey,
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
                          style: TextStyle(
                            color: currentStatus == BookingStatus.paymentPending
                                ? Colors.orange
                                : currentStatus == BookingStatus.paymentCompleted
                                    ? Colors.green
                                    : currentStatus == BookingStatus.confirmed
                                        ? Colors.blue
                                        : Colors.grey,
                            fontSize: 16,
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
}