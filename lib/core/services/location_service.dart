import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check & Request Permissions
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

  // Get Current Location
  Future<Position> getCurrentLocation() async {
    final permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions denied');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),  // Timeout for perf
    );
  }

  // Generate Static Map URL (Google Static Maps API – Get free key from console.cloud.google.com)
  String getStaticMapUrl(double lat, double lng, {String? markerLabel}) {
    const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';  // Secure in env vars for prod
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

  // Fetch Map Image (for caching/display)
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