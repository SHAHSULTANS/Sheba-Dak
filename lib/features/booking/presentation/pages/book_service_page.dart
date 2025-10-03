import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';
import 'package:smartsheba/core/network/api_client.dart';

class BookServicePage extends StatefulWidget {
  final String providerId;
  final String serviceCategory;
  final double price;

  const BookServicePage({
    super.key,
    required this.providerId,
    required this.serviceCategory,
    required this.price,
  });

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> with SingleTickerProviderStateMixin {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  
  // Animation controllers
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  
  // Form validation
  bool get _isFormValid => selectedDate != null && selectedTime != null;
  bool _isSubmitting = false;

  DateTime? get scheduledDateTime {
    if (selectedDate == null || selectedTime == null) return null;
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Set initial date to next available slot
    _setInitialDateTime();
  }

  void _setInitialDateTime() {
    final now = DateTime.now();
    final nextHour = now.add(const Duration(hours: 1));
    setState(() {
      selectedDate = DateTime(nextHour.year, nextHour.month, nextHour.day);
      selectedTime = TimeOfDay(hour: nextHour.hour, minute: 0);
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && mounted) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && mounted) {
      setState(() => selectedTime = pickedTime);
    }
  }

  void _submitBooking(AuthState authState) {
    if (!_isFormValid || _isSubmitting) return;

    if (authState is Authenticated) {
      setState(() => _isSubmitting = true);
      
      context.read<BookingBloc>().add(CreateBookingEvent(
        customerId: authState.user.id,
        providerId: widget.providerId,
        serviceCategory: widget.serviceCategory,
        scheduledAt: scheduledDateTime!,
        price: widget.price,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ));
    }
  }

  void _showDateTimeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('অনুগ্রহ করে তারিখ ও সময় নির্বাচন করুন'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'ঠিক আছে',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return _buildUnauthorizedView('বুকিং দেওয়ার জন্য আপনাকে লগইন করতে হবে।');
          }
          if (authState.user.role != Role.customer) {
            return _buildUnauthorizedView('শুধুমাত্র গ্রাহকরাই বুকিং দিতে পারবেন।');
          }

          return BlocConsumer<BookingBloc, BookingState>(
            listener: (context, bookingState) async {
              if (bookingState is BookingSuccess) {
                _handleBookingSuccess(bookingState, authState);
              } else if (bookingState is BookingFailure) {
                _handleBookingFailure(bookingState);
              }
            },
            builder: (context, bookingState) {
              _isSubmitting = bookingState is BookingLoading;

              return Stack(
                children: [
                  // Main Content
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeaderSection(),
                        const SizedBox(height: 24),
                        
                        // Service Details Card
                        _buildServiceDetailsCard(),
                        const SizedBox(height: 20),
                        
                        // Scheduling Section
                        _buildSchedulingSection(),
                        const SizedBox(height: 20),
                        
                        // Description Section
                        _buildDescriptionSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  
                  // Submit Button (Sticky Bottom)
                  _buildSubmitButton(authState),
                ],
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      title: const Text(
        'সেবা বুক করুন',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
      shadowColor: Colors.black.withOpacity(0.1),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.shade200,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'সেবা বুকিং',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'আপনার পছন্দের সময়সূচী নির্বাচন করুন',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Service Info
            _buildDetailRow(
              icon: Icons.work_outline,
              title: 'পরিষেবা',
              value: widget.serviceCategory,
            ),
            const SizedBox(height: 16),
            // Price Info
            _buildDetailRow(
              icon: Icons.attach_money_rounded,
              title: 'মূল্য',
              value: '৳${widget.price.toStringAsFixed(0)}',
              valueStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ?? const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'সময়সূচী নির্বাচন',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // Date Selection
        _buildDateTimeCard(
          icon: Icons.calendar_today_rounded,
          title: 'তারিখ',
          value: selectedDate == null 
              ? 'নির্বাচন করুন'
              : DateFormat('EEE, MMM d, yyyy').format(selectedDate!),
          onTap: _selectDate,
          isSelected: selectedDate != null,
        ),
        const SizedBox(height: 12),
        
        // Time Selection
        _buildDateTimeCard(
          icon: Icons.access_time_rounded,
          title: 'সময়',
          value: selectedTime == null 
              ? 'নির্বাচন করুন'
              : selectedTime!.format(context),
          onTap: _selectTime,
          isSelected: selectedTime != null,
        ),
      ],
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.black : Colors.grey.shade500,
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'অতিরিক্ত তথ্য',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'প্রয়োজনীয় বিবরণ বা বিশেষ নির্দেশনা লিখুন (ঐচ্ছিক)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'উদাহরণ: বিশেষ প্রয়োজন, অবস্থান বিবরণ, ইত্যাদি...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AuthState authState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: AnimatedBuilder(
          animation: _buttonScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _buttonScaleAnimation.value,
              child: child,
            );
          },
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: _isFormValid ? AppColors.primary : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isFormValid && !_isSubmitting
                    ? () => _submitBooking(authState)
                    : _isFormValid ? null : _showDateTimeError,
                onTapDown: (_) => _buttonAnimationController.forward(),
                onTapUp: (_) => _buttonAnimationController.reverse(),
                onTapCancel: () => _buttonAnimationController.reverse(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting ? 'বুকিং তৈরি হচ্ছে...' : 'বুকিং নিশ্চিত করুন',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthorizedView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('লগইন করুন'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookingSuccess(BookingSuccess bookingState, Authenticated authState) async {
    final bookingId = bookingState.bookingId;
    
    try {
      final allBookings = await ApiClient.getBookingsByUser(authState.user.id, 'customer');
      final booking = allBookings.firstWhere((b) => b.id == bookingId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ বুকিং রিকোয়েস্ট সফল!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'প্রোভাইডার কনফার্ম করলে পেমেন্ট করতে বলা হবে',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      if (booking.status == BookingStatus.pending) {
        context.go('/my-bookings');
      } else {
        context.go('/payment/$bookingId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('রুটিং ত্রুটি: $e। আমার বুকিংস দেখুন।'),
          backgroundColor: Colors.orange,
        ),
      );
      context.go('/my-bookings');
    }
  }

  void _handleBookingFailure(BookingFailure bookingState) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('ত্রুটি: ${bookingState.message}')),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'বুঝেছি',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}