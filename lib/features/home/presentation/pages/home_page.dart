import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/utils/dummy_data.dart'; // For dummy categories.
import '../../domain/entities/service_category.dart'; // Model.

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('স্মার্টশেবা', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
            tooltip: 'প্রস্থান',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            // Fetches dummy data once to build the grid
            final categories = DummyData.getServiceCategories();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Profile Header Section (Preserved) ---
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.deepPurple[100],
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0] : 'U',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                onPressed: () {
                                  context.go('/profile-edit');
                                },
                                tooltip: 'প্রোফাইল সম্পাদনা করুন',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'স্বাগতম, ${user.name}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? 'ইমেইল যোগ করা হয়নি',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ভূমিকা: ${user.role.toString().split('.').last}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Search Bar Section ---
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'সেবা খুঁজুন...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      // Future Week 9: Implement search logic (e.g., filter categories, initiate API search)
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // --- Location Display Section (Placeholder for Week 8 Geolocation) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('আপনার অবস্থান: ঢাকা, বাংলাদেশ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // --- Service Categories Grid ---
                  Text(
                    'সেবা বিভাগসমূহ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Grid scrolls with SingleChildScrollView
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2-column grid for mobile responsiveness
                      childAspectRatio: 3 / 2, // Card aspect ratio
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        child: InkWell(
                          onTap: () {
                            // Week 3 Day 18-21: Navigate to the service list page for this category
                            context.go('/services/${category.id}');
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Placeholder for icon asset (requires assets/icons folder with matching names)
                              Image.asset(category.iconPath, height: 50, width: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.category, size: 50, color: Colors.deepPurple); // Fallback icon
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name, 
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }
          // Default loading state
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}