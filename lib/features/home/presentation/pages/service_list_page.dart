import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/home/domain/entities/service_category.dart';
import '../../../../core/utils/dummy_data.dart';
// import '../../domain/entities/service.dart';

class ServiceListPage extends StatelessWidget {
  final String categoryId;
  
  // Find the category name for the AppBar title.
  final String categoryName;

  ServiceListPage({super.key, required this.categoryId})
    : categoryName = DummyData.getServiceCategories()
            .firstWhere((cat) => cat.id == categoryId, orElse: () => const ServiceCategory(id: '', name: 'সেবা', iconPath: '', description: '')).name;

  @override
  Widget build(BuildContext context) {
    final services = DummyData.getServices(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: services.isEmpty
          ? const Center(child: Text('এই ক্যাটাগরিতে কোনো সেবা নেই।'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    title: Text(service.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text('প্রোভাইডার: ${service.providerName}\nমূল্য শুরু: ৳${service.price.toStringAsFixed(0)}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to the detail page using the service ID
                      context.go('/service-detail/${service.id}');
                    },
                  ),
                );
              },
            ),
    );
  }
}