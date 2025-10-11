class LocationFailure {
  final String message;
  final LocationErrorType type;

  LocationFailure(this.message, this.type);
}

enum LocationErrorType {
  permissionDenied,
  serviceDisabled,
  networkError,
  unknown,
}