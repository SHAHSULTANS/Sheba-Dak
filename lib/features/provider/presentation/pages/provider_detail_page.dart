import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Use absolute paths for Auth and Core components
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart'; // For Role enum

import '../../../../core/utils/dummy_data.dart';
import '../../domain/entities/service_provider.dart';

class ProviderDetailPage extends StatelessWidget {
  final String id;
  const ProviderDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // Use the dedicated getProviderById method
    final provider = DummyData.getProviderById(id);

    // Handle error case
    if (provider.id == 'error') {
      return Scaffold(
        appBar: AppBar(title: Text(provider.name, style: const TextStyle(color: Colors.white))),
        body: Center(child: Text(provider.description)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Header (Name, Rating, Verified)
            Row(
              children: [
                Text(
                  provider.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (provider.isVerified) 
                  const Tooltip(
                    message: 'প্রমাণিত প্রোভাইডার',
                    child: Icon(Icons.verified, color: Colors.green, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  'রেটিং: ${provider.rating.toStringAsFixed(1)} / 5.0',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Description/Bio
            Text('আমাদের সম্পর্কে', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(provider.description, style: Theme.of(context).textTheme.bodyLarge),
            const Divider(height: 32),
            
            // Services List (Placeholder for now)
            Text('যেসব সেবা প্রদান করি:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            
            // Note: Since we only have IDs, we just display the ID list for now.
            // In a later week, we'd use DummyData.getServiceById to get the service name.
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.services.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text('- ${provider.services[index]}', style: Theme.of(context).textTheme.bodyLarge),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // RBAC Check for Contact Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // Ensure Authenticated state and customer role
                if (state is Authenticated && state.user.role == Role.customer) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Prep for Week 5: Navigate to booking/contact screen.
                        context.go('/contact-provider/${provider.id}');
                      },
                      child: const Text('প্রোভাইডারের সাথে যোগাযোগ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
                // Hide button if not an authenticated customer
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}