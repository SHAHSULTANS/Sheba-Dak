// উপরের import গুলো অপরিবর্তিত রাখুন
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/utils/validators.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
// import 'package:smartsheba/core/theme/colors.dart';

import '../bloc/auth_bloc.dart';

class ProfileCreationPage extends StatefulWidget {
  const ProfileCreationPage({super.key});
  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();

  String? selectedGender;
  DateTime? selectedDateOfBirth;
  String? profileImageUrl;

  final List<String> genderOptions = ['পুরুষ', 'মহিলা', 'অন্যান্য'];
  final List<String> cities = [
    'ঢাকা','চট্টগ্রাম','সিলেট','রাজশাহী','খুলনা','বরিশাল','রংপুর','ময়মনসিংহ'
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDateOfBirth) {
      setState(() => selectedDateOfBirth = picked);
    }
  }

  Future<void> _pickProfileImage() async {
    // এখন ডায়ালগের primaryColor AppColors.primary
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('ছবি যোগ করুন', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('ক্যামেরা'),
              onTap: () { Navigator.pop(context); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('গ্যালারি'),
              onTap: () { Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('প্রোফাইল তৈরি করুন',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) context.go('/');
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // হেডার
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowMedium,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: profileImageUrl != null
                                ? Image.network(profileImageUrl!, fit: BoxFit.cover)
                                : Icon(Icons.person, size: 60,
                                    color: AppColors.primaryLight),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('আপনার ছবি যোগ করুন',
                        style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),

              // ফর্ম
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'পূর্ণ নাম',
                        hint: 'আপনার নাম লিখুন',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'নাম প্রয়োজন' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: emailController,
                        label: 'ইমেইল (ঐচ্ছিক)',
                        hint: 'example@email.com',
                        icon: Icons.email_outlined,
                        validator: Validators.validateEmail,
                        isOptional: true,
                      ),
                      const SizedBox(height: 16),

                      // লিঙ্গ ড্রপডাউন
                      _buildDropdown(
                        label: 'লিঙ্গ',
                        value: selectedGender,
                        options: genderOptions,
                        icon: Icons.wc_outlined,
                        onChanged: (val) => setState(() => selectedGender = val),
                      ),
                      const SizedBox(height: 16),

                      // জন্ম তারিখ
                      InkWell(
                        onTap: () => _selectDateOfBirth(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                selectedDateOfBirth != null
                                    ? '${selectedDateOfBirth!.day}/${selectedDateOfBirth!.month}/${selectedDateOfBirth!.year}'
                                    : 'জন্ম তারিখ নির্বাচন করুন',
                                style: TextStyle(
                                  color: selectedDateOfBirth != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // শহর
                      _buildDropdown(
                        label: 'শহর',
                        value: cityController.text.isEmpty ? null : cityController.text,
                        options: cities,
                        icon: Icons.location_city_outlined,
                        onChanged: (val) => cityController.text = val ?? '',
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: addressController,
                        label: 'সম্পূর্ণ ঠিকানা',
                        hint: 'বাড়ি নং, রোড, এলাকা',
                        icon: Icons.home_outlined,
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'ঠিকানা প্রয়োজন' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: postalCodeController,
                        label: 'পোস্ট কোড (ঐচ্ছিক)',
                        hint: '১২০০',
                        icon: Icons.local_post_office_outlined,
                        isOptional: true,
                      ),
                      const SizedBox(height: 30),

                      // সাবমিট বাটন
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline, color: Colors.white),
                              onPressed: isLoading ? null : _submitProfile,
                              label: Text(
                                isLoading ? 'লোড হচ্ছে...' : 'প্রোফাইল সংরক্ষণ করুন',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: options.map((String v) =>
                DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _submitProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(UpdateProfileEvent(
        name: nameController.text,
        email: emailController.text.isEmpty ? null : emailController.text,
        address: addressController.text,
        city: cityController.text,
        postalCode: postalCodeController.text.isEmpty ? null : postalCodeController.text,
        gender: selectedGender,
        dateOfBirth: selectedDateOfBirth,
        profileImageUrl: profileImageUrl,
      ));
    }
  }
}
