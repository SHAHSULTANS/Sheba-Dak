import 'package:equatable/equatable.dart';
import 'location_entity.dart';

class AddressEntity extends Equatable {
  final String? street;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;
  final String? postalCode;
  final String? country;
  final String? countryCode;
  final String formattedAddress;
  final LocationEntity location;

  const AddressEntity({
    this.street,
    this.locality,
    this.subLocality,
    this.administrativeArea,
    this.postalCode,
    this.country,
    this.countryCode,
    required this.formattedAddress,
    required this.location,
  });

  factory AddressEntity.fromMap(Map<String, dynamic> map) {
    return AddressEntity(
      street: map['street'] as String?,
      locality: map['locality'] as String?,
      subLocality: map['subLocality'] as String?,
      administrativeArea: map['administrativeArea'] as String?,
      postalCode: map['postalCode'] as String?,
      country: map['country'] as String?,
      countryCode: map['countryCode'] as String?,
      formattedAddress: map['formattedAddress'] as String,
      location: LocationEntity.fromMap(map['location'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'locality': locality,
      'subLocality': subLocality,
      'administrativeArea': administrativeArea,
      'postalCode': postalCode,
      'country': country,
      'countryCode': countryCode,
      'formattedAddress': formattedAddress,
      'location': location.toMap(),
    };
  }

  String get shortAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    return parts.join(', ');
  }

  String get cityArea {
    final parts = <String>[];
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (administrativeArea != null && administrativeArea!.isNotEmpty) {
      parts.add(administrativeArea!);
    }
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        street,
        locality,
        subLocality,
        administrativeArea,
        postalCode,
        country,
        countryCode,
        formattedAddress,
        location,
      ];

  AddressEntity copyWith({
    String? street,
    String? locality,
    String? subLocality,
    String? administrativeArea,
    String? postalCode,
    String? country,
    String? countryCode,
    String? formattedAddress,
    LocationEntity? location,
  }) {
    return AddressEntity(
      street: street ?? this.street,
      locality: locality ?? this.locality,
      subLocality: subLocality ?? this.subLocality,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      location: location ?? this.location,
    );
  }
}