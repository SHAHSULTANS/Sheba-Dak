import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Use absolute paths for Auth components
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart'; // For Role enum

class ProviderDashboardPage extends StatelessWidget {
  const ProviderDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোভাইডার ড্যাশবোর্ড', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Check for Authenticated state and provider role
          if (state is Authenticated && state.user.role == Role.provider) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'স্বাগতম, প্রোভাইডার ${state.user.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  
                  // Primary Stats Placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('মোট কাজ', '25'),
                      _buildStatCard('আজকের রিকোয়েস্ট', '3'),
                      _buildStatCard('রেটিং', '4.5'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  // Incoming Requests Section (Prep for Week 6)
                  Text(
                    'ইনকামিং রিকোয়েস্টস', 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('এই সপ্তাহে আপনার কোনো নতুন রিকোয়েস্ট নেই।', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  // ListView for requests will be added in Week 6.
                ],
              ),
            );
          }
          // Fallback if accessed incorrectly (should be caught by routes.dart redirect)
          return const Center(
            child: Text('অনুমোদিত নয়। এই ড্যাশবোর্ড শুধুমাত্র প্রোভাইডারদের জন্য।'),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 100,
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}