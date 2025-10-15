import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        throw Exception('Location permissions are permanently denied');
      }
    }
    return permission;
  }

  // 🔹 Get Current Location (Instance Method)
  Future<Position> getCurrentLocation() async {
    final permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions denied');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  // 🔹 Generate Static Map URL
  String getStaticMapUrl(double lat, double lng, {String? markerLabel}) {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // ⚠️ Use env vars in production
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





    static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('লোকেশন সার্ভিস একটিভেট করা নেই। দয়া করে আপনার ডিভাইসের লোকেশন সার্ভিস চালু করুন।');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('লোকেশন পারমিশন ডিনাই করা হয়েছে।');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('লোকেশন পারমিশন পার্মানেন্টলি ডিনাই করা হয়েছে। দয়া করে অ্যাপ সেটিংস থেকে পারমিশন দিন।');
    }

    // Get current position with timeout
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('লোকেশন ফেচ করতে সমস্যা: $e');
    }
  }

  static Future<double> calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return await Geolocator.distanceBetween(
      startLat, startLng, endLat, endLng,
    ) / 1000.0; // Convert to kilometers
  }

}

