// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator.pop
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Placeholder/Assumed Imports ---
import 'package:smartsheba/core/search/data/repositories/search_repository_impl.dart';
import 'package:smartsheba/core/search/domain/repositories/search_repository.dart';
import 'package:smartsheba/core/search/presentation/bloc/search_bloc.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/routes.dart'; // Assumed to contain 'appRouter' (GoRouter config)

// 🟢 ADD THIS GLOBAL KEY (SAME AS IN routes.dart)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

  // Other Blocs
  getIt.registerFactory(() => AuthBloc());
  getIt.registerFactory(() => BookingBloc());
}

// ----------------------
// Main Function
// ----------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show a simple loading screen (optional)
  runApp(const SplashScreen()); 

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Setup DI
  setupDependencies();

  // Once initialization is complete, replace the SplashScreen with MyApp
  runApp(MyApp(prefs: prefs));
}

// ----------------------
// SplashScreen
// ----------------------
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              // Use Bangla or English based on your app's language choice
              Text('অ্যাপ লোড হচ্ছে...'), 
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------
// MyApp (SIMPLIFIED - Remove PopScope)
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
      ],
      child: MaterialApp.router(
        title: 'SmartSheba',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        
        // SIMPLIFIED BUILDER - Remove the PopScope wrapper
        builder: (context, child) {
          // Deferred initialization (still a good pattern)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DummyData.initDummyBookings();
          });

          // Just return the child directly - PopScope is now in routes.dart
          return child!;
        },
      ),
    );
  }
}