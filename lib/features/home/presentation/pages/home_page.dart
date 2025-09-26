import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Core Imports
import '../../../../core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart'; // For Role enum
// Feature Imports
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/service_category.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetches dummy data once outside the BlocBuilder to avoid recalculation
    final categories = DummyData.getServiceCategories();
    
    return Scaffold(
      // --- APP BAR: Dynamic Title & Actions ---
      appBar: AppBar(
        title: const Text('স্মার্টশেবা', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Profile/Dashboard Icon
          _buildAuthActions(context),
          // Logout Button
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
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16.0), // Padding adjusted for aesthetic
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Welcome & Location ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildWelcomeAndLocation(context, state.user),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- 2. Search Bar ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: _SearchBar(),
                  ),
                  const SizedBox(height: 24),

                  // --- 3. Featured Categories (Horizontal Scroll) ---
                  _buildSectionHeader(context, 'জনপ্রিয় সেবা বিভাগ'),
                  _buildHorizontalCategoryList(context, categories),
                  const SizedBox(height: 24),

                  // --- 4. Role-Specific Action Buttons & Provider Discovery ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoleSpecificActions(context, state.user.role),
                        const SizedBox(height: 24),

                        // Provider List Button (for all users, but mainly Customer)
                        _buildSectionHeader(context, 'সেরা প্রোভাইডার খুঁজুন'),
                        _buildProviderDiscoveryButton(context),
                      ],
                    ),
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

  // --- WIDGET BUILDERS ---

  Widget _buildAuthActions(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is Authenticated) {
      final user = state.user;
      return IconButton(
        icon: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white,
          child: Text(
            user.name.isNotEmpty ? user.name[0] : 'U',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
        ),
        onPressed: () {
          // Navigate to dashboard based on role
          if (user.role == Role.provider) {
            context.go('/provider-dashboard');
          } else {
            context.go('/profile-edit');
          }
        },
        tooltip: user.role == Role.provider ? 'প্রোভাইডার ড্যাশবোর্ড' : 'প্রোফাইল',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildWelcomeAndLocation(BuildContext context, UserEntity user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'স্বাগতম, ${user.name.split(' ').first}!', // Use first name for a friendly greeting
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 18),
            const SizedBox(width: 4),
            Text(
              user.address ?? 'ঢাকা, বাংলাদেশ (ঠিকানা যোগ করুন)', 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHorizontalCategoryList(BuildContext context, List<ServiceCategory> categories) {
    return SizedBox(
      height: 120, // Fixed height for horizontal list
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 100, // Fixed width for each card
            margin: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                context.go('/services/${category.id}');
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        category.iconPath,
                        height: 40,
                        width: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.category, size: 40, color: Theme.of(context).primaryColor);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleSpecificActions(BuildContext context, Role role) {
    if (role == Role.provider) {
      return Card(
        color: Colors.green.shade50,
        elevation: 2,
        child: ListTile(
          leading: const Icon(Icons.dashboard, color: Colors.green),
          title: const Text('ড্যাশবোর্ডে যান', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('আপনার নতুন রিকোয়েস্টগুলো দেখুন'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => context.go('/provider-dashboard'),
        ),
      );
    }
    // Default action for Customer (e.g., View Bookings)
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Colors.blue),
        title: const Text('আমার বুকিং', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('আপনার চলমান ও বিগত বুকিংগুলো দেখুন'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Future Week: Navigate to booking list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('বুকিং তালিকা (পরবর্তী সপ্তাহে)'), duration: Duration(seconds: 1)),
          );
        },
      ),
    );
  }

  Widget _buildProviderDiscoveryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_search),
        label: const Text('প্রোভাইডার তালিকা দেখুন'),
        onPressed: () {
          context.go('/providers');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// --- SEPARATE WIDGET FOR SEARCH (Better practice) ---
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Future Week 9: Navigate to dedicated search screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সার্চ স্ক্রিন (পরবর্তী সপ্তাহে)'), duration: Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              'সেবা, প্রোভাইডার, বা ক্যাটাগরি খুঁজুন...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}