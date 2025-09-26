import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Note: We don't need app_theme here unless we use a custom theme class.
import '../../../../../core/utils/dummy_data.dart';
import '../../domain/entities/service_provider.dart';

class ProviderListPage extends StatelessWidget {
  const ProviderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = DummyData.getProviders();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোভাইডার তালিকা', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final provider = providers[index];
          
          return Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: const CircleAvatar(
                child: Icon(Icons.person, size: 28),
              ),
              title: Text(
                provider.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.rating.toStringAsFixed(1)} রেটিং',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  if (provider.isVerified) 
                    const Tooltip(
                      message: 'প্রমাণিত প্রোভাইডার',
                      child: Icon(Icons.verified, color: Colors.green, size: 18),
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to detail page using GoRouter
                context.go('/provider-detail/${provider.id}');
              },
            ),
          );
        },
      ),
    );
  }
}