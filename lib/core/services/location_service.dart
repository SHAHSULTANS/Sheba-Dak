import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../location/domain/entities/location_entity.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ========== PERMISSION METHODS ==========

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

  // ========== GEOCODING METHODS ==========

  // 🔹 Get Address from Position (Geocoding)
  static Future<String> getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isEmpty) {
        return 'ঠিকানা পাওয়া যায়নি';
      }
      
      final placemark = placemarks.first;
      
      // Build address string in Bengali format
      final addressParts = [
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ].where((part) => part != null && part.isNotEmpty).toList();
      
      return addressParts.isNotEmpty 
          ? addressParts.join(', ')
          : '${placemark.postalCode ?? ''}, ${placemark.country ?? 'বাংলাদেশ'}';
          
    } catch (e) {
      print('Geocoding error: $e');
      return 'ঠিকানা লোড করতে সমস্যা';
    }
  }

  // 🔹 Get Address from LocationEntity
  static Future<String> getAddressFromLocationEntity(LocationEntity location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isEmpty) {
        return 'ঠিকানা পাওয়া যায়নি';
      }
      
      final placemark = placemarks.first;
      
      // Bengali formatted address
      final addressParts = [
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ].where((part) => part != null && part.isNotEmpty).toList();
      
      return addressParts.isNotEmpty 
          ? addressParts.join(', ')
          : '${placemark.postalCode ?? ''}, ${placemark.country ?? 'বাংলাদেশ'}';
          
    } catch (e) {
      print('Geocoding error: $e');
      return 'ঠিকানা লোড করতে সমস্যা';
    }
  }

  // 🔹 Get Bengali Formatted Address
  static Future<String> getBengaliFormattedAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isEmpty) {
        return 'ঠিকানা পাওয়া যায়নি';
      }
      
      final placemark = placemarks.first;
      
      // Custom Bengali address formatting
      final addressComponents = <String>[];
      
      if (placemark.street != null && placemark.street!.isNotEmpty) {
        addressComponents.add(placemark.street!);
      }
      
      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        addressComponents.add(placemark.subLocality!);
      }
      
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        addressComponents.add(placemark.locality!);
      }
      
      if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
        addressComponents.add(placemark.subAdministrativeArea!);
      }
      
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
        addressComponents.add(placemark.administrativeArea!);
      }
      
      return addressComponents.isNotEmpty 
          ? addressComponents.join(', ')
          : '${placemark.postalCode ?? ''}, ${placemark.country ?? 'বাংলাদেশ'}';
          
    } catch (e) {
      print('Bengali address formatting error: $e');
      return 'ঠিকানা ফরম্যাট করতে সমস্যা';
    }
  }

  // 🔹 Get Coordinates from Address (Reverse Geocoding)
  static Future<LocationEntity?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      
      if (locations.isEmpty) {
        return null;
      }
      
      final location = locations.first;
      return LocationEntity(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  // ========== COMPREHENSIVE LOCATION METHODS ==========

  // 🔹 Get Current Location with Address
  static Future<Map<String, dynamic>> getCurrentLocationWithAddress() async {
    try {
      final position = await getCurrentPosition();
      final address = await getAddressFromPosition(position);
      
      return {
        'position': position,
        'address': address,
        'locationEntity': LocationEntity(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      };
    } catch (e) {
      throw Exception('লোকেশন এবং ঠিকানা লোড করতে সমস্যা: $e');
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

  // ========== DISTANCE CALCULATION METHODS ==========

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

  // 🔹 Calculate Distance between two Positions
  static double calculateDistanceBetweenPositions(Position start, Position end) {
    const earthRadius = 6371.0;

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

  // 🔹 Calculate Distance between two LatLng points
  static double calculateDistanceBetweenLatLng(LatLng start, LatLng end) {
    const earthRadius = 6371.0;

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

  // ========== CONVERSION METHODS ==========

  // 🔹 Convert LatLng to LocationEntity
  static LocationEntity latLngToLocationEntity(LatLng latLng) {
    return LocationEntity(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }

  // 🔹 Convert Position to LocationEntity
  static LocationEntity positionToLocationEntity(Position position) {
    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // 🔹 Convert LocationEntity to LatLng
  static LatLng locationEntityToLatLng(LocationEntity location) {
    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  // ========== MAP SERVICES ==========

  // 🔹 Generate Static Map URL
  static String getStaticMapUrl(double lat, double lng, {String? markerLabel, int zoom = 15}) {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // ⚠️ Replace in production
    final baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    final params = {
      'center': '$lat,$lng',
      'zoom': zoom.toString(),
      'size': '400x300',
      'maptype': 'roadmap',
      'key': apiKey,
      if (markerLabel != null) 'markers': 'label:$markerLabel|$lat,$lng',
    };
    return '$baseUrl?${Uri(queryParameters: params).query}';
  }

  // 🔹 Fetch Map Image (for caching/display)
  static Future<Uint8List> fetchStaticMap(double lat, double lng) async {
    final url = getStaticMapUrl(lat, lng);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load map: ${response.statusCode}');
    }
  }

  // ========== UTILITY METHODS ==========

  // 🔹 Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // 🔹 Get last known position (cached)
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  // 🔹 Check if two locations are within radius
  static bool isWithinRadius({
    required LocationEntity center,
    required LocationEntity target,
    required double radiusKm,
  }) {
    final distance = calculateDistance(center, target);
    return distance <= radiusKm;
  }

  // 🔹 Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} মিটার';
    } else {
      return '${distanceKm.toStringAsFixed(1)} কিমি';
    }
  }

  // 🔹 Get approximate travel time (simplified)
  static String getApproximateTravelTime(double distanceKm) {
    // Average speed: 20 km/h in city traffic
    final hours = distanceKm / 20;
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes মিনিট';
    } else {
      return '${hours.toStringAsFixed(1)} ঘন্টা';
    }
  }
}