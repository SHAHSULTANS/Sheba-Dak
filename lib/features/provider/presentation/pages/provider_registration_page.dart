import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/provider_application.dart';

class ProviderRegistrationPage extends StatefulWidget {
  const ProviderRegistrationPage({super.key});

  @override
  _ProviderRegistrationPageState createState() => _ProviderRegistrationPageState();
}

// Removed TickerProviderStateMixin as it's not used (animation was removed)
class _ProviderRegistrationPageState extends State<ProviderRegistrationPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedServiceId;
  
  // documents now stores FILE NAMES for cross-platform compatibility
  List<String> documents = []; 

  @override
  void initState() {
    super.initState();
    // Pre-fill name if user is authenticated
    final userState = context.read<AuthBloc>().state;
    if (userState is Authenticated) {
      nameController.text = userState.user.name;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // === FIX: Web-Compatible File Picker Logic ===
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );
      
      // On web, result.paths is null, so we must check result.files
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // IMPORTANT FIX: Map the PlatformFile objects to their file names.
          // This name is available on ALL platforms, unlike the path.
          documents = result.files.map((file) => file.name).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${documents.length}টি ফাইল নির্বাচিত হয়েছে'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('কোনো ফাইল নির্বাচন করা হয়নি'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ফাইল নির্বাচনে ত্রুটি: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submitApplication(BuildContext context, String userId) {
    if (_formKey.currentState!.validate() && selectedServiceId != null && documents.isNotEmpty) {
      final application = ProviderApplication(
        userId: userId,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        services: [selectedServiceId!],
        documents: documents, // Now contains file names
      );
      context.read<AuthBloc>().add(SubmitProviderApplicationEvent(application));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ দয়া করে সকল প্রয়োজনীয় তথ্য পূরণ করুন'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(theme),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Check for successful submission (returns to Authenticated state)
          if (state is Authenticated) { 
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ আবেদন জমা দেওয়া হয়েছে। অনুমোদনের জন্য অপেক্ষা করুন।'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
            context.go('/');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ত্রুটি: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is Authenticated && state.user.role == Role.customer) {
            return _buildStepper(context, state.user, theme);
          }
          // Handle loading or other states, and unauthorized roles
          return Center(
            child: Text(
              'অনুমোদিত নয়: প্রোভাইডার বা অ্যাডমিন হিসেবে আবেদন করা যাবে না।',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  // --- Widget Builders (Ensuring all steps are present) ---

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
          ),
        ),
      ),
      title: const Text(
        'প্রোভাইডার নিবন্ধন',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.go('/'),
      ),
    );
  }

  Widget _buildStepper(BuildContext context, UserEntity user, ThemeData theme) {
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: const Color(0xFF9C27B0)),
      ),
      child: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && (_formKey.currentState?.validate() ?? false)) {
            setState(() => _currentStep++);
          } else if (_currentStep == 1 && documents.isNotEmpty) {
            setState(() => _currentStep++);
          } else if (_currentStep == 2) {
            _submitApplication(context, user.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_currentStep == 1
                    ? '❌ অন্তত একটি ডকুমেন্ট আপলোড করুন'
                    : '❌ সকল তথ্য সঠিকভাবে পূরণ করুন'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onStepCancel: () => _currentStep > 0
            ? setState(() => _currentStep--)
            : context.go('/'),
        steps: [
          _buildInfoStep(context, theme),
          _buildDocumentStep(context, theme),
          _buildSubmitStep(context, theme),
        ],
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentStep < 2 ? 'পরবর্তী' : 'সাবমিট করুন',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF9C27B0)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentStep == 0 ? 'বাতিল' : 'পিছনে যান',
                      style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
      ),
    );
  }

  Step _buildInfoStep(BuildContext context, ThemeData theme) {
    return Step(
      title: Text(
        '১. প্রাথমিক তথ্য',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'আপনার পুরো নাম',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'নাম প্রয়োজন';
                  }
                  if (value.trim().length < 2) {
                    return 'নাম কমপক্ষে ২ অক্ষরের হতে হবে';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'আপনার কাজের বিবরণ',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'বিবরণ প্রয়োজন';
                  }
                  if (value.trim().length < 10) {
                    return 'বিবরণ কমপক্ষে ১০ অক্ষরের হতে হবে';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedServiceId,
                decoration: InputDecoration(
                  labelText: 'মূল সেবা ক্যাটাগরি',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: const Text('একটি সেবা নির্বাচন করুন'),
                items: DummyData.getServiceCategories()
                    .map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedServiceId = value);
                },
                validator: (value) => value == null ? 'একটি সেবা নির্বাচন করুন' : null,
              ),
            ],
          ),
        ),
      ),
      isActive: _currentStep == 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
    );
  }

  // === FIX: Updated Document Step to Display File Name ===
  Step _buildDocumentStep(BuildContext context, ThemeData theme) {
    return Step(
      title: Text(
        '২. ডকুমেন্ট আপলোড',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'জাতীয় পরিচয়পত্র এবং কাজের অভিজ্ঞতা সার্টিফিকেট আপলোড করুন (PDF, JPG, PNG)।',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text('ডকুমেন্ট আপলোড করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              documents.isEmpty
                  ? 'কোনো ফাইল নির্বাচন করা হয়নি।'
                  : 'নির্বাচিত ফাইল: ${documents.length}টি',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: documents.isEmpty ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (documents.isNotEmpty)
              ...documents.map((fileName) => Padding( // Use fileName (String)
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName, // Display file name
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              documents.remove(fileName); // Remove by name
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ফাইল $fileName মুছে ফেলা হয়েছে'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
      isActive: _currentStep == 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildSubmitStep(BuildContext context, ThemeData theme) {
    return Step(
      title: Text(
        '৩. নিশ্চিতকরণ',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আপনার আবেদন পর্যালোচনা করা হবে। অ্যাডমিন অনুমোদনের পর আপনার ভূমিকা কাস্টমার থেকে প্রোভাইডারে পরিবর্তিত হবে।',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            Text(
              'এই প্রক্রিয়াটি ৩-৫ কার্যদিবস সময় নিতে পারে।',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'আপনার প্রোফাইল এবং ডকুমেন্ট যাচাইয়ের পর আমরা আপনাকে ইমেইলের মাধ্যমে অবহিত করব।',
                      style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF9C27B0)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isActive: _currentStep == 2,
      state: StepState.complete,
    );
  }
}