import 'package:dartz/dartz.dart';
import 'package:smartsheba/core/location/domain/entities/location_entity.dart';
import '../entities/search_result_entity.dart';
import '../../../../core/error/failure.dart';

abstract class SearchRepository {
  Future<Either<Failure, SearchResultEntity>> searchServicesAndProviders(
    String query, {
    LocationEntity? userLocation,
    bool nearbyFilterEnabled = false,
    double maxDistance = 50.0,
  });
  Future<Either<Failure, List<String>>> getSearchSuggestions(String query);
}