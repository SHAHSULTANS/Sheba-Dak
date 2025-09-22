import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '/../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';


class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('নিবন্ধন', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'নাম', // Name in Bangla.
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'ফোন নম্বর', // Phone Number in Bangla.
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'ইমেইল (ঐচ্ছিক)', // Email (Optional) in Bangla.
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
                    context.read<AuthBloc>().add(
                      LoginEvent(phoneController.text, '123456'), // Dummy OTP for now.
                    );
                  },
                  child: const Text('নিবন্ধন করুন'), // Register in Bangla.
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}