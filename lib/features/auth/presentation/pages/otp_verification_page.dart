import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../bloc/auth_bloc.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> 
    with TickerProviderStateMixin {
  
  // Controllers for each OTP digit
  final List<TextEditingController> _otpControllers = 
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (index) => FocusNode());

  // Timer for resend functionality
  Timer? _timer;
  int _resendCountdown = 60;
  bool _canResend = false;

  // Animation controllers
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _startResendTimer();
    _fadeController.forward();

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _fadeController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      final otp = _getOtpString();
      if (otp.length == 6) {
        _verifyOtp();
      }
    }
  }

  String _getOtpString() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _verifyOtp() {
    final otp = _getOtpString();
    if (otp.length == 6) {
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      context.read<AuthBloc>().add(
        VerifyOtpEvent(widget.phoneNumber, otp),
      );
    } else {
      _showError('সব ঘরে সংখ্যা দিন');
      _shakeOtpFields();
    }
  }

  void _shakeOtpFields() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resendOtp() {
    if (_canResend) {
      // Clear all fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      
      // Restart timer
      _startResendTimer();
      setState(() {});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('নতুন কোড পাঠানো হয়েছে'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Simulate API call - in real app, call your resend API
      context.read<AuthBloc>().add(
        SendOtpEvent(widget.phoneNumber),
      );
    }
  }

  String _formatPhoneNumber(String phone) {
    // Format phone number for display
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildBody(context, theme),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      title: const Text(
        'যাচাইকরণ',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // --- VERIFICATION ICON ---
          _buildVerificationIcon(),
          const SizedBox(height: 32),

          // --- HEADER TEXT ---
          _buildHeaderText(theme),
          const SizedBox(height: 8),

          // --- PHONE NUMBER DISPLAY ---
          _buildPhoneDisplay(theme),
          const SizedBox(height: 40),

          // --- OTP INPUT FIELDS ---
          _buildOtpInputFields(),
          const SizedBox(height: 32),

          // --- VERIFY BUTTON ---
          _buildVerifyButton(),
          const SizedBox(height: 24),

          // --- RESEND SECTION ---
          _buildResendSection(theme),
          const SizedBox(height: 40),

          // --- HELP TEXT ---
          _buildHelpText(theme),
        ],
      ),
    );
  }

  Widget _buildVerificationIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.message_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHeaderText(ThemeData theme) {
    return Text(
      'যাচাই কোড প্রবেশ করুন',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPhoneDisplay(ThemeData theme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade600,
        ),
        children: [
          const TextSpan(text: 'আমরা ৬ সংখ্যার কোড পাঠিয়েছি\n'),
          TextSpan(
            text: _formatPhoneNumber(widget.phoneNumber),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const TextSpan(text: ' নম্বরে'),
        ],
      ),
    );
  }

  Widget _buildOtpInputFields() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeController.value * 10 * 
            ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1),
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return Container(
                width: 50,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusNodes[index].hasFocus 
                        ? const Color(0xFF2196F3)
                        : Colors.grey.shade300,
                    width: _focusNodes[index].hasFocus ? 2 : 1,
                  ),
                  boxShadow: _focusNodes[index].hasFocus
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) => _onOtpChanged(value, index),
                  onTap: () {
                    // Clear field on tap for better UX
                    _otpControllers[index].selection = TextSelection.fromPosition(
                      TextPosition(offset: _otpControllers[index].text.length),
                    );
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate based on user profile completion
          if (state.user.address == null) {
            context.go('/profile-creation');
          } else {
            context.go('/');
          }
        } else if (state is AuthError) {
          _showError(state.message);
          _shakeOtpFields();
          
          // Clear OTP fields on error
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _verifyOtp,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'যাচাই করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'কোড পাননি?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        if (!_canResend)
          Text(
            'পুনরায় পাঠান ${_resendCountdown}s পরে',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          )
        else
          TextButton(
            onPressed: _resendOtp,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'পুনরায় পাঠান',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpText(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SMS না পেলে স্প্যাম ফোল্ডার চেক করুন অথবা নেটওয়ার্ক সংযোগ নিশ্চিত করুন',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}