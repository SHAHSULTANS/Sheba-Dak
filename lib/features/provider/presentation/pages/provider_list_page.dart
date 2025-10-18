import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/provider/domain/entities/service_provider.dart';
import 'dart:math' as math;

// Add missing color definitions if not already present
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color accent = Color(0xFF00E676);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFE8EAF6);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color rating = Color(0xFFFFA000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ProviderListPage extends StatefulWidget {
  const ProviderListPage({super.key});

  @override
  State<ProviderListPage> createState() => _ProviderListPageState();
}

class _ProviderListPageState extends State<ProviderListPage> {
  LatLng? _userLocation;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  bool _showNearbyOnly = false;
  double _searchRadius = 15.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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
        _userLocation = DummyData.dhanmondi;
        _currentAddress = 'ঢাকা, বাংলাদেশ';
      });
    }
  }

  List<ServiceProvider> _getFilteredProviders() {
    final allProviders = DummyData.getProviders();
    if (!_showNearbyOnly || _userLocation == null) return allProviders;
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
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    final providers = _getFilteredProviders();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.grey100,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildLocationFilterCard(providers),
            Expanded(
              child: providers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        final distance = _userLocation != null &&
                                provider.businessLocation != null
                            ? _calculateDistance(
                                _userLocation!, provider.businessLocation!)
                            : null;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
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
                                    // Avatar
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          child: Text(
                                            provider.name.isNotEmpty ? provider.name[0] : '?',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        if (provider.isOnline)
                                          Positioned(
                                            bottom: -2,
                                            right: -2,
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

                                    // Info section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Name & verified badge (on separate lines)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                provider.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (provider.isVerified)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Container(
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
                                                ),
                                            ],
                                          ),

                                          const SizedBox(height: 6),

                                          // Description
                                          Text(
                                            provider.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                            ),
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

                                    // Ratings + radius
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ...List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                starIndex < provider.rating.floor()
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: AppColors.rating,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${provider.rating.toStringAsFixed(1)})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (provider.serviceRadius > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              '${provider.serviceRadius.toStringAsFixed(0)} কিমি',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textTertiary,
                                              ),
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
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Logo with neon accent (2025 futuristic)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,  // Updated gradient
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.person_search,
                color: Colors.white,
                size: 20,
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
                    'প্রোভাইডার তালিকা',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${_getFilteredProviders().length}টি প্রোভাইডার',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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

  Widget _buildLocationFilterCard(List<ServiceProvider> providers) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                          _showNearbyOnly ? 'শুধুমাত্র ${_searchRadius.toStringAsFixed(0)}কিমি এর মধ্যে' : 'সব এলাকা থেকে',
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
                    activeColor: AppColors.accent,
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
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'কোন সার্ভিস প্রোভাইডার পাওয়া যায়নি',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
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
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}