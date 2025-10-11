import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../entities/address_entity.dart';

/// Represents the permission status returned by location APIs.
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
}

/// Represents the type of error that occurred during location operations.
enum LocationErrorType {
  permissionDenied,
  deniedForever,
  serviceDisabled,
  networkError,
  unknown,
}

/// Represents a failure in location-related operations.
class LocationFailure {
  final String message;
  final LocationErrorType type;

  LocationFailure(this.message, this.type);
}

/// Abstract repository interface for location-related operations.
abstract class LocationRepository {
  /// Requests location permission from the user.
  Future<Either<LocationFailure, LocationPermissionStatus>> requestPermission();

  /// Checks the current permission status (replaces isPermissionGranted).
  Future<Either<LocationFailure, LocationPermissionStatus>> checkPermissionStatus();

  /// Gets the current GPS location.
  Future<Either<LocationFailure, LocationEntity>> getCurrentLocation();

  /// Converts coordinates into a human-readable address.
  Future<Either<LocationFailure, AddressEntity>> reverseGeocode(LocationEntity location);

  /// Searches for addresses based on a query string.
  Future<Either<LocationFailure, List<AddressEntity>>> searchAddress(String query);

  /// Starts a stream of location updates.
  Stream<LocationEntity> getLocationStream();

  /// Stops location updates.
  Future<void> stopLocationUpdates();
}
