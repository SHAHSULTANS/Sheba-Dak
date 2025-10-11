// lib/core/location/domain/usecases/get_current_location.dart
import 'package:dartz/dartz.dart';
import 'package:smartsheba/core/location/data/repositories/location_repository_impl.dart';
import 'package:smartsheba/core/location/domain/entities/location_entity.dart';
import 'package:smartsheba/core/location/domain/repositories/location_repository.dart';

import '../../location_failure.dart' hide LocationFailure;

class GetCurrentLocation {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  Future<Either<LocationFailure, LocationEntity>> call() async {
    return await repository.getCurrentLocation();
  }
}

// // Similar for other usecases: RequestPermission, ReverseGeocode, etc.