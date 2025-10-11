import 'package:get_it/get_it.dart';
import 'data/datasources/location_datasource.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'presentation/bloc/location_bloc.dart';

final getIt = GetIt.instance;

void setupLocationDependencies() {
  // DataSource
  getIt.registerLazySingleton<LocationDataSource>(
    () => LocationDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(getIt<LocationDataSource>()),
  );

  // BLoC - Factory to create new instance for each use
  getIt.registerFactory<LocationBloc>(
    () => LocationBloc(locationRepository: getIt<LocationRepository>()),
  );
}