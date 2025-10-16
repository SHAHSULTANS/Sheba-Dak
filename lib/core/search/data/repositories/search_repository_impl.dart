import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/dummy_data.dart';
import '../../../../core/location/domain/entities/location_entity.dart';
import '../../../../core/services/location_service.dart';
import '../services/fuzzy_search_service.dart';

class SearchRepositoryImpl implements SearchRepository {
  final LocationService locationService;

  SearchRepositoryImpl({required this.locationService});

  @override
  Future<Either<Failure, SearchResultEntity>> searchServicesAndProviders(
    String query, {
    LocationEntity? userLocation,
    bool nearbyFilterEnabled = false,
    double maxDistance = 50.0,
  }) async {
    try {
      if (query.isEmpty) {
        return Right(SearchResultEntity(
          categories: [],
          services: [],
          providers: [],
          totalResults: 0,
        ));
      }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      final allCategories = DummyData.getServiceCategories();
      final allServices = DummyData.getServices('');
      final allProviders = DummyData.getProviders();

      // Fuzzy search in categories
      final matchedCategories = allCategories.where((category) {
        return FuzzySearchService.isFuzzyMatch(category.name, query) ||
            FuzzySearchService.isFuzzyMatch(category.description, query);
      }).toList();

      // Fuzzy search in services
      final matchedServices = allServices.where((service) {
        return FuzzySearchService.isFuzzyMatch(service.name, query) ||
            FuzzySearchService.isFuzzyMatch(service.description, query);
      }).toList();

      // Fuzzy search in providers with proximity filtering
      final matchedProviders = allProviders.where((provider) {
        final matchesQuery = FuzzySearchService.isFuzzyMatch(provider.name, query) ||
            FuzzySearchService.isFuzzyMatch(provider.description, query) ||
            provider.services.any((service) =>
                FuzzySearchService.isFuzzyMatch(service, query));
        if (!matchesQuery) return false;

        if (nearbyFilterEnabled && userLocation != null && provider.businessLocation != null) {
          final providerLocation = LocationEntity(
            latitude: provider.businessLocation!.latitude,
            longitude: provider.businessLocation!.longitude,
          );

          final distance = LocationService.calculateDistance(userLocation, providerLocation);
          return distance <= maxDistance;
        }
        return true;
      }).toList();

      final results = SearchResultEntity(
        categories: matchedCategories,
        services: matchedServices,
        providers: matchedProviders,
        totalResults: matchedCategories.length + matchedServices.length + matchedProviders.length,
      );

      // Cache search query
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('search_$query', DateTime.now().toIso8601String());

      return Right(results);
    } catch (e) {
      return Left(SearchFailure('Search failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSearchSuggestions(String query) async {
    try {
      if (query.isEmpty) {
        return const Right([]);
      }

      final allCategories = DummyData.getServiceCategories();
      final allProviders = DummyData.getProviders();
      final allServices = DummyData.getServices('');

      final suggestions = <String>{};

      // Add category names
      for (final category in allCategories) {
        if (FuzzySearchService.isFuzzyMatch(category.name, query, threshold: 0.3)) {
          suggestions.add(category.name);
        }
      }

      // Add provider names
      for (final provider in allProviders) {
        if (FuzzySearchService.isFuzzyMatch(provider.name, query, threshold: 0.3)) {
          suggestions.add(provider.name);
        }
      }

      // Add service names
      for (final service in allServices) {
        if (FuzzySearchService.isFuzzyMatch(service.name, query, threshold: 0.3)) {
          suggestions.add(service.name);
        }
      }

      // Add common services as fallback
      final commonServices = ['প্লাম্বিং', 'ইলেকট্রিশিয়ান', 'ক্লিনিং', 'এসি সার্ভিস', 'পেইন্টিং'];
      for (final service in commonServices) {
        if (FuzzySearchService.isFuzzyMatch(service, query, threshold: 0.3)) {
          suggestions.add(service);
        }
      }

      return Right(suggestions.take(5).toList());
    } catch (e) {
      return Left(SearchFailure('Suggestions failed: $e'));
    }
  }
}
