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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  
  final _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isScrolled = false;
  
  // Feature flags for gradual rollout
  static const bool _enableAdvancedAnalytics = true;
  static const bool _enableAchievements = false; // Coming soon
  static const bool _enableSocialFeatures = false; // Coming soon

  bool _resourcesPrecached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scrollController.addListener(_onScroll);
    _animationController.forward();
    
    // Pre-cache images for better performance - moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_resourcesPrecached) {
      _precacheResources();
      _resourcesPrecached = true;
    }
  }

  void _precacheResources() {
    precacheImage(const AssetImage('assets/images/achievement_badge.png'), context);
    precacheImage(const AssetImage('assets/images/profile_empty_state.png'), context);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isScrolled = _scrollOffset > 100;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh user data when app comes to foreground
      _refreshUserData();
    }
  }

  void _refreshUserData() {
    // In a real app, this would refresh from API
    print('🔄 Refreshing user data...');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        _handleAuthStateChanges(context, state);
      },
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: _buildAppBar(context, state, theme),
            body: _buildBody(context, state, theme, screenHeight),
            floatingActionButton: _buildQuickActions(context, state),
          ),
        );
      },
    );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is Unauthenticated) {
      Future.microtask(() {
        context.go('/login', extra: {
          'showLogoutMessage': true,
          'message': 'সফলভাবে লগআউট হয়েছে'
        });
      });
    } else if (state is AuthError) {
      _showErrorSnackBar(context, state.message);
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthState state, ThemeData theme) {
    return AppBar(
      backgroundColor: _isScrolled 
          ? _backgroundColorAnimation.value
          : Colors.transparent,
      elevation: _isScrolled ? 4 : 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.primaryColor,
            size: 20,
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
      actions: [
        if (state is Authenticated) ...[
          _buildAppBarActions(context, state.user, theme),
        ],
      ],
    );
  }

  Widget _buildAppBarActions(BuildContext context, UserEntity user, ThemeData theme) {
    return Row(
      children: [
        // Notification Bell with Badge
        Stack(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: theme.primaryColor,
                  size: 22,
                ),
              ),
              onPressed: () => _showNotifications(context),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
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
          onSelected: (value) => _handleAppBarMenuSelection(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  const Text('সেটিংস'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text('সাহায্য'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'invite',
              child: Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text('বন্ধুকে আমন্ত্রণ করুন'),
                ],
              ),
            ),
          ],
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.more_vert_rounded,
              color: theme.primaryColor,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AuthState state, ThemeData theme, double screenHeight) {
    if (state is Authenticated) {
      return SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshUserData(); // Removed await: sync void can't be awaited
            },
            color: theme.primaryColor,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildProfileHeader(context, state.user, theme, screenHeight),
                _buildProfileContent(context, state.user, theme),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      );
    }
    
    return _buildLoadingState(theme);
  }

  SliverAppBar _buildProfileHeader(BuildContext context, UserEntity user, ThemeData theme, double screenHeight) {
    return SliverAppBar(
      expandedHeight: screenHeight * 0.35,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withOpacity(0.8),
                const Color(0xFF9C27B0),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfileAvatar(user, theme),
                const SizedBox(height: 20),
                _buildProfileInfo(user, theme),
                const SizedBox(height: 16),
                _buildProfileStats(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserEntity user, ThemeData theme) {
    return Stack(
      children: [
        // Animated Background Circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
        ),
        
        // Profile Avatar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: user.profileImageUrl != null 
                ? NetworkImage(user.profileImageUrl!) as ImageProvider
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  )
                : null,
          ),
        ),
        
        // Verification Badge
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryColor, width: 2),
            ),
            child: Icon(
              user.isVerified ? Icons.verified_rounded : Icons.verified_outlined,
              color: user.isVerified ? const Color(0xFF4CAF50) : Colors.grey,
              size: 20,
            ),
          ),
        ),
        
        // Edit Profile FAB
        Positioned(
          bottom: 0,
          left: 0,
          child: FloatingActionButton.small(
            onPressed: () => context.push('/profile-edit'),
            backgroundColor: Colors.white,
            foregroundColor: theme.primaryColor,
            child: const Icon(Icons.edit_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserEntity user, ThemeData theme) {
    return Column(
      children: [
        Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.phoneNumber,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            user.email!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.role == Role.provider ? 'সেবা প্রদানকারী' : 'সেবা গ্রহীতা',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats(UserEntity user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildProfileContent(BuildContext context, UserEntity user, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Quick Actions Card
            _buildQuickActionsCard(context, user, theme),
            
            const SizedBox(height: 20),
            
            // Account Information Section
            _buildSection(
              context: context,  // Fixed: Named parameter
              title: 'একাউন্ট তথ্য',
              icon: Icons.person_outline_rounded,
              children: _buildAccountInfoItems(context, user),
            ),

            // Professional Section (Provider only)
            if (user.role == Role.provider) ...[
              const SizedBox(height: 20),
              _buildSection(
                context: context,  // Fixed: Named parameter
                title: 'পেশাগত',
                icon: Icons.work_outline_rounded,
                children: _buildProfessionalItems(context, user),
              ),
            ],

            // Analytics Section
            if (_enableAdvancedAnalytics) ...[
              const SizedBox(height: 20),
              _buildSection(
                context: context,  // Fixed: Named parameter
                title: 'এনালিটিক্স',
                icon: Icons.analytics_outlined,
                children: _buildAnalyticsItems(context, user),
              ),
            ],

            // Preferences Section
            const SizedBox(height: 20),
            _buildSection(
              context: context,  // Fixed: Named parameter
              title: 'পছন্দসমূহ',
              icon: Icons.settings_outlined,
              children: _buildPreferenceItems(context, user),
            ),

            // Support Section
            const SizedBox(height: 20),
            _buildSection(
              context: context,  // Fixed: Named parameter
              title: 'সহায়তা',
              icon: Icons.help_outline_rounded,
              children: _buildSupportItems(context, user),
            ),

            // Legal Section
            const SizedBox(height: 20),
            _buildSection(
              context: context,  // Fixed: Named parameter
              title: 'আইনগত',
              icon: Icons.security_outlined,
              children: _buildLegalItems(context, user),
            ),

            // Logout Section
            const SizedBox(height: 24),
            _buildLogoutCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, UserEntity user, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              const Color(0xFF9C27B0).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'নতুন',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
        value: user.name,
        onTap: () => context.push('/profile-edit'),
        showEdit: true,
      ),
      _buildInfoTile(
        icon: Icons.phone_rounded,
        title: 'ফোন নম্বর',
        subtitle: user.phoneNumber,
        value: user.phoneNumber,
        trailing: _buildVerifiedBadge(),
      ),
      if (user.email != null && user.email!.isNotEmpty)
        _buildInfoTile(
          icon: Icons.email_rounded,
          title: 'ইমেইল',
          subtitle: user.email!,
          value: user.email!,
          onTap: () => context.push('/profile-edit'),
          showEdit: true,
        ),
      _buildInfoTile(
        icon: Icons.location_on_rounded,
        title: 'ঠিকানা',
        subtitle: user.address ?? 'ঠিকানা যোগ করুন',
        value: user.address ?? 'অনির্ধারিত',
        onTap: () => context.push('/profile-edit'),
        showEdit: true,
      ),
      _buildInfoTile(
        icon: Icons.cake_rounded,
        title: 'জন্ম তারিখ',
        subtitle: user.dateOfBirth != null 
            ? '${user.dateOfBirth!.day}-${user.dateOfBirth!.month}-${user.dateOfBirth!.year}'
            : 'যোগ করুন',
        value: user.dateOfBirth?.toString() ?? 'অনির্ধারিত',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.grey.shade700, size: 20),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (showEdit && onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 16,
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'লগআউট',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.red.shade300,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'যাচাইকৃত',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: List.generate(6, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildQuickActions(BuildContext context, AuthState state) {
    if (state is! Authenticated) return null;

    return Wrap(
      spacing: 12,
      direction: Axis.vertical,
      children: [
        FloatingActionButton.small(
          onPressed: () => _showQuickSettings(context),
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.settings_rounded),
        ),
        FloatingActionButton.small(
          onPressed: () => _scrollToTop(),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.arrow_upward_rounded),
        ),
      ],
    );
  }

  // Navigation and Action Handlers
  void _handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.push('/');
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Feature Methods (Stubs for real implementation)
  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('নোটিফিকেশন প্যানেল (শীঘ্রই আসছে)')),
    );
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
        _shareProfile(context, (context.read<AuthBloc>().state as Authenticated).user);
        break;
    }
  }

  void _showQRCode(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('আপনার প্রোফাইল কোড'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_rounded, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('এই কিউআর কোড স্ক্যান করে আপনার প্রোফাইল দেখুন'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  void _shareProfile(BuildContext context, UserEntity user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('প্রোফাইল শেয়ার লিঙ্ক কপি করা হয়েছে'),
        action: SnackBarAction(
          label: 'আরও দেখুন',
          onPressed: () {},
        ),
      ),
    );
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
      builder: (context) => AlertDialog(
        title: const Text('কপিরাইট'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('© ২০২৫ স্মার্টশেবা'),
            SizedBox(height: 8),
            Text('সমস্ত অধিকার সংরক্ষিত।'),
            SizedBox(height: 8),
            Text('সংস্করণ: 1.0.0 (বিল্ড ২০২৫.০১.০১)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Column(
          children: [
            // Quick settings content would go here
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('লগআউট করবেন?'),
          ],
        ),
        content: const Text('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান? আপনি পুনরায় লগইন করতে আপনার ফোন নম্বর ব্যবহার করবেন।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
  }
}