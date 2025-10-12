import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/presentation/pages/address_input_page.dart';
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

class _BookServicePageState extends State<BookServicePage>
    with SingleTickerProviderStateMixin {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? location;
  Position? _selectedPosition;
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();

  // Animation controllers
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // Form validation - ✅ Enhanced validation
  bool get _isFormValid => selectedDate != null &&
      selectedTime != null &&
      location != null &&
      location!.trim().isNotEmpty;

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

    // ✅ Safe initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialDateTime();
      _loadSavedLocation();
    });
  }

  // ✅ Safe load saved location using post frame callback
  void _loadSavedLocation() {
    if (!mounted) return;
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated && authState.user.address != null) {
        if (mounted) {
          setState(() {
            location = authState.user.address;
            _selectedPosition = authState.user.location;
          });
          print('🔍 Loaded saved location from profile: $location');
        }
      }
    } catch (e) {
      print('🔍 Error loading saved location: $e');
    }
  }

  void _setInitialDateTime() {
    final now = DateTime.now();
    final nextHour = now.add(const Duration(hours: 1));
    if (mounted) {
      setState(() {
        selectedDate = DateTime(nextHour.year, nextHour.month, nextHour.day);
        selectedTime = TimeOfDay(hour: nextHour.hour, minute: 0);
      });
    }
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

  // ✅ MOBILE-SAFE ADDRESS SELECTION
  Future<void> _selectAddress() async {
    if (!mounted) return;

    try {
      print('🔍 BookServicePage: Starting address selection');

      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const AddressInputPage(),
          ),
          // ✅ MOBILE CRITICAL SETTINGS
          fullscreenDialog: false,
          maintainState: true,
          settings: const RouteSettings(
            name: 'address_input_booking',
            arguments: {'from_booking': true},
          ),
        ),
      );

      print('🔍 BookServicePage: Address result received: $result');
      print('🔍 BookServicePage: Still mounted: $mounted');

      // ✅ Mobile-safe result processing
      if (!mounted) {
        print('🔍 BookServicePage unmounted during navigation');
        return;
      }

      if (result != null &&
          result['address'] != null &&
          result['address'] is String &&
          (result['address'] as String).trim().isNotEmpty) {

        // ✅ Use addPostFrameCallback for mobile-safe state update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              location = result['address'] as String;
              _selectedPosition = result['position'] as Position?;
            });
            print('🔍 Address state updated successfully: ${result['address']}');

            // ✅ Success feedback
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ঠিকানা সফলভাবে যুক্ত হয়েছে ✅\n${result['address']}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          }
        });
      } else {
        print('🔍 Invalid or empty address result: $result');
        if (mounted && result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ঠিকানা সঠিকভাবে যুক্ত হয়নি'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('🔍 Address selection error: $e');
      print('🔍 Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ঠিকানা নির্বাচন করতে সমস্যা:\n$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _submitBooking(AuthState authState) {
    if (!_isFormValid || _isSubmitting) {
      _showFormError();
      return;
    }

    if (authState is Authenticated) {
      setState(() => _isSubmitting = true);

      print('🔍 Submitting booking with location: $location');

      context.read<BookingBloc>().add(CreateBookingEvent(
        customerId: authState.user.id,
        providerId: widget.providerId,
        serviceCategory: widget.serviceCategory,
        scheduledAt: scheduledDateTime!,
        price: widget.price,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: location, // ✅ Now properly validated
        // serviceAddress: location, // Explicit service address
        // locationLat: _selectedPosition?.latitude,
        // locationLng: _selectedPosition?.longitude,
      ));
    }
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
        // ✅ Optimized buildWhen to prevent unnecessary rebuilds
        buildWhen: (previous, current) =>
            current is! Authenticated ||
            (current is Authenticated &&
                (previous is! Authenticated ||
                    previous.user.id != current.user.id ||
                    previous.user.role != current.user.role)),
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return _buildUnauthorizedView('বুকিং দেওয়ার জন্য আপনাকে লগইন করতে হবে।');
          }
          if (authState.user.role != Role.customer) {
            return _buildUnauthorizedView('শুধুমাত্র গ্রাহকরাই বুকিং দিতে পারবেন।');
          }

          // ✅ Pass authState to isolated content to prevent rebuild interference
          return _buildAuthenticatedContent(context, authState);
        },
      ),
    );
  }

  // ✅ Isolated authenticated content to preserve local state
  Widget _buildAuthenticatedContent(BuildContext context, Authenticated authState) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, bookingState) {
        if (bookingState is BookingSuccess) {
          _handleBookingSuccess(bookingState, authState);
        } else if (bookingState is BookingFailure) {
          _handleBookingFailure(bookingState);
          setState(() => _isSubmitting = false);
        }
      },
      builder: (context, bookingState) {
        _isSubmitting = bookingState is BookingLoading;

        return Stack(
          children: [
            // Main Content - ✅ Local state preserved here
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildServiceDetailsCard(),
                  const SizedBox(height: 20),
                  _buildSchedulingSection(),
                  const SizedBox(height: 20),
                  _buildAddressSection(), // ✅ Uses local state, not affected by Bloc
                  const SizedBox(height: 20),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Submit Button
            _buildSubmitButton(authState),
          ],
        );
      },
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
            _buildDetailRow(
              icon: Icons.work_outline,
              title: 'পরিষেবা',
              value: widget.serviceCategory,
            ),
            const SizedBox(height: 16),
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

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ঠিকানা',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildAddressCard(),
      ],
    );
  }

  // ✅ UPDATED: Mobile-safe address card with proper validation
  Widget _buildAddressCard() {
    final hasValidAddress = location != null && location!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasValidAddress ? AppColors.primary : Colors.grey.shade200,
          width: hasValidAddress ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _selectAddress, // ✅ Uses mobile-safe method
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasValidAddress
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: hasValidAddress ? AppColors.primary : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সেবার ঠিকানা',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValidAddress
                          ? location!.trim()
                          : 'ঠিকানা নির্বাচন করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: hasValidAddress ? Colors.black : Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasValidAddress ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasValidAddress ? AppColors.primary : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: hasValidAddress
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
              ),
            ],
          ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
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
              color: _isFormValid && !_isSubmitting
                  ? AppColors.primary
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isFormValid && !_isSubmitting
                    ? () => _submitBooking(authState)
                    : null,
                onTapDown: (_) => _buttonAnimationController.forward(),
                onTapUp: (_) => _buttonAnimationController.reverse(),
                onTapCancel: () => _buttonAnimationController.reverse(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting
                            ? 'বুকিং তৈরি হচ্ছে...'
                            : 'বুকিং নিশ্চিত করুন',
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
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

  void _showFormError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isFormValid
                    ? 'ফর্ম প্রসেসিং সমস্যা'
                    : 'তারিখ, সময় এবং ঠিকানা নির্বাচন করুন',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleBookingSuccess(BookingSuccess bookingState,
      Authenticated authState) async {
    final bookingId = bookingState.bookingId;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ বুকিং রিকোয়েস্ট সফল!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'প্রোভাইডার কনফার্ম করলে পেমেন্ট করতে বলা হবে',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );

        // ✅ Safe navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.push('/my-bookings');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('নেভিগেশন ত্রুটি: $e'),
            backgroundColor: Colors.orange,
          ),
        );
        context.push('/my-bookings');
      }
    }
  }

  void _handleBookingFailure(BookingFailure bookingState) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('ত্রুটি: ${bookingState.message}')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'বুঝেছি',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}