// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import '../bloc/auth_bloc.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/utils/validators.dart';
// import '../../../../features/auth/domain/entities/user_entity.dart';

// class ProfileEditPage extends StatefulWidget {
//   const ProfileEditPage({super.key});

//   @override
//   _ProfileEditPageState createState() => _ProfileEditPageState();
// }

// class _ProfileEditPageState extends State<ProfileEditPage>
//     with TickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController nameController;
//   late TextEditingController emailController;
//   late TextEditingController addressController;
//   late TextEditingController cityController;
//   late TextEditingController postalCodeController;
//   late TextEditingController phoneController;
//   Gender? selectedGender;
//   DateTime? selectedDateOfBirth;

//   // Animation controllers for premium feel
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     final state = context.read<AuthBloc>().state;
//     if (state is Authenticated) {
//       final user = state.user;
//       nameController = TextEditingController(text: user.name);
//       emailController = TextEditingController(text: user.email ?? '');
//       addressController = TextEditingController(text: user.address ?? '');
//       cityController = TextEditingController(text: user.city ?? '');
//       postalCodeController = TextEditingController(text: user.postalCode ?? '');
//       phoneController = TextEditingController(text: user.phoneNumber);
//       selectedGender = user.gender;
//       selectedDateOfBirth = user.dateOfBirth;
//     } else {
//       nameController = TextEditingController();
//       emailController = TextEditingController();
//       addressController = TextEditingController();
//       cityController = TextEditingController();
//       postalCodeController = TextEditingController();
//       phoneController = TextEditingController();
//     }
//   }

//   void _initializeAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));

