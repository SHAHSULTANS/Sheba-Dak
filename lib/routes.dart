import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- AUTH IMPORTS (FIXED: All state classes are in auth_bloc.dart) ---
import 'features/auth/presentation/bloc/auth_bloc.dart'; // This now provides AuthBloc AND Authenticated

// --- Auth Page Imports (Existing) ---
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_verification_page.dart';
import 'features/auth/presentation/pages/profile_creation_page.dart';
import 'features/auth/presentation/pages/profile_edit_page.dart';

// --- Home/Service Imports (Updated) ---
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/service_list_page.dart'; 
import 'features/home/presentation/pages/service_detail_page.dart' hide Authenticated, AuthBloc; 

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => OtpVerificationPage(
        phoneNumber: state.uri.queryParameters['phone'] ?? '',
      ),
    ),
    GoRoute(
      path: '/profile-creation',
      builder: (context, state) => const ProfileCreationPage(),
    ),
    GoRoute(
      path: '/profile-edit',
      builder: (context, state) => const ProfileEditPage(),
    ),

    // --- SERVICE DISCOVERY ROUTES ---
    GoRoute(
      path: '/services/:categoryId',
      builder: (context, state) => ServiceListPage(
        categoryId: state.pathParameters['categoryId']!,
      ),
    ),
    GoRoute(
      path: '/service-detail/:serviceId',
      builder: (context, state) => ServiceDetailPage(
        id: state.pathParameters['serviceId']!,
      ),
    ),
    GoRoute(
      path: '/booking',
      builder: (context, state) => const Placeholder(child: Center(child: Text('Booking Page (Coming Week 5)'))),
    ),
  ],
  
  // --- REDIRECT LOGIC ---
  redirect: (context, state) {
    // AuthBloc and Authenticated are now correctly provided by the single import above.
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final isAuthenticated = authState is Authenticated;
    final targetPath = state.uri.path;

    if (!isAuthenticated) {
      if (['/login', '/register', '/otp', '/services', '/service-detail'].any(targetPath.startsWith)) {
        // Allow unauthenticated users to view login/register/otp and service pages
        return null;
      }
      return '/login';
    } 
    
    // Redirect authenticated users away from login/register
    if (isAuthenticated && ['/login', '/register'].contains(targetPath)) {
        return '/';
    }
    
    return null;
  },
  
  // --- ERROR HANDLER ---
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);