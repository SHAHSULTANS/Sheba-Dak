import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/utils/validators.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.lightImpact();
      context.read<AuthBloc>().add(SendOtpEvent(phoneController.text));
      _showOTPRedirectDialog();
    }
  }

  void _showOTPRedirectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
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
            const SizedBox(height: 20),
            Text(
              'OTP পাঠানো হয়েছে!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'আপনার ফোন নম্বরে OTP পাঠানো হয়েছে',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
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
                  context.go('/otp-verification');
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showErrorSnackBar(state.message);
            setState(() => _isLoading = false);
          }
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // FIXED: Premium App Bar without SafeArea conflict
              SliverAppBar(
                expandedHeight: size.height * 0.25,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                // FIXED: Add proper top padding for status bar
                toolbarHeight: kToolbarHeight + statusBarHeight,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio = (constraints.maxHeight - kToolbarHeight - statusBarHeight) / 
                        (size.height * 0.25 - kToolbarHeight - statusBarHeight);
                    
                    return FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        // FIXED: Remove SafeArea and use padding instead
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: statusBarHeight + 16, // Status bar + some padding
                            left: 24,
                            right: 24,
                            bottom: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back button with proper positioning
                              SizedBox(
                                height: kToolbarHeight - 16,
                                child: IconButton(
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
                              ),
                              // FIXED: Animated content that scales with app bar
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - expandRatio)),
                                  child: Opacity(
                                    opacity: expandRatio.clamp(0.0, 1.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'নতুন অ্যাকাউন্ট তৈরি করুন',
                                          style: TextStyle(
                                            fontSize: 28 * expandRatio.clamp(0.5, 1.0),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'আপনার তথ্য দিয়ে রেজিস্ট্রেশন সম্পন্ন করুন',
                                          style: TextStyle(
                                            fontSize: 16 * expandRatio.clamp(0.5, 1.0),
                                            color: Colors.white.withOpacity(0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Form Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Profile Avatar Placeholder
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Name Field
                            _buildPremiumTextField(
                              controller: nameController,
                              label: 'পুরো নাম',
                              icon: Icons.person_rounded,
                              validator: Validators.requiredValidator,
                            ),
                            const SizedBox(height: 20),

                            // Phone Field
                            _buildPremiumTextField(
                              controller: phoneController,
                              label: 'ফোন নম্বর',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              validator: Validators.validatePhoneNumber,
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            _buildPremiumTextField(
                              controller: emailController,
                              label: 'ইমেইল (ঐচ্ছিক)',
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 32),

                            // Register Button
                            _buildPremiumRegisterButton(),
                            const SizedBox(height: 24),

                            // Login Redirect
                            _buildLoginRedirect(),
                            // FIXED: Add bottom padding to prevent overflow
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF2196F3), size: 22),
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
          errorStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumRegisterButton() {
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
          onTap: _isLoading ? null : _handleRegister,
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
                            const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'নিবন্ধন করুন',
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

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ইতিমধ্যে অ্যাকাউন্ট আছে?',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: Text(
              'লগইন করুন',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
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