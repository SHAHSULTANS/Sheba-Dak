import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartsheba/core/search/presentation/widgets/smart_search_bar.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/features/provider/domain/entities/service_provider.dart';
import 'dart:math' as math;
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
  late AnimationController _heroAnimationController;
  late Animation<double> _heroScaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  LatLng? _userLocation;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  double _searchRadius = 15.0;
  bool _showNearbyOnly = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heroScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.elasticOut,
    ));
    // Add pulse animation for micro-interaction on FAB
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _heroAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heroAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      final position = await LocationService.getCurrentPosition();
      final address = await LocationService.getAddressFromPosition(position);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _currentAddress = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _isLoadingLocation = false;
      });
      // Fallback to Dhaka center
      _userLocation = DummyData.dhanmondi;
      _currentAddress = 'ঢাকা, বাংলাদেশ';
    }
  }

  List<ServiceProvider> _getFilteredProviders() {
    final allProviders = DummyData.getProviders();
    if (!_showNearbyOnly || _userLocation == null) {
      return allProviders;
    }
    return DummyData.getNearbyProviders(_userLocation!, maxDistance: _searchRadius);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371.0;
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    final categories = DummyData.getServiceCategories();
    final theme = Theme.of(context);
    final filteredProviders = _getFilteredProviders();
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true, // Allow gradient to extend
      appBar: _buildProfessionalAppBar(context, theme),
      body: Container(
        // Updated subtle background gradient for 2025 depth (warm neutrals trend)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.grey100,  // Warm beige fade
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            print('🔍 HomePage state: ${state.runtimeType}');
            // Show loading only during initial auth check
            if (state is AuthLoading || state is AuthInitial) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text('লোড হচ্ছে...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            // ✅ AUTHENTICATED USER - Full features
            if (state is Authenticated) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildAuthenticatedContent(context, state.user, categories, theme, filteredProviders),
                ),
              );
            }
            // ✅ GUEST USER - Browse freely with login prompts
            if (state is Unauthenticated) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildGuestContent(context, categories, theme, filteredProviders),
                ),
              );
            }
            // Error state
            if (state is AuthError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('লগইন করুন', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('কিছু ভুল হয়েছে', style: TextStyle(color: AppColors.textSecondary)));
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(context, theme),
    );
  }

  // ========== UPDATED PROFESSIONAL APP BAR (2025 Gradient overlay, electric blue theme) ==========
  PreferredSizeWidget _buildProfessionalAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent, // Transparent for gradient sync
      foregroundColor: AppColors.textPrimary,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Logo with neon accent (2025 futuristic)
            Hero(
              tag: 'app_logo',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,  // Updated gradient
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.home_repair_service,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title with bolder typography (2025 bold trend)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'শেবা',
                    style: TextStyle(
                      color: Color.fromARGB(255, 229, 231, 233),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'ডাক',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 229, 232, 237),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Notifications with micro-interaction badge
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 24),
                      onPressed: () {
                        HapticFeedback.lightImpact(); // Micro-interaction
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('নোটিফিকেশন'),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'নোটিফিকেশন',
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,  // Cherry red badge
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox(width: 48); // Spacer for alignment
          },
        ),
        // Profile/Login with enhanced avatar
        _buildProfileOrLoginButton(context),
        // Location with enhanced icon
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: _isLoadingLocation
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,  // Gradient icon
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _getUserLocation();
            },
            tooltip: 'লোকেশন আপডেট',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.surfaceVariant.withOpacity(0.5), // Softer divider
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,  // 2025 gradient app bar
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOrLoginButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (user.role == Role.provider) {
                  context.push('/provider-dashboard');
                } else {
                  context.push('/profile-view');
                }
              },
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        // Guest - Enhanced login button with icon
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: TextButton.icon(
            onPressed: () => context.push('/login'),
            icon: Icon(Icons.login_outlined, color: AppColors.textSecondary, size: 16),
            label: const Text(
              'লগইন',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 40),
            ),
          ),
        );
      },
    );
  }

  // ========== ENHANCED AUTHENTICATED CONTENT with Personalized Recommendations ==========
  Widget _buildAuthenticatedContent(BuildContext context, UserEntity user, List<ServiceCategory> categories, ThemeData theme, List<ServiceProvider> filteredProviders) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context, user, theme),
              _buildSearchSection(context, theme),
              _buildQuickActions(context, user, theme),
              _buildPersonalizedRecommendations(context, theme),
              _buildFeaturedServices(context, categories, theme),
              _buildCategoriesGrid(context, categories, theme),
              _buildLocationFilterCard(filteredProviders),
            ],
          ),
        ),
        if (!_isLoadingLocation)
          _buildProvidersList(filteredProviders),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ========== ENHANCED GUEST CONTENT ==========
  Widget _buildGuestContent(BuildContext context, List<ServiceCategory> categories, ThemeData theme, List<ServiceProvider> filteredProviders) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuestWelcomeHeader(context, theme),
              _buildSearchSection(context, theme),
              _buildGuestPrompt(context, theme),
              _buildFeaturedServices(context, categories, theme),
              _buildCategoriesGrid(context, categories, theme),
              _buildLocationFilterCard(filteredProviders),
            ],
          ),
        ),
        if (!_isLoadingLocation)
          _buildProvidersList(filteredProviders),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ========== UPDATED: Personalized Recommendations Section (2025 AI-driven with neon accents) ==========
  Widget _buildPersonalizedRecommendations(BuildContext context, ThemeData theme) {
    // Dummy personalized data
    final recommendations = DummyData.getRecommendedServices(); // Assume this exists in dummy_data.dart
    if (recommendations.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'আপনার জন্য সাজেস্টেড',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/recommendations'),
                icon: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accent),  // Neon green arrow
                label: const Text('সব দেখুন', style: TextStyle(color: AppColors.accent)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                final color = _getCategoryColor(index);
                return Container(
                  width: 140,
                  margin: EdgeInsets.only(right: index == recommendations.length - 1 ? 20 : 16),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: InkWell(
                      onTap: () => context.push('/service-detail/${rec.id}'),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppColors.successGradient,  // Updated gradient
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.favorite_border, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rec.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳${rec.price}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
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
      ),
    );
  }

  Widget _buildLocationFilterCard(List<ServiceProvider> providers) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.surfaceVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আপনার লোকেশন',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        _currentAddress ?? 'লোকেশন লোড হচ্ছে...',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingLocation)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Enhanced Nearby Toggle with better UX
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'কাছাকাছি সার্ভিস দেখুন',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _showNearbyOnly ? 'শুধুমাত্র ১৫কিমি এর মধ্যে' : 'সব এলাকা থেকে',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showNearbyOnly,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showNearbyOnly = value;
                    });
                  },
                  activeColor: AppColors.accent,  // Neon green switch
                  activeTrackColor: AppColors.accent.withOpacity(0.3),
                ),
              ],
            ),
            // Enhanced Radius Slider with thumb icon
            if (_showNearbyOnly) ...[
              const SizedBox(height: 16),
              Text(
                'সার্চ রেডিয়াস: ${_searchRadius.toStringAsFixed(0)} কিমি',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: AppColors.accent,
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _searchRadius,
                  min: 5.0,
                  max: 50.0,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _searchRadius = value;
                    });
                  },
                ),
              ),
            ],
            // Results Info with badge
            if (_userLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${providers.length}টি প্রোভাইডার',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList(List<ServiceProvider> providers) {
    if (providers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 80, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'কোন সার্ভিস প্রোভাইডার পাওয়া যায়নি',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_showNearbyOnly)
                Text(
                  'সার্চ রেডিয়াস বাড়ান বা "কাছাকাছি সার্ভিস" বন্ধ করুন',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showNearbyOnly = false),
                icon: const Icon(Icons.refresh),
                label: const Text('আবার চেষ্টা করুন'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final provider = providers[index];
          final distance = _userLocation != null && provider.businessLocation != null
              ? _calculateDistance(_userLocation!, provider.businessLocation!)
              : null;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.surfaceVariant.withOpacity(0.3)),
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push('/provider-detail/${provider.id}');
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with online indicator
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              provider.name.isNotEmpty ? provider.name[0] : '?',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (provider.isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Provider info section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              provider.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Verified Badge (below name)
                            if (provider.isVerified) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.verified, color: Colors.white, size: 14),
                                    SizedBox(width: 2),
                                    Text(
                                      'ভেরিফাইড',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Description
                            Text(
                              provider.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),

                            const SizedBox(height: 10),

                            // Distance
                            if (distance != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: AppColors.success, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distance.toStringAsFixed(1)} কিমি দূরে',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Ratings + service radius
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(
                                5,
                                (starIndex) => Icon(
                                  starIndex < provider.rating.floor() ? Icons.star : Icons.star_border,
                                  color: AppColors.rating,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${provider.rating.toStringAsFixed(1)})',
                                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                          if (provider.serviceRadius > 0)
                            Text(
                              '${provider.serviceRadius.toStringAsFixed(0)} কিমি',
                              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: providers.length,
      ),
    );


  }

  // ========== ENHANCED WELCOME HEADERS with gradient updates ==========
  Widget _buildWelcomeHeader(BuildContext context, UserEntity user, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,  // Updated to primary gradient
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.waving_hand, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'হ্যালো, ${user.name.split(' ').first}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,  // White text on gradient
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.9), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _currentAddress ?? user.address ?? 'ঢাকা, বাংলাদেশ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Hero(
                tag: 'welcome_avatar',
                child: ScaleTransition(
                  scale: _heroScaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestWelcomeHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'শেবা ডাক-এ স্বাগতম!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'আপনার প্রয়োজনীয় সেবা খুঁজুন',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Hero(
                tag: 'welcome_avatar',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_repair_service,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== ENHANCED GUEST PROMPT with gradient updates ==========
  Widget _buildGuestPrompt(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.08),
              AppTheme.primaryColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.account_circle, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'আপনার অ্যাকাউন্ট তৈরি করুন',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'সেবা বুক করতে, চ্যাট করতে এবং আরও সুবিধা পেতে লগইন করুন',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      context.push('/login');
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('লগইন করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/register');
                    },
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text('নিবন্ধন'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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

  // ========== ENHANCED SEARCH SECTION with better integration ==========
  Widget _buildSearchSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: Column(
        children: [
          SmartSearchBar(
            onSearchSubmitted: (query) {
              if (query.isNotEmpty) {
                HapticFeedback.mediumImpact();
                context.push('/search-results', extra: {'query': query});
              }
            },
            showNearbyFilter: true,
            onNearbyFilterChanged: (enabled) {
              setState(() {
                _showNearbyOnly = enabled;
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ========== ENHANCED QUICK ACTIONS with updated gradients ==========
  Widget _buildQuickActions(BuildContext context, UserEntity user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'দ্রুত অ্যাক্সেস',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 20,
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
      return _buildActionCard(
        context: context,
        onTap: () => context.push('/provider-dashboard'),
        icon: Icons.dashboard_rounded,
        title: 'ড্যাশবোর্ডে যান',
        subtitle: 'নতুন রিকোয়েস্ট ও পরিসংখ্যান দেখুন',
        gradient: [AppColors.primary.withOpacity(0.1), Colors.transparent],
        iconColor: AppColors.primary,
      );
    }
    return Column(
      children: [
        if (role == Role.customer)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildActionCard(
              context: context,
              onTap: () => context.push('/provider-registration'),
              icon: Icons.work_history_rounded,
              title: 'প্রোভাইডার হোন',
              subtitle: 'আপনার সেবা প্রদান শুরু করতে আবেদন করুন',
              gradient: [AppColors.secondary.withOpacity(0.1), Colors.transparent],
              iconColor: AppColors.secondary,
            ),
          ),
        _buildActionCard(
          context: context,
          onTap: () => context.push('/my-bookings'),
          icon: Icons.calendar_month_rounded,
          title: 'আমার বুকিং',
          subtitle: 'চলমান ও সম্পন্ন সেবাগুলো দেখুন',
          gradient: [AppColors.primary.withOpacity(0.1), Colors.transparent],
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,  // Consistent gradient
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== ENHANCED FEATURED SERVICES with updated layouts ==========
  Widget _buildFeaturedServices(BuildContext context, List<ServiceCategory> categories, ThemeData theme) {
    final featuredCategories = categories.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'জনপ্রিয় সেবা',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/services/all'),
                icon: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accent),
                label: Text('সব দেখুন', style: TextStyle(color: AppColors.accent)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: featuredCategories.length,
            itemBuilder: (context, index) {
              final category = featuredCategories[index];
              final color = _getCategoryColor(index);
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: index == featuredCategories.length - 1 ? 20 : 16),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/services/${category.id}');
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                category.iconPath,
                                fit: BoxFit.cover,
                                height: 70,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.category_rounded,
                                    size: 36,
                                    color: color,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${category.name} সার্ভিস',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
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

  // ========== ENHANCED CATEGORIES GRID with updated cards ==========
  Widget _buildCategoriesGrid(BuildContext context, List<ServiceCategory> categories, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'সব ক্যাটাগরি',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = _getCategoryColor(index);
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/services/${category.id}');
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.2), Colors.transparent],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.asset(
                              category.iconPath,
                              height: 40,
                              width: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.category_rounded,
                                  size: 40,
                                  color: color,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
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

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppColors.accent,
      AppColors.secondary,
      AppColors.warning,
      AppColors.error,
      Colors.cyan,
      Colors.brown,
      Colors.blueGrey,
    ];
    return colors[index % colors.length];
  }

  // ========== ENHANCED FLOATING ACTION BUTTON with neon pulse ==========
  Widget _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),  // Neon glow
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.heavyImpact();
            context.push('/providers');
          },
          backgroundColor: AppColors.accent,  // Neon green FAB
          foregroundColor: Colors.white,
          elevation: 0,
          heroTag: 'fab_search',
          icon: const Icon(Icons.person_search_rounded, size: 24),
          label: const Text(
            'প্রোভাইডার খুঁজুন',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ========== ENHANCED BOTTOM NAVIGATION with updated colors ==========
  Widget _buildBottomNavigation(BuildContext context, ThemeData theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border(
              top: BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.accent,  // Neon green selected
              unselectedItemColor: AppColors.textTertiary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              elevation: 0,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              currentIndex: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined, size: 26),
                  activeIcon: Icon(Icons.home, size: 26, color: AppColors.accent),
                  label: 'হোম',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.grid_view_outlined, size: 26),
                  activeIcon: Icon(Icons.grid_view, size: 26, color: AppColors.accent),
                  label: 'সেবা',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  activeIcon: Icon(Icons.chat_bubble, size: 26, color: AppColors.accent),
                  label: 'মেসেজ',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline, size: 26),
                  activeIcon: Icon(Icons.person, size: 26, color: AppColors.accent),
                  label: 'প্রোফাইল',
                ),
              ],
              onTap: (index) {
                HapticFeedback.lightImpact();
                final isAuthenticated = state is Authenticated;
                switch (index) {
                  case 0:
                    // Already on home
                    break;
                  case 1:
                    if (isAuthenticated) {
                      context.push('/services');
                    } else {
                      _showLoginPrompt(context);
                    }
                    break;
                  case 2:
                    if (isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('মেসেজিং'),
                          backgroundColor: AppTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      _showLoginPrompt(context);
                    }
                    break;
                  case 3:
                    if (isAuthenticated) {
                      context.push('/profile-view');
                    } else {
                      _showLoginPrompt(context);
                    }
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  // ========== ENHANCED LOGIN PROMPT DIALOG with updated styling ==========
  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.login_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'লগইন প্রয়োজন',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'এই ফিচার ব্যবহার করতে আপনাকে লগইন করতে হবে।',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'বাতিল',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/login');
                      },
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('লগইন করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,  // Neon green button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}