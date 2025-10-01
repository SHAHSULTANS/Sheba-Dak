import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';

class ProviderDashboardPage extends StatelessWidget {
  const ProviderDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
            ),
          ),
        ),
        title: const Text(
          'প্রোভাইডার ড্যাশবোর্ড',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // ভবিষ্যতে নোটিফিকেশন পেজে লিঙ্ক করুন
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('নোটিফিকেশন ফিচার শীঘ্রই আসছে!')),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/incoming-requests'),
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.list_alt, color: Colors.white),
        tooltip: 'নতুন রিকোয়েস্ট দেখুন',
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated && state.user.role == Role.provider) {
            final bookings = DummyData.getPendingBookingsByProvider(state.user.id);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'স্বাগতম, ${state.user.name}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'আপনার সেবা পরিচালনা করুন এবং নতুন রিকোয়েস্ট দেখুন',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),

                  // Stats Section
                  Text(
                    'আপনার পরিসংখ্যান',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        context,
                        title: 'মোট কাজ',
                        value: '25',
                        icon: Icons.work_outline,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        title: 'আজকের রিকোয়েস্ট',
                        value: bookings.length.toString(),
                        icon: Icons.event_available,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        context,
                        title: 'রেটিং',
                        value: '4.5',
                        icon: Icons.star_border,
                        color: Colors.amber,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Requests Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ইনকামিং রিকোয়েস্টস',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/incoming-requests'),
                        child: const Text(
                          'সব দেখুন',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  bookings.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'এই সপ্তাহে কোনো নতুন রিকোয়েস্ট নেই',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length > 3 ? 3 : bookings.length, // শুধু ৩টি দেখাবে
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            return _buildBookingCard(context, booking, theme);
                          },
                        ),
                ],
              ),
            );
          }
          return Center(
            child: Text(
              'অনুমোদিত নয়। এই ড্যাশবোর্ড শুধুমাত্র প্রোভাইডারদের জন্য।',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 700),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    BookingEntity booking,
    ThemeData theme,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/incoming-requests'), // বিস্তারিত দেখতে পেজে যান
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  _getCategoryIcon(booking.serviceCategory),
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceCategory,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'তারিখ: ${booking.scheduledAt.toString().substring(0, 16)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'মূল্য: ৳${booking.price.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                color: Colors.orange,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }
}