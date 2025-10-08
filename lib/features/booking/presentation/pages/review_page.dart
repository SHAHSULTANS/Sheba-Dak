// lib/features/booking/presentation/pages/review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';

class ReviewPage extends StatefulWidget {
  final String bookingId;

  const ReviewPage({super.key, required this.bookingId});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  BookingEntity? _booking;
  String _errorMessage = '';
  bool _hasExistingReview = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _fetchBooking();
    // Reset bloc state when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingBloc>().add(ResetBookingState());
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooking() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasExistingReview = false;
      });

      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        setState(() {
          _errorMessage = 'লগইন প্রয়োজন';
          _isLoading = false;
        });
        return;
      }

      // Check for existing reviews
      final existingReviews = DummyData.getReviewsByBooking(widget.bookingId);
      if (existingReviews.isNotEmpty) {
        setState(() {
          _hasExistingReview = true;
          _isLoading = false;
        });
        return;
      }

      // Fetch booking using ApiClient.getBookingById
      _booking = await ApiClient.getBookingById(widget.bookingId);

      if (_booking == null) {
        setState(() {
          _errorMessage = 'বুকিং পাওয়া যায়নি';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'বুকিং লোড করতে সমস্যা: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          // Handle loading state from Bloc
          if (state is BookingLoading) {
            _isLoading = true;
          }

          return BlocListener<BookingBloc, BookingState>(
            listener: (context, state) {
              print('DEBUG: BlocListener received state: $state');
              if (state is ReviewSuccess) {
                print('DEBUG: Showing SnackBar for ReviewSuccess: ${state.message}');
                _scaffoldMessengerKey.currentState?.clearSnackBars();
                final snackBar = SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 3),
                );
                _scaffoldMessengerKey.currentState?.showSnackBar(snackBar).closed.then((_) {
                  print('DEBUG: SnackBar closed, resetting state and navigating to /my-bookings');
                  context.read<BookingBloc>().add(ResetBookingState());
                  setState(() {
                    _isLoading = false; // Reset loading state
                  });
                  context.go('/my-bookings'); // Navigate to /my-bookings
                });
              } else if (state is ReviewFailure) {
                print('DEBUG: Showing SnackBar for ReviewFailure: ${state.message}');
                _scaffoldMessengerKey.currentState?.clearSnackBars();
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    duration: const Duration(seconds: 3),
                  ),
                );
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: _buildReviewContent(theme, state),
          );
        },
      ),
    );
  }

  Widget _buildReviewContent(ThemeData theme, BookingState state) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || authState.user.role != Role.customer) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: AppColors.error, size: 80),
              const SizedBox(height: 16),
              Text(
                'অনুমোদিত নয়: শুধুমাত্র গ্রাহকরা রিভিউ দিতে পারেন',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/my-bookings'),
                child: const Text('ফিরে যান'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasExistingReview) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 80),
              const SizedBox(height: 16),
              Text(
                'এই বুকিংয়ের জন্য ইতিমধ্যে রিভিউ দেওয়া হয়েছে',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/my-bookings'),
                child: const Text('ফিরে যান'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 80),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'বুকিং পাওয়া যায়নি',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/my-bookings'),
                child: const Text('ফিরে যান'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
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
          'রিভিউ দিন',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'বুকিং তথ্য',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'সেবা: ${_booking!.serviceCategory}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'তারিখ: ${_formatDate(_booking!.scheduledAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'সময়: ${_formatTime(_booking!.scheduledAt)}',
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
              'রেটিং দিন (1-5)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'মন্তব্য (ঐচ্ছিক)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                hintText: 'আপনার মন্তব্য লিখুন...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _rating == 0
                    ? null
                    : () {
                        setState(() {
                          _isLoading = true;
                        });
                        final authState = context.read<AuthBloc>().state as Authenticated;
                        context.read<BookingBloc>().add(
                              SubmitReviewEvent(
                                bookingId: widget.bookingId,
                                providerId: _booking!.providerId,
                                customerId: authState.user.id,
                                rating: _rating.toInt(),
                                comment: _commentController.text.isEmpty ? null : _commentController.text,
                              ),
                            );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
                        ),
                      )
                    : Text(
                        'রিভিউ জমা দিন',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : () => context.go('/my-bookings'),
                child: Text(
                  'ফিরে যান',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}