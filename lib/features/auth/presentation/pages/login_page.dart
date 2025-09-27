import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section with Animated Logo
                  _buildHeaderSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome Text
                  _buildWelcomeText(),
                  
                  const SizedBox(height: 32),
                  
                  // Login Form
                  _buildLoginForm(),
                  
                  const SizedBox(height: 24),
                  
                  // Alternative Login Options
                  _buildAlternativeLogin(),
                  
                  const SizedBox(height: 32),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Animated Logo Container (Without Lottie)
        SizedBox(
          height: 150,
          child: Stack(
            children: [
              // Background Circle
              Positioned(
                right: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Service Icons with Animation
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedIcon(Icons.build, 0),
                    _buildAnimatedIcon(Icons.electrical_services, 1),
                    _buildAnimatedIcon(Icons.cleaning_services, 2),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // App Name with Gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'SmartSheba',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        Text(
          'স্থানীয় সেবার নির্ভরযোগ্য প্লাটফর্ম',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(IconData icon, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay * 0.2, 1.0, curve: Curves.elasticOut),
        ),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'লগইন করুন',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'আপনার অ্যাকাউন্টে অ্যাক্সেস পেতে ফোন নম্বর দিন',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Phone Number Field with Country Code
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Row(
              children: [
                // Country Code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // You can add a BD flag image here
                      // Image.asset('assets/images/bd-flag.png', width: 20, height: 20),
                      Icon(Icons.flag, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+88',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      hintText: '017XXXXXXXX',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      hintStyle: TextStyle(color: AppColors.grey500),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => Validators.validatePhoneNumber(value),
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // OTP Send Button
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
               print('AuthBloc state changed: $state');
              if (state is OtpSent) {
                
                print('Navigating to OTP page for: ${state.phoneNumber}');
                context.go('/otp-verification', extra: state.phoneNumber);
              } else if (state is OtpSent) {
                // ✅ FIX: Navigate to the OTP verification page
                // The phone number is passed as an extra argument
                context.go('/otp-verification', extra: state.phoneNumber);
                
                // Show a user-friendly message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ OTP পাঠানো হয়েছে। যাচাই করুন। (Dummy OTP: 123456)'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state is AuthError) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ত্রুটি: ${state.message}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              
              if (isLoading) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                );
              }
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Dispatch the event to the BLoC
                      context.read<AuthBloc>().add(SendOtpEvent(phoneController.text));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'ওটিপি পাঠান',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeLogin() {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.grey300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'অথবা',
                style: TextStyle(color: AppColors.grey600),
              ),
            ),
            Expanded(child: Divider(color: AppColors.grey300)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Social Login Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.facebook,
              color: AppColors.facebook,
              onTap: () {
                // Handle Facebook login
              },
            ),
            
            const SizedBox(width: 16),
            
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              color: AppColors.google,
              onTap: () {
                // Handle Google login
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
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
              style: TextStyle(color: AppColors.grey600),
            ),
            GestureDetector(
              onTap: () {
                context.go('/register');
              },
              child: Text(
                'রেজিস্টার করুন',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Security Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Text(
                '১০০% সুরক্ষিত ও গোপনীয়তা রক্ষিত',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}