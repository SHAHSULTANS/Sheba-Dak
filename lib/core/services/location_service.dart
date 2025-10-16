import 'dart:math';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../location/domain/entities/location_entity.dart'; // <-- import your entity

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // 🔹 Check & Request Permissions
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception('লোকেশন পারমিশন পার্মানেন্টলি ডিনাই করা হয়েছে।');
      }
    }
    return permission;
  }

  // 🔹 Get Current Location (Position)
  Future<Position> getCurrentLocation() async {
    final permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('লোকেশন পারমিশন ডিনাই করা হয়েছে।');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  // 🔹 Static method for safe call (for other layers)
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('লোকেশন সার্ভিস একটিভেট করা নেই।');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('লোকেশন পারমিশন ডিনাই করা হয়েছে।');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('লোকেশন পারমিশন পার্মানেন্টলি ডিনাই করা হয়েছে।');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('লোকেশন ফেচ করতে সমস্যা: $e');
    }
  }

  // 🔹 Get Current Location as LocationEntity
  Future<LocationEntity> getCurrentLocationEntity() async {
    final position = await getCurrentPosition();
    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // 🔹 Calculate Distance between two LocationEntities (Haversine)
  static double calculateDistance(LocationEntity start, LocationEntity end) {
    const earthRadius = 6371.0; // Earth radius in kilometers

    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;

  // 🔹 Convert LatLng to LocationEntity
  LocationEntity latLngToLocationEntity(LatLng latLng) {
    return LocationEntity(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }

  // 🔹 Generate Static Map URL
  String getStaticMapUrl(double lat, double lng, {String? markerLabel}) {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // ⚠️ Replace in production
    final baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    final params = {
      'center': '$lat,$lng',
      'zoom': '15',
      'size': '400x300',
      'maptype': 'roadmap',
      'key': apiKey,
      if (markerLabel != null) 'markers': 'label:$markerLabel|$lat,$lng',
    };
    return '$baseUrl?${Uri(queryParameters: params).query}';
  }

  // 🔹 Fetch Map Image (for caching/display)
  Future<Uint8List> fetchStaticMap(double lat, double lng) async {
    final url = getStaticMapUrl(lat, lng);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load map: ${response.statusCode}');
    }
  }
}
