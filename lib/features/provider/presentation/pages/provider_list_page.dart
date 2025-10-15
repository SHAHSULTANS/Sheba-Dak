import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/provider/domain/entities/service_provider.dart';
import 'dart:math' as math;

class ProviderListPage extends StatefulWidget {
  const ProviderListPage({super.key});

  @override
  State<ProviderListPage> createState() => _ProviderListPageState();
}

class _ProviderListPageState extends State<ProviderListPage> {
  LatLng? _userLocation;
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
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _isLoadingLocation = false;
        _userLocation = DummyData.dhanmondi; // Fallback to Dhaka center
      });
    }
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

  List<ServiceProvider> _getFilteredProviders() {
    final allProviders = DummyData.getProviders();

    if (!_showNearbyOnly || _userLocation == null) {
      return allProviders;
    }

    return DummyData.getNearbyProviders(_userLocation!, maxDistance: _searchRadius);
  }

  @override
  Widget build(BuildContext context) {
    final providers = _getFilteredProviders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোভাইডার তালিকা', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            onPressed: _getUserLocation,
            tooltip: 'লোকেশন আপডেট',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLocationFilterCard(providers),
          Expanded(
            child: providers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: providers.length,
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      final distance = _userLocation != null &&
                              provider.businessLocation != null
                          ? _calculateDistance(
                              _userLocation!, provider.businessLocation!)
                          : null;

                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              provider.name.isNotEmpty
                                  ? provider.name[0]
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            provider.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${provider.rating.toStringAsFixed(1)} রেটিং',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (provider.isVerified) ...[
                                    const SizedBox(width: 12),
                                    const Tooltip(
                                      message: 'প্রমাণিত প্রোভাইডার',
                                      child: Icon(Icons.verified,
                                          color: Colors.green, size: 18),
                                    ),
                                  ],
                                ],
                              ),
                              if (distance != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'দূরত্ব: ${distance.toStringAsFixed(1)} কিমি',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            context.push('/provider-detail/${provider.id}');
                          },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userLocation != null
                        ? 'আপনার বর্তমান লোকেশন'
                        : 'লোকেশন লোড হচ্ছে...',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'কাছাকাছি সার্ভিস দেখুন',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Switch(
                  value: _showNearbyOnly,
                  onChanged: (value) {
                    setState(() {
                      _showNearbyOnly = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            if (_showNearbyOnly) ...[
              const SizedBox(height: 12),
              Text(
                'সার্চ রেডিয়াস: ${_searchRadius.toStringAsFixed(0)} কিমি',
                style: const TextStyle(fontSize: 14),
              ),
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
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Colors.grey[300],
              ),
            ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'কোন সার্ভিস প্রোভাইডার পাওয়া যায়নি',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
    );
  }
}