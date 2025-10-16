import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsheba/core/search/data/repositories/search_repository_impl.dart';
import 'package:smartsheba/core/search/domain/repositories/search_repository.dart';
import 'package:smartsheba/core/search/presentation/bloc/search_bloc.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/routes.dart';

// ----------------------
// GetIt instance
// ----------------------
final getIt = GetIt.instance;

// ----------------------
// Dependency Injection
// ----------------------
void setupDependencies() {
  // Core Services
  getIt.registerLazySingleton(() => LocationService());

  // Search Dependencies
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(locationService: getIt<LocationService>()),
  );

  // Blocs
  getIt.registerFactory(() => SearchBloc(
        searchRepository: getIt<SearchRepository>(),
        locationService: getIt<LocationService>(),
      ));

  // Other Blocs (optional, can keep your old ones)
  getIt.registerFactory(() => AuthBloc());
  getIt.registerFactory(() => BookingBloc());
}

// ----------------------
// Main Function
// ----------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Setup DI
  setupDependencies();

  runApp(MyApp(prefs: prefs));
}

// ----------------------
// MyApp
// ----------------------
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<BookingBloc>()),
        BlocProvider(create: (_) => getIt<SearchBloc>()),
        // Add more providers here if needed
      ],
      child: MaterialApp.router(
        title: 'SmartSheba',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Deferred initialization
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DummyData.initDummyBookings();
          });
          return child!;
        },
      ),
    );
  }
}
