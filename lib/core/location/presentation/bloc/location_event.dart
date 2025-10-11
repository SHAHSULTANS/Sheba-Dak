// lib/core/location/presentation/bloc/location_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/address_entity.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  // ✅ FIX: Change base class return type to List<Object?>
  List<Object?> get props => [];
}

class RequestLocationPermission extends LocationEvent {
  const RequestLocationPermission();
}

class CheckLocationPermission extends LocationEvent {
  const CheckLocationPermission();
}

class GetCurrentLocation extends LocationEvent {
  const GetCurrentLocation();
}

class ReverseGeocodeLocation extends LocationEvent {
  final LocationEntity location;
  const ReverseGeocodeLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class SearchAddress extends LocationEvent {
  final String query;
  const SearchAddress(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectAddress extends LocationEvent {
  // ✅ FIX: Make address nullable
  final AddressEntity? address; 
  const SelectAddress(this.address);

  @override
  List<Object?> get props => [address]; 
}

class StartLocationTracking extends LocationEvent {
  const StartLocationTracking();
}

class StopLocationTracking extends LocationEvent {
  const StopLocationTracking();
}

class ClearLocationError extends LocationEvent {
  const ClearLocationError();
}