import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/utils/validators.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(SendOtpEvent(phoneController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) {
            _showOTPSuccessDialog(state.phoneNumber);
            setState(() => _isLoading = false);
          } else if (state is AuthError) {
            _showErrorSnackBar(state.message);
            setState(() => _isLoading = false);
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium App Bar
            SliverAppBar(
              expandedHeight: size.height * 0.3,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                            ),
                          ),
                          const Spacer(),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE3F2FD)],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'SmartSheba',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'স্থানীয় সেবার নির্ভরযোগ্য প্লাটফর্ম',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Login Form Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(),
                        const SizedBox(height: 32),

                        // Login Form
                        _buildLoginForm(),
                        const SizedBox(height: 24),

                        // Alternative Login Options
                        _buildAlternativeLogin(),
                        const SizedBox(height: 32),

                        // Footer
                        _buildFooter(),
                        
                        // Bottom padding for safe area
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                      ],
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

  Widget _buildWelcomeSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'লগইন করুন',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'আপনার অ্যাকাউন্টে অ্যাক্সেস পেতে ফোন নম্বর দিন',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Phone Number Field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhoneNumber,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'ফোন নম্বর',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  child: const Icon(Icons.phone_android_rounded, color: Color(0xFF2196F3), size: 22),
                ),
                prefixText: '+88 ',
                prefixStyle: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                hintText: '017XXXXXXXX',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // OTP Send Button - FIXED
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 58,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
            : const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                stops: [0.1, 0.9],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'ওটিপি পাঠান',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (!_isLoading)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeLogin() {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'অথবা',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Social Login Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.facebook_rounded,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onTap: () {
                HapticFeedback.lightImpact();
                // Handle Facebook login
              },
            ),
            
            const SizedBox(width: 16),
            
            _buildSocialButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Google',
              color: const Color(0xFFEA4335),
              onTap: () {
                HapticFeedback.lightImpact();
                // Handle Google login
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Register Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'অ্যাকাউন্ট নেই? ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100, width: 1),
                ),
                child: Text(
                  'রেজিস্টার করুন',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Security Badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.green.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                '১০০% সুরক্ষিত ও গোপনীয়তা রক্ষিত',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOTPSuccessDialog(String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'OTP পাঠানো হয়েছে!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$phoneNumber নম্বরে OTP পাঠানো হয়েছে',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ডেমো OTP: 123456',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/otp-verification', extra: phoneNumber);
                  },
                  child: const Text(
                    'OTP পৃষ্ঠায় যান',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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
}