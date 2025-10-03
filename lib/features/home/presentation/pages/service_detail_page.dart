import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';

import '../../../../core/utils/dummy_data.dart';
import '../../domain/entities/service.dart';

class ServiceDetailPage extends StatelessWidget {
  final String id;
  const ServiceDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final service = DummyData.getServiceById(id);

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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.red),
            ),
          ),
        ),
      );
    }

    final provider = DummyData.getProviders().firstWhere(
      (p) => p.services.contains(service.id),
      orElse: () => DummyData.getProviders().first,
    );
    final providerId = provider.id;
    final serviceCategory = service.categoryId;
    final price = service.price;

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Name Header
            Text(
              service.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  serviceCategory.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),

            // Description Section
            _buildSection(
              context,
              icon: Icons.description_outlined,
              title: 'বিবরণ',
              child: Text(service.description,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),

            // Price Section
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.attach_money,
              title: 'মূল্য',
              child: Text('৳${price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold)),
            ),

            // Provider Section
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.person_outline,
              title: 'প্রোভাইডার',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(provider.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Book Now Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated && state.user.role == Role.customer) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go(
                        '/booking/$providerId/$serviceCategory/$price',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.green,
                        elevation: 4,
                      ),
                      child: const Text(
                        'বুক করুন',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for section card
  Widget _buildSection(BuildContext context,
      {required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}