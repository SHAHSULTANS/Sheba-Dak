import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/location_repository.dart';

abstract class LocationDataSource {
  Future<LocationPermissionStatus> checkPermission();
  Future<LocationPermissionStatus> requestPermission();
  Future<LocationEntity> getCurrentPosition();
  Future<AddressEntity> reverseGeocode(LocationEntity location);
  Future<List<AddressEntity>> searchAddress(String query);
  Stream<LocationEntity> getPositionStream();
}

class LocationDataSourceImpl implements LocationDataSource {
  final GeolocatorPlatform _geolocator;
  final LocationSettings _locationSettings;

  LocationDataSourceImpl({
    GeolocatorPlatform? geolocator,
    LocationSettings? locationSettings,
  })  : _geolocator = geolocator ?? GeolocatorPlatform.instance,
        _locationSettings = locationSettings ?? const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        );

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await _geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await _geolocator.requestPermission();
    return _mapPermission(permission);
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  @override
  Future<LocationEntity> getCurrentPosition() async {
    try {
      final position = await _geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      
      return LocationEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
      );
    } catch (e) {
      throw LocationFailure(
        'Failed to get current position: $e',
        LocationErrorType.unknown,
      );
    }
  }

  @override
  Future<AddressEntity> reverseGeocode(LocationEntity location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        throw LocationFailure(
          'No address found for location',
          LocationErrorType.unknown,
        );
      }

      final placemark = placemarks.first;
      
      return AddressEntity(
        street: _buildStreet(placemark),
        locality: placemark.locality,
        subLocality: placemark.subLocality,
        administrativeArea: placemark.administrativeArea,
        postalCode: placemark.postalCode,
        country: placemark.country,
        countryCode: placemark.isoCountryCode,
        formattedAddress: _buildFormattedAddress(placemark),
        location: location,
      );
    } catch (e) {
      throw LocationFailure(
        'Reverse geocoding failed: $e',
        LocationErrorType.unknown,
      );
    }
  }

  String _buildStreet(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      parts.add(placemark.thoroughfare!);
    }
    return parts.join(', ');
  }

  String _buildFormattedAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      parts.add(placemark.postalCode!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  @override
  Future<List<AddressEntity>> searchAddress(String query) async {
    try {
      final locations = await locationFromAddress(query);
      
      return await Future.wait(
        locations.map((location) async {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          final placemark = placemarks.firstOrNull;
          final locationEntity = LocationEntity(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: location.timestamp,
          );
          
          return AddressEntity(
            street: placemark?.street,
            locality: placemark?.locality,
            subLocality: placemark?.subLocality,
            administrativeArea: placemark?.administrativeArea,
            postalCode: placemark?.postalCode,
            country: placemark?.country,
            countryCode: placemark?.isoCountryCode,
            formattedAddress: placemark != null 
                ? _buildFormattedAddress(placemark)
                : query,
            location: locationEntity,
          );
        }),
      );
    } catch (e) {
      throw LocationFailure(
        'Address search failed: $e',
        LocationErrorType.unknown,
      );
    }
  }

  @override
  Stream<LocationEntity> getPositionStream() {
    return _geolocator.getPositionStream(locationSettings: _locationSettings)
        .map((position) => LocationEntity(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          timestamp: position.timestamp,
        ));
  }
}