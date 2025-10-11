import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsheba/core/location/domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _locationRepository;
  StreamSubscription<LocationEntity>? _locationSubscription;

  LocationBloc({required LocationRepository locationRepository})
      : _locationRepository = locationRepository,
        super(const LocationState()) {
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<CheckLocationPermission>(_onCheckLocationPermission);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<ReverseGeocodeLocation>(_onReverseGeocodeLocation);
    on<SearchAddress>(_onSearchAddress);
    on<SelectAddress>(_onSelectAddress);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<ClearLocationError>(_onClearError);

    // ✅ Automatically check permission on startup
    add(const CheckLocationPermission());
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _locationRepository.requestPermission();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure)),
      (status) => emit(state.copyWith(isLoading: false, permissionStatus: status)),
    );
  }

  Future<void> _onCheckLocationPermission(
    CheckLocationPermission event,
    Emitter<LocationState> emit,
  ) async {
    final result = await _locationRepository.checkPermissionStatus();

    result.fold(
      (failure) => emit(state.copyWith(error: failure)),
      (status) => emit(state.copyWith(permissionStatus: status)),
    );
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    // 🎯 FIX: Check permission status before attempting to fetch.
    if (!state.hasPermission) {
      final denialFailure = LocationFailure(
        'Location permission is required to fetch current position.',
        LocationErrorType.permissionDenied,
      );
      emit(state.copyWith(isLoading: false, error: denialFailure));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    final result = await _locationRepository.getCurrentLocation();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure)),
      (location) => emit(state.copyWith(isLoading: false, currentLocation: location)),
    );
  }

  Future<void> _onReverseGeocodeLocation(
    ReverseGeocodeLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _locationRepository.reverseGeocode(event.location);

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure)),
      (address) => emit(state.copyWith(isLoading: false, selectedAddress: address)),
    );
  }

  Future<void> _onSearchAddress(
    SearchAddress event,
    Emitter<LocationState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    final result = await _locationRepository.searchAddress(event.query);

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure, searchResults: [])),
      (addresses) => emit(state.copyWith(isLoading: false, searchResults: addresses)),
    );
  }

  void _onSelectAddress(
    SelectAddress event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(
      selectedAddress: event.address,
      clearSelectedAddress: event.address == null,
      searchResults: [],
    ));
  }

  void _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<LocationState> emit,
  ) {
    if (!state.hasPermission) return;

    _locationSubscription?.cancel();
    _locationSubscription = _locationRepository.getLocationStream().listen(
      (location) {
        add(ReverseGeocodeLocation(location));
      },
    );

    emit(state.copyWith(isTracking: true));
  }

  void _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<LocationState> emit,
  ) {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    emit(state.copyWith(isTracking: false));
  }

  void _onClearError(
    ClearLocationError event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
