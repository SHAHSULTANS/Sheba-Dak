import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '/../../core/theme/app_theme.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('লগইন', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'স্মার্টশেবায় স্বাগতম',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'ফোন নম্বর',
                border: OutlineInputBorder(),
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
                    context.read<AuthBloc>().add(
                          LoginEvent(phoneController.text, '123456'),
                        );
                  },
                  child: const Text('ওটিপি পাঠান'),
                );
              },
            ),
           TextButton(
              onPressed: () {
                print('Navigating to /register');
                try {
                  context.go('/register');
                } catch (e) {
                  print('Navigation error: $e');
                }
              },
              child: const Text('নতুন অ্যাকাউন্ট তৈরি করুন'),
            )
                      ],
        ),
      ),
    );
  }
}