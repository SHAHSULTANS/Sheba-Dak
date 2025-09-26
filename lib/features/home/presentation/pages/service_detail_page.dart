import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- AUTH IMPORTS ---
// This import provides AuthBloc and all its states (including Authenticated).
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart'; 
// This import provides UserEntity and the Role enum.
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart'; 

// --- CORE/HOME IMPORTS ---
import '../../../../core/utils/dummy_data.dart';
import '../../domain/entities/service.dart';


class ServiceDetailPage extends StatelessWidget {
  final String id;
  const ServiceDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // FIX 1: Use the dedicated method to ensure the correct service is loaded.
    final service = DummyData.getServiceById(id);

    // Handle the 'Service not found' error gracefully.
    if (service.id == 'error') {
      return Scaffold(
        appBar: AppBar(
          title: Text(service.name),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              service.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
          ),
        ),
      );
    }
    
    // Main UI for a valid service
    return Scaffold(
      appBar: AppBar(
        title: Text(service.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Text('বিবরণ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(service.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),

            Text('মূল্য: ৳${service.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 8),
            Text('প্রোভাইডার: ${service.providerName}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),

            // RBAC Check: Show button ONLY for authenticated customers
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // FIXED: Using Role.customer instead of RoleEnum.customer
                if (state is Authenticated && state.user.role == Role.customer) { 
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.go('/booking?serviceId=${service.id}');
                      },
                      child: const Text('প্রোভাইডারের সাথে যোগাযোগ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
                // Show nothing if not an authenticated customer
                return const SizedBox.shrink(); 
              },
            ),
          ],
        ),
      ),
    );
  }
}