//     // Start animations after frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fadeController.forward();
//       _slideController.forward();
//     });
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     addressController.dispose();
//     cityController.dispose();
//     postalCodeController.dispose();
//     phoneController.dispose();
//     _fadeController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDateOfBirth(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDateOfBirth ?? DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: const Color(0xFF2196F3),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: const Color(0xFF1A1A1A),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != selectedDateOfBirth) {
//       setState(() {
//         selectedDateOfBirth = picked;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: const Text(
//           'প্রোফাইল সম্পাদনা করুন',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: const Color(0xFF2196F3),
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save_outlined, color: Colors.white),
//             onPressed: () => _saveProfile(context),
//           ),
//         ],
//       ),
//       body: BlocConsumer<AuthBloc, AuthState>(
//         listener: (context, state) {
//           if (state is Authenticated) {
//             HapticFeedback.lightImpact();
//             _showPremiumSuccessSnackBar('প্রোফাইল আপডেট সফল');
//             context.pop();
//           } else if (state is AuthError) {
//             HapticFeedback.mediumImpact();
//             _showPremiumErrorSnackBar(state.message);
//           }
//         },
//         builder: (context, state) {
//           if (state is AuthLoading) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
//               ),
//             );
//           }
//           return CustomScrollView(
//             physics: const BouncingScrollPhysics(),
//             slivers: [
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
//                   child: FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: SlideTransition(
//                       position: _slideAnimation,
//                       child: _buildPremiumProfileHeader(theme, size),
//                     ),
//                   ),
//                 ),
//               ),
//               SliverToBoxAdapter(
//                 child: Form(
//                   key: _formKey,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                     child: Column(
//                       children: [
//                         _buildPremiumFormCard(
//                           theme,
//                           'ব্যক্তিগত তথ্য',
//                           [
//                             _buildPremiumTextField(
//                               controller: nameController,
//                               label: 'পূর্ণ নাম',
//                               icon: Icons.person_outline_rounded,
//                               validator: (value) =>
//                                   Validators.validateRequired(value, 'নাম প্রয়োজন'),
//                             ),
//                             const SizedBox(height: 16),
//                             _buildPremiumTextField(
//                               controller: phoneController,
//                               label: 'ফোন নম্বর',
//                               icon: Icons.phone_outlined,
//                               enabled: false,
//                               validator: (value) =>
//                                   Validators.validatePhoneNumber(value),
//                             ),
//                             const SizedBox(height: 16),
//                             _buildPremiumTextField(
//                               controller: emailController,
//                               label: 'ইমেইল',
//                               icon: Icons.email_outlined,
//                               keyboardType: TextInputType.emailAddress,
//                               validator: Validators.validateEmail,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         _buildPremiumFormCard(
//                           theme,
//                           'ঠিকানা',
//                           [
//                             _buildPremiumTextField(
//                               controller: addressController,
//                               label: 'বিস্তারিত ঠিকানা',
//                               icon: Icons.home_outlined,
//                               maxLines: 2,
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildPremiumTextField(
//                                     controller: cityController,
//                                     label: 'শহর',
//                                     icon: Icons.location_city_outlined,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: _buildPremiumTextField(
//                                     controller: postalCodeController,
//                                     label: 'পোস্টাল কোড',
//                                     icon: Icons.local_post_office_outlined,
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         _buildPremiumFormCard(
//                           theme,
//                           'অতিরিক্ত তথ্য',
//                           [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildPremiumDropdown(
//                                     value: selectedGender,
//                                     label: 'লিঙ্গ',
//                                     icon: Icons.wc_outlined,
//                                     items: Gender.values,
//                                     onChanged: (Gender? value) {
//                                       setState(() {
//                                         selectedGender = value;
//                                       });
//                                     },
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: _buildPremiumDateField(
//                                     selectedDate: selectedDateOfBirth,
//                                     label: 'জন্ম তারিখ',
//                                     icon: Icons.cake_outlined,
//                                     onTap: () => _selectDateOfBirth(context),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 40),
//                         _buildPremiumSaveButton(theme, state),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildPremiumProfileHeader(ThemeData theme, Size size) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             const Color(0xFF2196F3).withOpacity(0.1),
//             const Color(0xFF9C27B0).withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.blue.shade100, width: 1),
//       ),
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               CircleAvatar(
//                 radius: 50,
//                 backgroundColor: Colors.blue.shade100,
//                 child: const Icon(
//                   Icons.person,
//                   size: 60,
//                   color: Color(0xFF2196F3),
//                 ),
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2196F3),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.edit,
//                     size: 16,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             nameController.text.isEmpty ? 'আপনার নাম' : nameController.text,
//             style: theme.textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.w700,
//               color: const Color(0xFF1A1A1A),
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'প্রোফাইল সম্পূর্ণ করুন সেরা অভিজ্ঞতার জন্য',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: Colors.grey.shade600,
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPremiumFormCard(
//       ThemeData theme, String title, List<Widget> children) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.purple.shade500, Colors.purple.shade600],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.info_outline_rounded,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 title,
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: const Color(0xFF1A1A1A),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _buildPremiumTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     int maxLines = 1,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//     bool enabled = true,
//   }) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       keyboardType: keyboardType,
//       enabled: enabled,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: Colors.grey.shade500),
//         labelText: label,
//         labelStyle: TextStyle(color: Colors.grey.shade600),
//         filled: true,
//         fillColor: Colors.grey.shade50,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       ),
//       validator: validator,
//       style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
//     );
//   }

//   Widget _buildPremiumDropdown<T>({
//     required T? value,
//     required String label,
//     required IconData icon,
//     required List<T> items,
//     required void Function(T?) onChanged,
//   }) {
//     return InputDecorator(
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: Colors.grey.shade500),
//         labelText: label,
//         labelStyle: TextStyle(color: Colors.grey.shade600),
//         filled: true,
//         fillColor: Colors.grey.shade50,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<T>(
//           value: value,
//           isExpanded: true,
//           items: items.map((T item) {
//             return DropdownMenuItem<T>(
//               value: item,
//               child: Text(
//                 _getGenderDisplay(item as Gender),
//                 style: const TextStyle(fontSize: 16),
//               ),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }

//   Widget _buildPremiumDateField({
//     required DateTime? selectedDate,
//     required String label,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AbsorbPointer(
//         child: TextFormField(
//           readOnly: true,
//           decoration: InputDecoration(
//             prefixIcon: Icon(icon, color: Colors.grey.shade500),
//             labelText: label,
//             suffixIcon: const Icon(Icons.calendar_today_outlined, color: Color.fromARGB(255, 150, 150, 150)),
//             labelStyle: TextStyle(color: Colors.grey.shade600),
//             filled: true,
//             fillColor: Colors.grey.shade50,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(color: Colors.grey.shade200),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(color: Colors.grey.shade200),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//           controller: TextEditingController(
//             text: selectedDate != null
//                 ? DateFormat('dd MMM yyyy').format(selectedDate!)
//                 : null,
//           ),
//           style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
//         ),
//       ),
//     );
//   }

//   Widget _buildPremiumSaveButton(ThemeData theme, AuthState state) {
//     final isLoading = state is AuthLoading;
//     final isValid = _formKey.currentState?.validate() ?? false;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       height: 56,
//       decoration: BoxDecoration(
//         gradient: isValid && !isLoading
//             ? const LinearGradient(
//                 colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
//                 stops: [0.0, 1.0],
//               )
//             : LinearGradient(
//                 colors: [
//                   Colors.grey.shade300,
//                   Colors.grey.shade400,
//                 ],
//               ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: isValid && !isLoading
//             ? [
//                 BoxShadow(
//                   color: const Color(0xFF2196F3).withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(0, 8),
//                 ),
//               ]
//             : [],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: isValid && !isLoading ? () => _saveProfile(context) : null,
//           borderRadius: BorderRadius.circular(16),
//           child: Center(
//             child: isLoading
//                 ? const SizedBox(
//                     height: 24,
//                     width: 24,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.save_rounded,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'সংরক্ষণ করুন',
//                         style: theme.textTheme.labelLarge?.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _saveProfile(BuildContext context) {
//     if (_formKey.currentState?.validate() ?? false) {
//       final user = (context.read<AuthBloc>().state as Authenticated).user;
//       context.read<AuthBloc>().add(UpdateProfileEvent(
//         name: nameController.text,
//         email: emailController.text.isEmpty ? null : emailController.text,
//         address: addressController.text.isEmpty ? null : addressController.text,
//         city: cityController.text.isEmpty ? null : cityController.text,
//         postalCode: postalCodeController.text.isEmpty ? null : postalCodeController.text,
//         // gender: selectedGender,
//         dateOfBirth: selectedDateOfBirth,
//       ));
//     }
//   }

//   void _showPremiumSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.check_circle_rounded,
//                 color: Colors.green,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         margin: const EdgeInsets.all(16),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showPremiumErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.error_rounded,
//                 color: Colors.red.shade600,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         margin: const EdgeInsets.all(16),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String _getGenderDisplay(Gender gender) {
//     switch (gender) {
//       case Gender.male:
//         return 'পুরুষ';
//       case Gender.female:
//         return 'মহিলা';
//       case Gender.other:
//         return 'অন্যান্য';
//     }
//   }
// }





import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Gender? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
  }

  void _initializeControllers() {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      _nameController = TextEditingController(text: state.user.name);
      _emailController = TextEditingController(text: state.user.email ?? '');
      _addressController = TextEditingController(text: state.user.address ?? '');
      _cityController = TextEditingController(text: state.user.city ?? '');
      _postalCodeController = TextEditingController(text: state.user.postalCode ?? '');
      _selectedGender = state.user.gender;
      _selectedDate = state.user.dateOfBirth;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _addressController = TextEditingController();
      _cityController = TextEditingController();
      _postalCodeController = TextEditingController();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
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
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showGenderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'লিঙ্গ নির্বাচন করুন',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            ...Gender.values.map((gender) {
              return ListTile(
                leading: Icon(
                  _getGenderIcon(gender),
                  color: _selectedGender == gender ? const Color(0xFF2196F3) : Colors.grey.shade600,
                ),
                title: Text(
                  _getGenderText(gender),
                  style: TextStyle(
                    fontWeight: _selectedGender == gender ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedGender == gender ? const Color(0xFF2196F3) : Colors.grey.shade800,
                  ),
                ),
                trailing: _selectedGender == gender
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2196F3))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Icons.male_rounded;
      case Gender.female:
        return Icons.female_rounded;
      case Gender.other:
        return Icons.transgender_rounded;
    }
  }

  String _getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'পুরুষ';
      case Gender.female:
        return 'মহিলা';
      case Gender.other:
        return 'অন্যান্য';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            _showSuccessDialog();
          } else if (state is AuthError) {
            _showErrorSnackBar(state.message);
            setState(() {
              _isLoading = false;
            });
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            _isLoading = true;
          }
          return _buildPremiumContent(theme);
        },
      ),
    );
  }

  Widget _buildPremiumContent(ThemeData theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumAppBar(theme),
        SliverToBoxAdapter(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildProfileImageSection(),
                      const SizedBox(height: 32),
                      _buildPersonalInfoSection(theme),
                      const SizedBox(height: 24),
                      _buildAddressSection(theme),
                      const SizedBox(height: 24),
                      _buildAdditionalInfoSection(theme),
                      const SizedBox(height: 40),
                      _buildActionButtons(theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2196F3),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'প্রোফাইল সম্পাদনা',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
      ),
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                Icons.person_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  // Handle image upload
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'প্রোফাইল ছবি পরিবর্তন করুন',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'ব্যক্তিগত তথ্য',
      icon: Icons.person_outline_rounded,
      children: [
        _buildPremiumTextField(
          controller: _nameController,
          label: 'পুরো নাম *',
          icon: Icons.person_rounded,
          validator: (value) => value?.isEmpty ?? true ? 'নাম প্রয়োজন' : null,
        ),
        const SizedBox(height: 16),
        _buildPremiumTextField(
          controller: _emailController,
          label: 'ইমেইল ঠিকানা',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
      ],
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'ঠিকানা তথ্য',
      icon: Icons.home_work_outlined,
      children: [
        _buildPremiumTextField(
          controller: _addressController,
          label: 'রাস্তার ঠিকানা',
          icon: Icons.location_on_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPremiumTextField(
                controller: _cityController,
                label: 'শহর',
                icon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPremiumTextField(
                controller: _postalCodeController,
                label: 'পোস্টাল কোড',
                icon: Icons.markunread_mailbox_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'অতিরিক্ত তথ্য',
      icon: Icons.info_outline_rounded,
      children: [
        // Gender Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'লিঙ্গ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showGenderBottomSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedGender != null ? _getGenderIcon(_selectedGender!) : Icons.people_rounded,
                      color: _selectedGender != null ? const Color(0xFF2196F3) : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedGender != null ? _getGenderText(_selectedGender!) : 'লিঙ্গ নির্বাচন করুন',
                        style: TextStyle(
                          color: _selectedGender != null ? Colors.grey.shade800 : Colors.grey.shade500,
                          fontWeight: _selectedGender != null ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Date of Birth
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'জন্ম তারিখ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd MMMM, yyyy').format(_selectedDate!)
                            : 'জন্ম তারিখ নির্বাচন করুন',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.grey.shade800 : Colors.grey.shade500,
                          fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Save Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
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
              onTap: _isLoading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<AuthBloc>().add(UpdateProfileEvent(
                          name: _nameController.text,
                          email: _emailController.text.isEmpty ? null : _emailController.text,
                          address: _addressController.text.isEmpty ? null : _addressController.text,
                          city: _cityController.text.isEmpty ? null : _cityController.text,
                          postalCode: _postalCodeController.text.isEmpty ? null : _postalCodeController.text,
                          // gender: _selectedGender,
                          dateOfBirth: _selectedDate,
                        ));
                      }
                    },
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
                                const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'প্রোফাইল সংরক্ষণ করুন',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Cancel Button
        Container(
          height: 52,
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
              onTap: _isLoading ? null : () => context.pop(),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'ফিরে যান',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
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
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'সফল!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'আপনার প্রোফাইল সফলভাবে আপডেট করা হয়েছে',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Text(
                        'ঠিক আছে',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
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
      ),
    );
  }
}