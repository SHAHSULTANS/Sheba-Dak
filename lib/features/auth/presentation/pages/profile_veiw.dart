import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/core/theme/app_theme.dart';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _resourcesPrecached = false;
  bool _isDisposed = false;

  // Feature flags for gradual rollout
  static const bool _enableAdvancedAnalytics = true;
  static const bool _enableAchievements = false;
  static const bool _enableSocialFeatures = false;

  @override
  bool get wantKeepAlive => true;

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
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scrollController.addListener(_onScroll);

    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _animationController.forward();
      }
    });

    // Handle async precache in post frame to avoid sync exceptions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheResourcesAsync();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_resourcesPrecached && mounted) {
      _resourcesPrecached = true;
    }
  }

  Future<void> _precacheResourcesAsync() async {
    // Precache only if assets exist - handle async errors properly
    // Skip achievement badge since feature disabled and causing load errors
    if (_enableAchievements) {
      try {
        await precacheImage(const AssetImage('assets/images/achievement_badge.png'), context);
      } catch (e) {
        debugPrint('Achievement badge asset not found: $e - skipping precache');
      }
    }
    // Skip precaching profile_empty_state.png to avoid load error (asset missing)
    debugPrint('Profile empty state asset skipped to prevent load error');
  }

  void _onScroll() {
    // Debounce scroll updates to reduce rebuilds
    final isScrolled = _scrollController.offset > 100;
    if (_isScrolled != isScrolled && mounted) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      buildWhen: (previous, current) {
        // Optimize rebuilds - only rebuild on significant state changes
        return previous.runtimeType != current.runtimeType ||
               (previous is Authenticated && current is Authenticated &&
                previous.user != current.user);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
          floatingActionButton: state is Authenticated ? _buildQuickActions(context) : null,
        );
      },
    );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (!mounted) return;

    if (state is Unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login', extra: {
            'showLogoutMessage': true,
            'message': 'সফলভাবে লগআউট হয়েছে'
          });
        }
      });
    } else if (state is AuthError) {
      _showErrorSnackBar(context, state.message);
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthState state) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: _isScrolled ? Colors.white : Colors.transparent,
      elevation: _isScrolled ? 2 : 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: _isScrolled ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.primaryColor,
            size: 18,
          ),
        ),
        onPressed: () => _handleBackNavigation(context),
      ),
      title: AnimatedOpacity(
        opacity: _isScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          'প্রোফাইল',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
      actions: state is Authenticated
          ? [_buildAppBarActions(context, state.user, theme)]
          : null,
    );
  }

  Widget _buildAppBarActions(BuildContext context, UserEntity user, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notification Bell with Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: _isScrolled ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              onPressed: () => _showNotifications(context),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),

        // Settings Menu
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          offset: const Offset(0, 50),
          onSelected: (value) => _handleAppBarMenuSelection(context, value),
          itemBuilder: (context) => [
            _buildPopupMenuItem('settings', Icons.settings_rounded, 'সেটিংস', theme.primaryColor),
            _buildPopupMenuItem('help', Icons.help_rounded, 'সাহায্য', Colors.orange),
            const PopupMenuDivider(),
            _buildPopupMenuItem('invite', Icons.person_add_rounded, 'বন্ধুকে আমন্ত্রণ করুন', Colors.green),
          ],
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _isScrolled ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.more_vert_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      return RepaintBoundary(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshUserData,
              color: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildProfileHeader(context, state.user),
                  _buildProfileContent(context, state.user),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _buildLoadingState();
  }

  Future<void> _refreshUserData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      debugPrint('🔄 User data refreshed');
    }
  }

  SliverAppBar _buildProfileHeader(BuildContext context, UserEntity user) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return SliverAppBar(
      expandedHeight: screenHeight * 0.26, // FIX: Slightly increased to 0.26 for more breathing room
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.85),
                  const Color(0xFF9C27B0),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.26 - MediaQuery.of(context).padding.top - 50,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        _buildProfileAvatar(user, theme),
                        const SizedBox(height: 8),
                        Flexible(
                          child: _buildProfileInfo(user),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 60, // FIX: Increased back to 60 to prevent overflow in stats
                          child: _buildProfileStats(user),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserEntity user, ThemeData theme) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    return RepaintBoundary(
      child: Container(
        width: isSmallScreen ? 100.0 : 110.0,
        height: isSmallScreen ? 100.0 : 110.0,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Main Profile Avatar Container
            Container(
              width: isSmallScreen ? 80.0 : 90.0,
              height: isSmallScreen ? 80.0 : 90.0,
              padding: EdgeInsets.all(isSmallScreen ? 1.5 : 2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isSmallScreen ? 38.0 : 42.0,
                backgroundColor: Colors.white,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!) as ImageProvider
                    : null,
                child: user.profileImageUrl == null
                    ? Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24.0 : 28.0,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // Verification Badge - Positioned relative to the main container
            Positioned(
              bottom: -3,
              right: -3,
              child: Container(
                width: isSmallScreen ? 22.0 : 24.0,
                height: isSmallScreen ? 22.0 : 24.0,
                padding: EdgeInsets.all(isSmallScreen ? 2.5 : 3.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.primaryColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  user.isVerified ? Icons.verified_rounded : Icons.verified_outlined,
                  color: user.isVerified ? const Color(0xFF4CAF50) : Colors.grey,
                  size: isSmallScreen ? 11.0 : 12.0,
                ),
              ),
            ),

            // Edit Profile Button - Positioned relative to the main container
            Positioned(
              bottom: -3,
              left: -3,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: Container(
                  width: isSmallScreen ? 22.0 : 24.0,
                  height: isSmallScreen ? 22.0 : 24.0,
                  child: InkWell(
                    onTap: () => context.push('/profile-edit'),
                    customBorder: const CircleBorder(),
                    child: Icon(
                      Icons.edit_rounded,
                      size: isSmallScreen ? 11.0 : 12.0,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserEntity user) {
    return RepaintBoundary(
      child: Column(
        children: [
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.0, // FIX: Explicit line height
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            user.phoneNumber,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.0, // FIX: Explicit line height
            ),
          ),
          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              user.email!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.0, // FIX: Explicit line height
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              user.role == Role.provider ? 'সেবা প্রদানকারী' : 'সেবা গ্রহীতা',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.0, // FIX: Explicit line height
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats(UserEntity user) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('২৫', 'মোট কাজ'),
            _buildStatItem('৪.৮', 'রেটিং'),
            _buildStatItem('৯৮%', 'সফলতা'),
            _buildStatItem('১২', 'বর্তমান'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14, // FIX: Slightly reduced to 14
            fontWeight: FontWeight.bold,
            height: 1.0, // FIX: Explicit line height to prevent overflow
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            height: 1.0, // FIX: Explicit line height
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildProfileContent(BuildContext context, UserEntity user) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
           
            // Quick Actions Card
            _buildQuickActionsCard(context, user, theme),
           
            const SizedBox(height: 16),
           
            // Account Information Section
            _buildSection(
              context: context,
              title: 'একাউন্ট তথ্য',
              icon: Icons.person_outline_rounded,
              children: _buildAccountInfoItems(context, user),
            ),
            // Professional Section (Provider only)
            if (user.role == Role.provider) ...[
              const SizedBox(height: 16),
              _buildSection(
                context: context,
                title: 'পেশাগত',
                icon: Icons.work_outline_rounded,
                children: _buildProfessionalItems(context, user),
              ),
            ],
            // Analytics Section
            if (_enableAdvancedAnalytics) ...[
              const SizedBox(height: 16),
              _buildSection(
                context: context,
                title: 'এনালিটিক্স',
                icon: Icons.analytics_outlined,
                children: _buildAnalyticsItems(context, user),
              ),
            ],
            // Preferences Section
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: 'পছন্দসমূহ',
              icon: Icons.settings_outlined,
              children: _buildPreferenceItems(context, user),
            ),
            // Support Section
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: 'সহায়তা',
              icon: Icons.help_outline_rounded,
              children: _buildSupportItems(context, user),
            ),
            // Legal Section
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: 'আইনগত',
              icon: Icons.security_outlined,
              children: _buildLegalItems(context, user),
            ),
            // Logout Section
            const SizedBox(height: 16),
            _buildLogoutCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, UserEntity user, ThemeData theme) {
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withOpacity(0.08),
                const Color(0xFF9C27B0).withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'দ্রুত একশন',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'নতুন',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickActionChip(
                      icon: Icons.qr_code_rounded,
                      label: 'কিউআর কোড',
                      onTap: () => _showQRCode(context, user),
                    ),
                    _buildQuickActionChip(
                      icon: Icons.share_rounded,
                      label: 'শেয়ার করুন',
                      onTap: () => _shareProfile(context, user),
                    ),
                    _buildQuickActionChip(
                      icon: Icons.card_membership_rounded,
                      label: 'মেম্বারশিপ',
                      onTap: () => _showMembership(context, user),
                    ),
                    _buildQuickActionChip(
                      icon: Icons.star_border_rounded,
                      label: 'রিভিউ',
                      onTap: () => _showReviews(context, user),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  List<Widget> _buildAccountInfoItems(BuildContext context, UserEntity user) {
    return [
      _buildInfoTile(
        icon: Icons.person_outline_rounded,
        title: 'নাম',
        subtitle: user.name,
        onTap: () => context.push('/profile-edit'),
        showEdit: true,
      ),
      _buildInfoTile(
        icon: Icons.phone_rounded,
        title: 'ফোন নম্বর',
        subtitle: user.phoneNumber,
        trailing: _buildVerifiedBadge(),
      ),
      if (user.email != null && user.email!.isNotEmpty)
        _buildInfoTile(
          icon: Icons.email_rounded,
          title: 'ইমেইল',
          subtitle: user.email!,
          onTap: () => context.push('/profile-edit'),
          showEdit: true,
        ),
      _buildInfoTile(
        icon: Icons.location_on_rounded,
        title: 'ঠিকানা',
        subtitle: user.address ?? 'ঠিকানা যোগ করুন',
        onTap: () => context.push('/profile-edit'),
        showEdit: true,
      ),
      _buildInfoTile(
        icon: Icons.cake_rounded,
        title: 'জন্ম তারিখ',
        subtitle: user.dateOfBirth != null
            ? '${user.dateOfBirth!.day}-${user.dateOfBirth!.month}-${user.dateOfBirth!.year}'
            : 'যোগ করুন',
        onTap: () => context.push('/profile-edit'),
        showEdit: true,
      ),
    ];
  }

  List<Widget> _buildProfessionalItems(BuildContext context, UserEntity user) {
    return [
      _buildActionTile(
        icon: Icons.dashboard_rounded,
        title: 'প্রোভাইডার ড্যাশবোর্ড',
        subtitle: 'আপনার সেবা ব্যবস্থাপনা',
        onTap: () => context.push('/provider-dashboard'),
        color: Colors.green,
        badge: '৫ নতুন',
      ),
      _buildActionTile(
        icon: Icons.request_quote_rounded,
        title: 'সেবা রিকোয়েস্ট',
        subtitle: 'নতুন রিকোয়েস্ট দেখুন',
        onTap: () => context.push('/incoming-requests'),
        color: Colors.orange,
        badge: '৩ অপেক্ষমান',
      ),
      _buildActionTile(
        icon: Icons.analytics_rounded,
        title: 'পরিসংখ্যান',
        subtitle: 'বিস্তারিত বিশ্লেষণ',
        onTap: () => _showAnalytics(context),
        color: Colors.purple,
      ),
    ];
  }

  List<Widget> _buildAnalyticsItems(BuildContext context, UserEntity user) {
    return [
      _buildActionTile(
        icon: Icons.trending_up_rounded,
        title: 'কর্মক্ষমতা',
        subtitle: 'আপনার সেবা পরিসংখ্যান',
        onTap: () => _showPerformance(context),
        color: Colors.blue,
      ),
      _buildActionTile(
        icon: Icons.insights_rounded,
        title: 'আয় বিশ্লেষণ',
        subtitle: 'মাসিক আয় ও প্রবণতা',
        onTap: () => _showEarnings(context),
        color: Colors.green,
      ),
    ];
  }

  List<Widget> _buildPreferenceItems(BuildContext context, UserEntity user) {
    return [
      _buildActionTile(
        icon: Icons.notifications_rounded,
        title: 'নোটিফিকেশন',
        subtitle: 'নোটিফিকেশন সেটিংস',
        onTap: () => _showNotificationSettings(context),
        color: Colors.purple,
      ),
      _buildActionTile(
        icon: Icons.language_rounded,
        title: 'ভাষা',
        subtitle: 'বাংলা',
        onTap: () => _showLanguageSettings(context),
        color: Colors.teal,
      ),
      _buildActionTile(
        icon: Icons.palette_rounded,
        title: 'থিম',
        subtitle: 'গাঢ় / হালকা',
        onTap: () => _showThemeSettings(context),
        color: Colors.indigo,
      ),
      _buildActionTile(
        icon: Icons.security_rounded,
        title: 'গোপনীয়তা',
        subtitle: 'ডেটা ও গোপনীয়তা সেটিংস',
        onTap: () => _showPrivacySettings(context),
        color: Colors.blueGrey,
      ),
    ];
  }

  List<Widget> _buildSupportItems(BuildContext context, UserEntity user) {
    return [
      _buildActionTile(
        icon: Icons.help_center_rounded,
        title: 'সাহায্য কেন্দ্র',
        subtitle: 'সচরাচর জিজ্ঞাসা ও সমাধান',
        onTap: () => _showHelpCenter(context),
        color: Colors.orange,
      ),
      _buildActionTile(
        icon: Icons.support_agent_rounded,
        title: 'গ্রাহক সেবা',
        subtitle: '২৪/৭ সাপোর্ট',
        onTap: () => _showCustomerSupport(context),
        color: Colors.green,
      ),
      _buildActionTile(
        icon: Icons.feedback_rounded,
        title: 'ফিডব্যাক দিন',
        subtitle: 'আমাদের মতামত জানান',
        onTap: () => _showFeedback(context),
        color: Colors.pink,
      ),
    ];
  }

  List<Widget> _buildLegalItems(BuildContext context, UserEntity user) {
    return [
      _buildActionTile(
        icon: Icons.description_rounded,
        title: 'সেবার শর্তাবলী',
        subtitle: 'ব্যবহারের নিয়ম ও শর্ত',
        onTap: () => _showTermsOfService(context),
        color: Colors.grey,
      ),
      _buildActionTile(
        icon: Icons.privacy_tip_rounded,
        title: 'গোপনীয়তা নীতি',
        subtitle: 'ডেটা সুরক্ষা নীতি',
        onTap: () => _showPrivacyPolicy(context),
        color: Colors.blueGrey,
      ),
      _buildActionTile(
        icon: Icons.gavel_rounded,
        title: 'কপিরাইট',
        subtitle: '© ২০২৫ স্মার্টশেবা',
        onTap: () => _showCopyright(context),
        color: Colors.brown,
      ),
    ];
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: List.generate(
                children.length,
                (index) => Column(
                  children: [
                    children[index],
                    if (index < children.length - 1)
                      Divider(height: 1, color: Colors.grey.shade200),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool showEdit = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.grey.shade700, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.0, // FIX: Explicit line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (showEdit && onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.0, // FIX: Explicit line height
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.0, // FIX: Explicit line height
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.0, // FIX: Explicit line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'লগআউট',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                        height: 1.0, // FIX: Explicit line height
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.red.shade300,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 11, color: Colors.green.shade700),
          const SizedBox(width: 3),
          Text(
            'যাচাইকৃত',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.0, // FIX: Explicit line height
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.white),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                childCount: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'settings_fab',
            onPressed: () => _showQuickSettings(context),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            child: const Icon(Icons.settings_rounded, size: 20),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'scroll_top_fab',
            onPressed: _scrollToTop,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.arrow_upward_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  // Navigation and Action Handlers
  void _handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Feature Methods
  void _showNotifications(BuildContext context) {
    _showSuccessSnackBar(context, 'নোটিফিকেশন প্যানেল (শীঘ্রই আসছে)');
  }

  void _handleAppBarMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        _showQuickSettings(context);
        break;
      case 'help':
        _showHelpCenter(context);
        break;
      case 'invite':
        final state = context.read<AuthBloc>().state;
        if (state is Authenticated) {
          _shareProfile(context, state.user);
        }
        break;
    }
  }

  void _showQRCode(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('আপনার প্রোফাইল কোড', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.qr_code_rounded,
                size: 90,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'এই কিউআর কোড স্ক্যান করে আপনার প্রোফাইল দেখুন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  void _shareProfile(BuildContext context, UserEntity user) {
    _showSuccessSnackBar(context, 'প্রোফাইল শেয়ার লিঙ্ক কপি করা হয়েছে');
  }

  void _showMembership(BuildContext context, UserEntity user) {
    context.push('/membership');
  }

  void _showReviews(BuildContext context, UserEntity user) {
    context.push('/reviews');
  }

  void _showAnalytics(BuildContext context) {
    context.push('/analytics');
  }

  void _showPerformance(BuildContext context) {
    context.push('/performance');
  }

  void _showEarnings(BuildContext context) {
    context.push('/earnings');
  }

  void _showNotificationSettings(BuildContext context) {
    context.push('/notification-settings');
  }

  void _showLanguageSettings(BuildContext context) {
    context.push('/language-settings');
  }

  void _showThemeSettings(BuildContext context) {
    context.push('/theme-settings');
  }

  void _showPrivacySettings(BuildContext context) {
    context.push('/privacy-settings');
  }

  void _showHelpCenter(BuildContext context) {
    context.push('/help-center');
  }

  void _showCustomerSupport(BuildContext context) {
    context.push('/customer-support');
  }

  void _showFeedback(BuildContext context) {
    context.push('/feedback');
  }

  void _showTermsOfService(BuildContext context) {
    context.push('/terms-of-service');
  }

  void _showPrivacyPolicy(BuildContext context) {
    context.push('/privacy-policy');
  }

  void _showCopyright(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('কপিরাইট', style: TextStyle(fontSize: 18)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('© ২০২৫ স্মার্টশেবা', style: TextStyle(fontSize: 15)),
            SizedBox(height: 6),
            Text('সমস্ত অধিকার সংরক্ষিত।', style: TextStyle(fontSize: 14)),
            SizedBox(height: 6),
            Text('সংস্করণ: 1.0.0 (বিল্ড ২০২৫.১০.১৪)',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  void _showQuickSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'দ্রুত সেটিংস',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Center(
                    child: Text(
                      'কন্টেন্ট শীঘ্রই যোগ করা হবে',
                      style: TextStyle(color: Colors.grey),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('লগআউট করবেন?', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান? আপনি পুনরায় লগইন করতে আপনার ফোন নম্বর ব্যবহার করবেন।',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (context.mounted) {
                context.read<AuthBloc>().add(LogoutEvent());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
  }
}