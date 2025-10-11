import 'package:dartz/dartz.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _dataSource;
  final _cache = <String, dynamic>{};

  LocationRepositoryImpl(this._dataSource);

  @override
  Future<Either<LocationFailure, LocationPermissionStatus>> requestPermission() async {
    try {
      final status = await _dataSource.requestPermission();
      return Right(status);
    } on LocationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(LocationFailure(
        'Permission request failed: $e',
        LocationErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<LocationFailure, LocationPermissionStatus>> checkPermissionStatus() async {
    try {
      final status = await _dataSource.checkPermission();
      return Right(status);
    } on LocationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(LocationFailure(
        'Permission check failed: $e',
        LocationErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<LocationFailure, LocationEntity>> getCurrentLocation() async {
    try {
      final location = await _dataSource.getCurrentPosition();
      _cache['current_location'] = location;
      return Right(location);
    } on LocationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(LocationFailure(
        'Failed to get current location: $e',
        LocationErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<LocationFailure, AddressEntity>> reverseGeocode(LocationEntity location) async {
    final cacheKey = 'reverse_geocode_${location.latitude}_${location.longitude}';

    if (_cache.containsKey(cacheKey)) {
      return Right(_cache[cacheKey] as AddressEntity);
    }

    try {
      final address = await _dataSource.reverseGeocode(location);
      _cache[cacheKey] = address;
      return Right(address);
    } on LocationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(LocationFailure(
        'Reverse geocoding failed: $e',
        LocationErrorType.unknown,
      ));
    }
  }

  @override
  Future<Either<LocationFailure, List<AddressEntity>>> searchAddress(String query) async {
    final cacheKey = 'address_search_$query';

    if (_cache.containsKey(cacheKey)) {
      return Right(_cache[cacheKey] as List<AddressEntity>);
    }

    try {
      final addresses = await _dataSource.searchAddress(query);
      _cache[cacheKey] = addresses;
      return Right(addresses);
    } on LocationFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(LocationFailure(
        'Address search failed: $e',
        LocationErrorType.unknown,
      ));
    }
  }

  @override
  Stream<LocationEntity> getLocationStream() {
    return _dataSource.getPositionStream();
  }

  @override
  Future<void> stopLocationUpdates() async {
    // No-op: stream closes when listeners are removed
  }

  void clearCache() {
    _cache.clear();
  }
}
