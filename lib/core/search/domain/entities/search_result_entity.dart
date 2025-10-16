import 'package:equatable/equatable.dart';
import 'package:smartsheba/features/home/domain/entities/service.dart';
import 'package:smartsheba/features/home/domain/entities/service_category.dart';
import 'package:smartsheba/features/provider/domain/entities/service_provider.dart';

class SearchResultEntity extends Equatable {
  final List<ServiceCategory> categories;
  final List<Service> services;
  final List<ServiceProvider> providers;
  final int totalResults;

  const SearchResultEntity({
    required this.categories,
    required this.services,
    required this.providers,
    this.totalResults = 0,
  });

  @override
  List<Object?> get props => [categories, services, providers, totalResults];
}