import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '/../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লগইন', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'স্মার্টশেবায় স্বাগতম',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                validator: (value) => Validators.validatePhoneNumber(value ?? ''),
                decoration: InputDecoration(
                  labelText: 'ফোন নম্বর',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    context.go('/');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<AuthBloc>().add(
                          LoginEvent(phoneController.text, '123456'),
                        );
                      }
                    },
                    child: const Text('ওটিপি পাঠান'),
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: const Text('নতুন অ্যাকাউন্ট তৈরি করুন'),
              )
            ],
          ),
        ),
      ),
    );
  }
}