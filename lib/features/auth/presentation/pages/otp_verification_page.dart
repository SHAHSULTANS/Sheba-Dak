import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '/../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';


class OtpVerificationPage extends StatelessWidget {
  final String phoneNumber;
  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('ওটিপি যাচাই', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'আপনার ফোনে পাঠানো কোডটি লিখুন', // Enter code sent to phone.
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              decoration: InputDecoration(
                labelText: 'ওটিপি', // OTP in Bangla.
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
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
                      LoginEvent(phoneNumber, otpController.text),
                    );
                  },
                  child: const Text('যাচাই করুন'), // Verify in Bangla.
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}