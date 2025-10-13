// lib/features/booking/presentation/pages/review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

class _ReviewPageState extends State<ReviewPage> with TickerProviderStateMixin {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  BookingEntity? _booking;
  String _errorMessage = '';
  bool _hasExistingReview = false;

  // Premium animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _staggerAnimation;

  // Selected feedback tags
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'পেশাদার সেবা',
    'সময়ানুবর্তিতা',
    'বন্ধুত্বপূর্ণ আচরণ',
    'দক্ষতা',
    'পরিষ্কার পরিচ্ছন্নতা',
    'মূল্য সাশ্রয়ী',
    'নির্ভরযোগ্যতা',
    'দ্রুত সেবা',
    'যোগাযোগ দক্ষতা',
    'সরঞ্জামের মান'
  ];

  // Prevent unnecessary rebuilds
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializePremiumAnimations();
    _fetchBooking();

    // Use delayed initialization to prevent thread conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        context.read<BookingBloc>().add(ResetBookingState());
      }
    });
  }

  void _initializePremiumAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastEaseInToSlowEaseOut,
    ));

    _staggerAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeInOutCubic,
    );

    // Staggered animation sequence with safety checks
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_isDisposed) {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _commentController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooking() async {
    try {
      if (_isDisposed) return;
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasExistingReview = false;
      });
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        if (_isDisposed) return;
        setState(() {
          _errorMessage = 'লগইন প্রয়োজন';
          _isLoading = false;
        });
        return;
      }
      // Use cached data first to avoid unnecessary API calls
      final existingReviews = DummyData.getReviewsByBooking(widget.bookingId);
      if (existingReviews.isNotEmpty) {
        if (_isDisposed) return;
        setState(() {
          _hasExistingReview = true;
          _isLoading = false;
        });
        return;
      }
      // Add cancellation token pattern for API calls
      _booking = await ApiClient.getBookingById(widget.bookingId);
      if (_isDisposed) return;
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
      if (_isDisposed) return;
      setState(() {
        _errorMessage = 'বুকিং লোড করতে সমস্যা: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is ReviewSuccess) {
              HapticFeedback.mediumImpact();
              _showPremiumSuccessAnimation();
              Future.delayed(const Duration(milliseconds: 2200), () {
                if (!_isDisposed) {
                  context.read<BookingBloc>().add(ResetBookingState());
                  context.push('/my-bookings');
                }
              });
            } else if (state is ReviewFailure) {
              HapticFeedback.heavyImpact();
              _showPremiumErrorSnackBar(state.message);
              if (!_isDisposed) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          builder: (context, state) {
            if (state is BookingLoading && !_isLoading) {
              if (!_isDisposed) {
                setState(() {
                  _isLoading = true;
                });
              }
            }
            return _buildPremiumReviewContent(theme, size);
          },
        ),
      ),
    );
  }

  void _showPremiumSuccessAnimation() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Container(
                width: 320,
                height: 380,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.98),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background decoration
                    Positioned(
                      right: -60,
                      top: -60,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade100.withOpacity(0.3),
                              Colors.blue.shade100.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated checkmark
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade400.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 60,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'ধন্যবাদ!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'আপনার মূল্যবান রিভিউ আমাদের সেবার মান উন্নয়নে সহায়তা করবে',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'স্বয়ংক্রিয়ভাবে বুকিং পেজে ফিরে যাচ্ছেন...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPremiumErrorSnackBar(String message) {
    if (_isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildPremiumReviewContent(ThemeData theme, Size size) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated || authState.user.role != Role.customer) {
      return _buildPremiumErrorState(
        icon: Icons.verified_user_rounded,
        title: 'অনুমোদন প্রয়োজন',
        message: 'শুধুমাত্র গ্রাহকরা রিভিউ দিতে পারেন',
        gradient: [Colors.orange.shade400, Colors.orange.shade600],
      );
    }
    if (_isLoading) {
      return _buildPremiumLoadingState();
    }
    if (_hasExistingReview) {
      return _buildPremiumErrorState(
        icon: Icons.verified_rounded,
        title: 'রিভিউ সম্পন্ন',
        message: 'এই বুকিংয়ের জন্য ইতিমধ্যে রিভিউ দেওয়া হয়েছে',
        gradient: [Colors.green.shade400, Colors.green.shade600],
      );
    }
    if (_errorMessage.isNotEmpty || _booking == null) {
      return _buildPremiumErrorState(
        icon: Icons.error_outline_rounded,
        title: 'ত্রুটি',
        message: _errorMessage.isNotEmpty ? _errorMessage : 'বুকিং পাওয়া যায়নি',
        gradient: [Colors.red.shade400, Colors.red.shade600],
      );
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumSliverAppBar(theme, size),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumBookingInfoCard(theme),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
                _buildPremiumRatingSection(theme),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
                _buildPremiumTagsSection(theme),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
                _buildPremiumCommentSection(theme),
                SizedBox(height: 40),
                _buildPremiumSubmitButton(theme),
                SizedBox(height: 16),
                _buildPremiumCancelButton(theme),
                // Extra bottom padding for mobile
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSliverAppBar(ThemeData theme, Size size) {
    return SliverAppBar(
      expandedHeight: size.height * 0.3, // Reduced for smaller screens
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2196F3),
                const Color(0xFF9C27B0),
              ],
              stops: const [0.1, 0.9],
            ),
          ),
          child: Stack(
            children: [
              // Animated background elements - scaled for mobile
              Positioned(
                right: -size.width * 0.15,
                top: -size.height * 0.05,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 20),
                  curve: Curves.easeInOut,
                  width: size.width * 0.4,
                  height: size.width * 0.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -size.width * 0.1,
                bottom: -size.height * 0.05,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 15),
                  curve: Curves.easeInOut,
                  width: size.width * 0.3,
                  height: size.width * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 16.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(size.width < 600 ? 12.0 : 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.rate_review_rounded,
                                  size: size.width < 600 ? 24.0 : 32.0,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: size.width < 600 ? 12.0 : 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'আপনার অভিজ্ঞতা শেয়ার করুন',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        fontSize: size.width < 600 ? 18.0 : null,
                                      ),
                                    ),
                                    SizedBox(height: size.width < 600 ? 6.0 : 8.0),
                                    Text(
                                      'আপনার মূল্যবান মতামত আমাদের সেবার মান উন্নয়নে সহায়ক',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.4,
                                        fontSize: size.width < 600 ? 13.0 : null,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          onPressed: () => context.push('/my-bookings'),
        ),
      ),
    );
  }

  Widget _buildPremiumBookingInfoCard(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 10.0 : 14.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade500,
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 600 ? 20.0 : 24.0,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'বুকিং রেফারেন্স',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 11.0 : 12.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 3.0 : 4.0),
                          Text(
                            '#${widget.bookingId.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade50,
                            Colors.green.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'সম্পন্ন',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 11.0 : 12.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF8FAFC),
                        Colors.grey.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPremiumInfoItem(
                          icon: Icons.work_rounded,
                          label: 'সেবার ধরন',
                          value: _booking!.serviceCategory,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      if (MediaQuery.of(context).size.width > 400) ...[
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        Expanded(
                          child: _buildPremiumInfoItem(
                            icon: Icons.calendar_today_rounded,
                            label: 'তারিখ',
                            value: _formatDate(_booking!.scheduledAt),
                            color: Colors.purple.shade600,
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        Expanded(
                          child: _buildPremiumInfoItem(
                            icon: Icons.access_time_rounded,
                            label: 'সময়',
                            value: _formatTime(_booking!.scheduledAt),
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildPremiumInfoItem(
                                icon: Icons.calendar_today_rounded,
                                label: 'তারিখ',
                                value: _formatDate(_booking!.scheduledAt),
                                color: Colors.purple.shade600,
                              ),
                              SizedBox(height: 8),
                              _buildPremiumInfoItem(
                                icon: Icons.access_time_rounded,
                                label: 'সময়',
                                value: _formatTime(_booking!.scheduledAt),
                                color: Colors.orange.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPremiumRatingSection(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade500,
                          Colors.amber.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 600 ? 18.0 : 20.0,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0),
                  Text(
                    'সেবার মান রেট করুন',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                      fontSize: MediaQuery.of(context).size.width < 600 ? 16.0 : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
              Center(
                child: Column(
                  children: [
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: MediaQuery.of(context).size.width < 600 ? 40.0 : 52.0,
                      itemPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 4.0 : 6.0),
                      itemBuilder: (context, index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: _rating > index
                              ? LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.amber.shade600,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _rating > index
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.shade400.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onRatingUpdate: (rating) {
                        HapticFeedback.lightImpact();
                        if (!_isDisposed) {
                          setState(() {
                            _rating = rating;
                          });
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16.0 : 20.0),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _getRatingText(),
                        key: ValueKey(_rating),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 16.0,
                          fontWeight: FontWeight.w700,
                          color: _getRatingColor(),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTagsSection(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade500,
                          Colors.purple.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.label_important_rounded,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 600 ? 18.0 : 20.0,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0),
                  Expanded(
                    child: Text(
                      'সেবার বৈশিষ্ট্য নির্বাচন করুন',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                        fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 16.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16.0 : 20.0),
              
              // Mobile-friendly tags: No fixed height, let Wrap expand naturally
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0,
                    runSpacing: MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (!_isDisposed) {
                            setState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          }
                        },
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width < 600 ? 80.0 : 100.0,
                            maxWidth: MediaQuery.of(context).size.width < 600 ? 120.0 : 140.0,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0,
                            vertical: MediaQuery.of(context).size.width < 600 ? 8.0 : 10.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isSelected
                                    ? Icon(Icons.check_rounded,
                                        color: Colors.white, size: MediaQuery.of(context).size.width < 600 ? 12.0 : 14.0)
                                    : const SizedBox(width: 14, height: 14),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width < 600 ? 4.0 : 6.0),
                              Flexible(
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 600 ? 11.0 : 12.0,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Selected tags counter
                  if (_selectedTags.isNotEmpty) ...[
                    SizedBox(height: MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.blue.shade600,
                            size: MediaQuery.of(context).size.width < 600 ? 14.0 : 16.0,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0),
                          Text(
                            '${_selectedTags.length} টি বৈশিষ্ট্য নির্বাচিত',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 11.0 : 12.0,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCommentSection(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade500,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 600 ? 18.0 : 20.0,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 10.0 : 12.0),
                  Expanded(
                    child: Text(
                      'বিস্তারিত মন্তব্য (ঐচ্ছিক)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                        fontSize: MediaQuery.of(context).size.width < 600 ? 16.0 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16.0 : 20.0),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: InputBorder.none,
                      hintText: 'আপনার অভিজ্ঞতা বিস্তারিত বর্ণনা করুন...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 15.0,
                      ),
                      contentPadding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 20.0),
                    ),
                    maxLines: MediaQuery.of(context).size.width < 600 ? 4 : 5,
                    maxLength: 500,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 15.0,
                      color: const Color(0xFF1A1A1A),
                    ),
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return Container(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0,
                          right: MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0,
                        ),
                        child: Text(
                          '$currentLength / $maxLength',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 11.0 : 12.0,
                            fontWeight: FontWeight.w600,
                            color: currentLength > 400
                                ? Colors.orange.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton(ThemeData theme) {
    final isValid = _rating > 0;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: MediaQuery.of(context).size.width < 600 ? 56.0 : 60.0,
          decoration: BoxDecoration(
            gradient: isValid
                ? const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                    stops: [0.1, 0.9],
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.shade400,
                      Colors.grey.shade500,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isValid
                ? [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isValid && !_isLoading
                  ? () {
                      HapticFeedback.mediumImpact();
                      if (!_isDisposed) {
                        setState(() {
                          _isLoading = true;
                        });
                      }
                      final authState = context.read<AuthBloc>().state as Authenticated;
                      final comment = _commentController.text.isEmpty
                          ? null
                          : '${_commentController.text}${_selectedTags.isNotEmpty ? '\n\nসেবার বৈশিষ্ট্য: ${_selectedTags.join(', ')}' : ''}';
                      context.read<BookingBloc>().add(
                            SubmitReviewEvent(
                              bookingId: widget.bookingId,
                              providerId: _booking!.providerId,
                              customerId: authState.user.id,
                              rating: _rating.toInt(),
                              comment: comment,
                            ),
                          );
                    }
                  : null,
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width < 600 ? 20.0 : 24.0,
                              height: MediaQuery.of(context).size.width < 600 ? 20.0 : 24.0,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: MediaQuery.of(context).size.width < 600 ? 18.0 : 20.0,
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0),
                                Text(
                                  'রিভিউ জমা দিন',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 16.0,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (isValid && !_isLoading)
                    Positioned(
                      right: MediaQuery.of(context).size.width < 600 ? 16.0 : 20.0,
                      top: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: MediaQuery.of(context).size.width < 600 ? 18.0 : 20.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCancelButton(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: MediaQuery.of(context).size.width < 600 ? 48.0 : 52.0,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : () => context.push('/my-bookings'),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.grey.shade700,
                      size: MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0,
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0),
                    Text(
                      'পিছনে যান',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 15.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumErrorState({
    required IconData icon,
    required String title,
    required String message,
    required List<Color> gradient,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width < 600 ? 100.0 : 120.0,
              height: MediaQuery.of(context).size.width < 600 ? 100.0 : 120.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: MediaQuery.of(context).size.width < 600 ? 40.0 : 48.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
            Text(
              title,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 600 ? 20.0 : 24.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 8.0 : 12.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 16.0,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
            Container(
              height: MediaQuery.of(context).size.width < 600 ? 48.0 : 52.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/my-bookings'),
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      'বুকিং পেজে ফিরে যান',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width < 600 ? 14.0 : 15.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width < 600 ? 60.0 : 80.0,
            height: MediaQuery.of(context).size.width < 600 ? 60.0 : 80.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
              ),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
          Text(
            'লোড হচ্ছে...',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0),
          Text(
            'আপনার বুকিং তথ্য প্রস্তুত করা হচ্ছে',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 600 ? 13.0 : null,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'খুবই খারাপ';
      case 2:
        return 'সন্তোষজনক নয়';
      case 3:
        return 'মোটামুটি';
      case 4:
        return 'ভালো';
      case 5:
        return 'অসাধারণ';
      default:
        return 'রেটিং নির্বাচন করুন';
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
        return Colors.red.shade600;
      case 2:
        return Colors.orange.shade600;
      case 3:
        return Colors.amber.shade600;
      case 4:
        return Colors.lightGreen.shade600;
      case 5:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}