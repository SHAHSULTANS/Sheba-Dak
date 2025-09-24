import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';

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
              'আপনার ফোনে পাঠানো কোডটি লিখুন',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'ওটিপি',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  // Navigate to profile creation for new users, or home for existing.
                  // The backend dummy response for new users will not have an address field.
                  if (state.user.address == null) {
                    context.go('/profile-creation');
                  } else {
                    context.go('/');
                  }
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
                    final otp = otpController.text;
                    if (otp.length == 6) {
                      context.read<AuthBloc>().add(
                          VerifyOtpEvent(phoneNumber, otp),
                        );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ওটিপি ৬ সংখ্যার হতে হবে')),
                      );
                    }
                  },
                  child: const Text('যাচাই করুন'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}