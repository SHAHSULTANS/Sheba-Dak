// lib/features/provider/domain/entities/service_provider.dart
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceProvider extends Equatable {
  final String id;
  final String name;
  final double rating;
  final bool isVerified;
  final List<String> services;
  final String description;
  final LatLng? businessLocation;
  final double serviceRadius;
  final List<String> servedAreas;
  final bool isOnline;
  final DateTime? lastActive;

  const ServiceProvider({
    required this.id,
    required this.name,
    required this.rating,
    required this.isVerified,
    required this.services,
    required this.description,
    this.businessLocation,
    this.serviceRadius = 10.0,
    this.servedAreas = const [],
    this.isOnline = false,
    this.lastActive,
  });

  bool servesLocation(LatLng customerLocation) {
    if (businessLocation == null) return true;
    
    final distance = _calculateDistance(businessLocation!, customerLocation);
    return distance <= serviceRadius;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371.0;
    final lat1 = start.latitude * (pi / 180.0);
    final lon1 = start.longitude * (pi / 180.0);
    final lat2 = end.latitude * (pi / 180.0);
    final lon2 = end.longitude * (pi / 180.0);
    
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    if (json['business_location'] != null) {
      final loc = json['business_location'] as Map<String, dynamic>;
      location = LatLng(
        loc['lat'] as double,
        loc['lng'] as double,
      );
    }
    
    return ServiceProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      isVerified: json['is_verified'] as bool,
      services: (json['services'] as List).cast<String>(),
      description: json['description'] as String,
      businessLocation: location,
      serviceRadius: (json['service_radius'] as num).toDouble(),
      servedAreas: (json['served_areas'] as List).cast<String>(),
      isOnline: json['is_online'] as bool,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'is_verified': isVerified,
        'services': services,
        'description': description,
        'business_location': businessLocation != null
            ? {'lat': businessLocation!.latitude, 'lng': businessLocation!.longitude}
            : null,
        'service_radius': serviceRadius,
        'served_areas': servedAreas,
        'is_online': isOnline,
        'last_active': lastActive?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, rating, isVerified, services, description, businessLocation, serviceRadius, servedAreas, isOnline, lastActive];
}