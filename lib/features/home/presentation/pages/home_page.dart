import 'package:flutter/material.dart';
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

  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  double _searchRadius = 15.0;
  bool _showNearbyOnly = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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

    _animationController.forward();
    _heroAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heroAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _isLoadingLocation = false;
      });
      
      // Fallback to Dhaka center
      _userLocation = DummyData.dhanmondi;
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
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(context, theme),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          print('🔍 HomePage state: ${state.runtimeType}');
          
          // Show loading only during initial auth check
          if (state is AuthLoading || state is AuthInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('লোড হচ্ছে...'),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('লগইন করুন'),
                  ),
                ],
              ),
            );
          }
          
          return const Center(child: Text('কিছু ভুল হয়েছে'));
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(context, theme),
    );
  }

  // ========== APP BAR (Responsive to Auth State) ==========
  PreferredSizeWidget _buildModernAppBar(BuildContext context, ThemeData theme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
              Color(0xFF0D47A1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Logo/Icon
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_repair_service,
                      color: Color(0xFF9C27B0),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'শেবা',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'ডাক',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Icon
                // _buildSearchIcon(context),
                const SizedBox(width: 8),
                // Notification Icon (only for authenticated)
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildNotificationIcon(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Profile Icon or Login Button
                _buildProfileOrLoginButton(context),
                // Location Refresh
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoadingLocation 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
                  onPressed: _getUserLocation,
                  tooltip: 'লোকেশন আপডেট',
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('সার্চ ফিচার (শীঘ্রই আসছে)'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        tooltip: 'খুঁজুন',
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('নোটিফিকেশন (শীঘ্রই আসছে)'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'নোটিফিকেশন',
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOrLoginButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                if (user.role == Role.provider) {
                  context.push('/provider-dashboard');
                } else {
                  context.push('/profile-view');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        
        // Guest - Show login button
        return TextButton(
          onPressed: () => context.push('/login'),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'লগইন',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  // ========== AUTHENTICATED CONTENT ==========
  Widget _buildAuthenticatedContent(BuildContext context, UserEntity user, List<ServiceCategory> categories, ThemeData theme, List<ServiceProvider> filteredProviders) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, user, theme),
          _buildSearchSection(context, theme),
          _buildQuickActions(context, user, theme),
          _buildFeaturedServices(context, categories, theme),
          _buildCategoriesGrid(context, categories, theme),
          _buildLocationFilterCard(filteredProviders),
          if (!_isLoadingLocation) _buildProvidersList(filteredProviders),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ========== GUEST CONTENT ==========
  Widget _buildGuestContent(BuildContext context, List<ServiceCategory> categories, ThemeData theme, List<ServiceProvider> filteredProviders) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuestWelcomeHeader(context, theme),
          _buildSearchSection(context, theme),
          _buildGuestPrompt(context, theme), // ✅ Call to action
          _buildFeaturedServices(context, categories, theme),
          _buildCategoriesGrid(context, categories, theme),
          _buildLocationFilterCard(filteredProviders),
          if (!_isLoadingLocation) _buildProvidersList(filteredProviders),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLocationFilterCard(List<ServiceProvider> providers) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userLocation != null 
                      ? 'আপনার বর্তমান লোকেশন'
                      : 'লোকেশন লোড হচ্ছে...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Nearby Toggle
            Row(
              children: [
                const Expanded(
                  child: Text('কাছাকাছি সার্ভিস দেখুন'),
                ),
                Switch(
                  value: _showNearbyOnly,
                  onChanged: (value) {
                    setState(() {
                      _showNearbyOnly = value;
                    });
                  },
                  activeColor: const Color(0xFF2196F3),
                ),
              ],
            ),
            
            // Radius Slider (only show when nearby is enabled)
            if (_showNearbyOnly) ...[
              const SizedBox(height: 12),
              Text('সার্চ রেডিয়াস: ${_searchRadius.toStringAsFixed(0)} কিমি'),
              Slider(
                value: _searchRadius,
                min: 5.0,
                max: 50.0,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    _searchRadius = value;
                  });
                },
                activeColor: const Color(0xFF2196F3),
              ),
            ],
            
            // Results Info
            if (_userLocation != null) 
              Text(
                '${providers.length}টি সার্ভিস প্রোভাইডার পাওয়া গেছে',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList(List<ServiceProvider> providers) {
    if (providers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'কোন সার্ভিস প্রোভাইডার পাওয়া যায়নি',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              if (_showNearbyOnly)
                Text(
                  'সার্চ রেডিয়াস বাড়ান বা "কাছাকাছি সার্ভিস" বন্ধ করুন',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final distance = _userLocation != null && provider.businessLocation != null
            ? _calculateDistance(_userLocation!, provider.businessLocation!)
            : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2196F3),
              child: Text(
                provider.name.isNotEmpty ? provider.name[0] : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(provider.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (distance != null)
                  Text(
                    'দূরত্ব: ${distance.toStringAsFixed(1)} কিমি',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Wrap(
                  spacing: 4,
                  children: [
                    if (provider.isOnline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          'অনলাইন',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (provider.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Text(
                          'ভেরিফাইড',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(provider.rating.toStringAsFixed(1)),
                  ],
                ),
                if (provider.serviceRadius > 0)
                  Text(
                    '${provider.serviceRadius.toStringAsFixed(0)}কিমি',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
            onTap: () {
              // Navigate to provider details
              context.push('/provider-detail/${provider.id}');
            },
          ),
        );
      },
    );
  }

  // ========== WELCOME HEADERS ==========
  Widget _buildWelcomeHeader(BuildContext context, UserEntity user, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2196F3).withOpacity(0.9),
            const Color(0xFF1976D2).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'স্বাগতম, ${user.name.split(' ').first}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, 
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.address ?? 'ঢাকা, বাংলাদেশ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.waving_hand,
                        color: Color(0xFF9C27B0),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.yellow.shade300, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'বহুমুখী সেবার নির্ভরযোগ্য প্ল্যাটফর্ম',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2196F3).withOpacity(0.9),
            const Color(0xFF1976D2).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'শেবা ডাক-এ স্বাগতম!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'আপনার প্রয়োজনীয় সেবা খুঁজুন',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_repair_service,
                        color: Color(0xFF9C27B0),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.yellow.shade300, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'বহুমুখী সেবার নির্ভরযোগ্য প্ল্যাটফর্ম',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== GUEST PROMPT (Call to Action) ==========
  Widget _buildGuestPrompt(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'আপনার অ্যাকাউন্ট তৈরি করুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'সেবা বুক করতে, চ্যাট করতে এবং আরও সুবিধা পেতে লগইন করুন',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF9C27B0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'লগইন করুন',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'নিবন্ধন',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  // ========== SEARCH SECTION ==========
   // ========== SEARCH SECTION ==========
    Widget _buildSearchSection(BuildContext context, ThemeData theme) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: SmartSearchBar(
          onSearchSubmitted: (query) {
            if (query.isNotEmpty) {
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
      );
    }
  // ========== QUICK ACTIONS (Authenticated Users Only) ==========
  Widget _buildQuickActions(BuildContext context, UserEntity user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'দ্রুত অ্যাক্সেস',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
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
        gradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        iconColor: Colors.white,
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
              gradient: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              iconColor: Colors.white,
            ),
          ),
        _buildActionCard(
          context: context,
          onTap: () => context.push('/my-bookings'),
          icon: Icons.calendar_month_rounded,
          title: 'আমার বুকিং',
          subtitle: 'চলমান ও সম্পন্ন সেবাগুলো দেখুন',
          gradient: const [Color(0xFF2196F3), Color(0xFF1976D2)],
          iconColor: Colors.white,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, 
                      color: Colors.white.withOpacity(0.8), size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== FEATURED SERVICES ==========
  Widget _buildFeaturedServices(BuildContext context, List<ServiceCategory> categories, ThemeData theme) {
    final featuredCategories = categories.take(6).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'জনপ্রিয় সেবা',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 20,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/services/all'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2196F3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('সব দেখুন'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: featuredCategories.length,
            itemBuilder: (context, index) {
              final category = featuredCategories[index];
              final color = _getCategoryColor(index);
              
              return Container(
                width: 120,
                margin: EdgeInsets.only(
                  right: index == featuredCategories.length - 1 ? 20 : 16,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: InkWell(
                    onTap: () => context.push('/services/${category.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.asset(
                                category.iconPath,
                                height: 32,
                                width: 32,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.category_rounded,
                                    size: 32,
                                    color: color,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== CATEGORIES GRID ==========
  Widget _buildCategoriesGrid(BuildContext context, List<ServiceCategory> categories, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'সব ক্যাটাগরি',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
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
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = _getCategoryColor(index);
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/services/${category.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset(
                              category.iconPath,
                              height: 32,
                              width: 32,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.category_rounded,
                                  size: 32,
                                  color: color,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
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
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];
    return colors[index % colors.length];
  }

  // ========== FLOATING ACTION BUTTON ==========
  Widget _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/providers'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 6,
        heroTag: 'fab_search',
        icon: const Icon(Icons.person_search_rounded, size: 22),
        label: const Text(
          'প্রোভাইডার খুঁজুন',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ========== BOTTOM NAVIGATION ==========
  Widget _buildBottomNavigation(BuildContext context, ThemeData theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
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
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF2196F3),
              unselectedItemColor: Colors.grey.shade600,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              elevation: 0,
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home),
                  label: 'হোম',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  activeIcon: Icon(Icons.grid_view),
                  label: 'সেবা',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'মেসেজ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person),
                  label: 'প্রোফাইল',
                ),
              ],
              onTap: (index) {
                final isAuthenticated = state is Authenticated;
                
                switch (index) {
                  case 0:
                    // Already on home
                    break;
                  case 1:
                    
                    if (isAuthenticated) {
                      context.push('/services');
                      // context.push('/profile-view');
                    } else {
                      _showLoginPrompt(context);
                    }
                    break;
                  case 2:
                    if (isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('মেসেজিং (শীঘ্রই আসছে)'),
                          backgroundColor: Colors.blue,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
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

  // ========== LOGIN PROMPT DIALOG ==========
  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.login_rounded,
                color: Color(0xFF2196F3),
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
          'এই ফিচার ব্যবহার করতে আপনাকে লগইন করতে হবে।',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'বাতিল',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}