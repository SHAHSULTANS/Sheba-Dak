import 'dart:math';

import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime? timestamp;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.timestamp,
  });

  factory LocationEntity.fromMap(Map<String, dynamic> map) {
    return LocationEntity(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      accuracy: map['accuracy'] as double?,
      altitude: map['altitude'] as double?,
      speed: map['speed'] as double?,
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp?.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        timestamp,
      ];

  LocationEntity copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
  }) {
    return LocationEntity(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Helper method to calculate distance between two locations (in meters)
  double distanceTo(LocationEntity other) {
    const earthRadius = 6371000.0; // meters

    final lat1 = _toRadians(latitude);
    final lon1 = _toRadians(longitude);
    final lat2 = _toRadians(other.latitude);
    final lon2 = _toRadians(other.longitude);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}