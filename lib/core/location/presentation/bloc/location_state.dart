// lib/core/location/presentation/bloc/location_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/location_repository.dart';

class LocationState extends Equatable {
  final LocationPermissionStatus? permissionStatus;
  final LocationEntity? currentLocation;
  final AddressEntity? selectedAddress; // Nullable field
  final List<AddressEntity> searchResults;
  final bool isLoading;
  final LocationFailure? error;
  final bool isTracking;

  const LocationState({
    this.permissionStatus,
    this.currentLocation,
    this.selectedAddress,
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.isTracking = false,
  });

  LocationState copyWith({
    LocationPermissionStatus? permissionStatus,
    LocationEntity? currentLocation,
    AddressEntity? selectedAddress,
    List<AddressEntity>? searchResults,
    bool? isLoading,
    LocationFailure? error,
    bool? isTracking,
    // ✅ FIX: Add explicit clearing flag for selectedAddress
    bool clearSelectedAddress = false, 
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      currentLocation: currentLocation ?? this.currentLocation,
      // ✅ FIX: Use clearing logic: if flag is true -> null, otherwise use new value or old value
      selectedAddress: clearSelectedAddress ? null : selectedAddress ?? this.selectedAddress, 
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error, 
      isTracking: isTracking ?? this.isTracking,
    );
  }

  bool get hasPermission => permissionStatus == LocationPermissionStatus.whileInUse ||
                           permissionStatus == LocationPermissionStatus.always;

  bool get isPermissionDeniedForever => 
      permissionStatus == LocationPermissionStatus.deniedForever;

  @override
  List<Object?> get props => [
        permissionStatus,
        currentLocation,
        selectedAddress,
        searchResults,
        isLoading,
        error,
        isTracking,
      ];
}