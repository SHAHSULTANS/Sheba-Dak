import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import '../../domain/entities/service.dart';

class ServiceDetailPage extends StatelessWidget {
  final String id;
  const ServiceDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final service = DummyData.getServiceById(id);

    if (service.id == 'error') {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text('সেবা বিস্তারিত'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'সেবাটি পাওয়া যায়নি',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('হোমপেজে ফিরে যান'),
                ),
              ],
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Service Image
          SliverAppBar(
            expandedHeight: 200,
            collapsedHeight: 70,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.primary.withOpacity(0.4),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.work_outline_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                service.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Service Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Header
                  _buildServiceHeader(context, service, serviceCategory),
                  const SizedBox(height: 24),

                  // Service Highlights
                  _buildServiceHighlights(service),
                  const SizedBox(height: 24),

                  // Description Section
                  _buildDescriptionSection(context, service),
                  const SizedBox(height: 24),

                  // Provider Section
                  _buildProviderSection(context, provider),
                  const SizedBox(height: 32),

                  // Pricing Section
                  _buildPricingSection(context, price),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // ✅ FIXED: Sticky Bottom Action Bar with Proper Auth Protection
      bottomNavigationBar: _buildBottomActionBar(context, providerId, serviceCategory, price),
    );
  }

  Widget _buildServiceHeader(BuildContext context, Service service, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          service.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHighlights(Service service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHighlightItem(
            icon: Icons.schedule_rounded,
            label: 'দ্রুত সেবা',
            value: '২৪ ঘন্টার মধ্যে',
          ),
          _buildHighlightItem(
            icon: Icons.verified_user_rounded,
            label: 'যাচাইকৃত',
            value: 'প্রোভাইডার',
          ),
          _buildHighlightItem(
            icon: Icons.star_rounded,
            label: 'রেটিং',
            value: '৪.৮/৫.০',
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Service service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'সেবা বিবরণ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            service.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSection(BuildContext context, dynamic provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'সেবা প্রদানকারী',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'যাচাইকৃত সেবা প্রদানকারী',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '৪.৮',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.work_history_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '৫০+ কাজ সম্পন্ন',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/provider-detail/${provider.id}'),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(BuildContext context, double price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'শুরু হয়',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'স্থির মূল্য - কোনো গোপন ফী নেই',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Bottom Action Bar with Proper Auth & Role Protection
  Widget _buildBottomActionBar(BuildContext context, String providerId, String serviceCategory, double price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // ✅ CASE 1: Authenticated Customer - Show Book Button
            if (state is Authenticated && state.user.role == Role.customer) {
              return Row(
                children: [
                  // Price Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '৳${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'স্থির মূল্য',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Book Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        '/booking/$providerId/$serviceCategory/$price',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'বুক করুন',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // ✅ CASE 2: Authenticated Provider - Show Info Message
            if (state is Authenticated && state.user.role == Role.provider) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'প্রোভাইডাররা বুকিং করতে পারবেন না',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/provider-dashboard'),
                      child: Text(
                        'ড্যাশবোর্ড',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ✅ CASE 3: Guest User - Show Login Button with Price
            return Row(
              children: [
                // Price Display for Guest
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '৳${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'স্থির মূল্য',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Login to Book Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLoginPrompt(context);
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      'লগইন করে বুক করুন',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ Login Prompt Dialog
  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.login_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'লগইন প্রয়োজন',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'সেবা বুক করতে আপনাকে লগইন করতে হবে। আপনার কাছে কি অ্যাকাউন্ট আছে?',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/register');
            },
            child: Text(
              'নিবন্ধন করুন',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'লগইন করুন',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}