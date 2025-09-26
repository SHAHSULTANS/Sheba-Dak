import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Core Imports
import '../../../../core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart'; // For Role enum
// Feature Imports
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/service_category.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = DummyData.getServiceCategories();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // --- MODERN APP BAR ---
      appBar: _buildModernAppBar(context, theme),
      
      // --- MAIN BODY ---
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildMainContent(context, state.user, categories, theme),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      
      // --- FLOATING ACTION BUTTON ---
      floatingActionButton: _buildFloatingActionButton(context, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // --- BOTTOM NAVIGATION ---
      bottomNavigationBar: _buildBottomNavigation(context, theme),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3), // Blue
              Color(0xFF9C27B0), // Purple
            ],
          ),
        ),
      ),
      title: const Text(
        'স্মার্টশেবা',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        _buildNotificationIcon(context),
        const SizedBox(width: 8),
        _buildProfileIcon(context),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('নোটিফিকেশন (শীঘ্রই আসছে)')),
          );
        },
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is Authenticated) {
      final user = state.user;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF2196F3),
            child: Text(
              user.name.isNotEmpty ? user.name[0] : 'U',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          onPressed: () {
            if (user.role == Role.provider) {
              context.go('/provider-dashboard');
            } else {
              context.go('/profile-edit');
            }
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMainContent(BuildContext context, UserEntity user, List<ServiceCategory> categories, ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- WELCOME HEADER ---
          _buildWelcomeHeader(context, user, theme),
          
          // --- SEARCH BAR ---
          _buildSearchSection(context, theme),
          
          // --- QUICK ACTIONS ---
          _buildQuickActions(context, user, theme),
          
          // --- FEATURED SERVICES ---
          _buildFeaturedServices(context, categories, theme),
          
          // --- CATEGORIES GRID ---
          _buildCategoriesGrid(context, categories, theme),
          
          // --- BOTTOM SPACING ---
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, UserEntity user, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF9C27B0),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'স্বাগতম, ${user.name.split(' ').first}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.address ?? 'ঢাকা, বাংলাদেশ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('সার্চ স্ক্রিন (শীঘ্রই আসছে)')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.grey, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'সেবা, প্রোভাইডার, বা ক্যাটাগরি খুঁজুন...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(Icons.tune_rounded, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserEntity user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'দ্রুত অ্যাক্সেস',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildRoleSpecificActions(context, user.role, theme),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificActions(BuildContext context, Role role, ThemeData theme) {
    if (role == Role.provider) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/provider-dashboard'),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ড্যাশবোর্ডে যান',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'নতুন রিকোয়েস্ট ও পরিসংখ্যান দেখুন',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('বুকিং তালিকা (শীঘ্রই আসছে)')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আমার বুকিং',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'চলমান ও সম্পন্ন সেবাগুলো দেখুন',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedServices(BuildContext context, List<ServiceCategory> categories, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'জনপ্রিয় সেবা',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/services'),
                child: const Text('সব দেখুন'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: categories.take(6).length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 0,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: InkWell(
                    onTap: () => context.go('/services/${category.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.asset(
                                category.iconPath,
                                height: 32,
                                width: 32,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.category_rounded,
                                    size: 32,
                                    color: Color(0xFF2196F3),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, List<ServiceCategory> categories, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'সব ক্যাটাগরি',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/services/${category.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.asset(
                              category.iconPath,
                              height: 32,
                              width: 32,
                              color: Colors.white,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.category_rounded,
                                  size: 32,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.go('/providers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.person_search_rounded, color: Colors.white),
        label: const Text(
          'প্রোভাইডার খুঁজুন',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey.shade600,
        elevation: 0,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'হোম',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'সেবা',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'মেসেজ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'প্রোফাইল',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.go('/services');
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('মেসেজিং (শীঘ্রই আসছে)')),
              );
              break;
            case 3:
              context.go('/profile-edit');
              break;
          }
        },
      ),
    );
  }
}