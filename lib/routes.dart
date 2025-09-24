import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_verification_page.dart';
import 'features/auth/presentation/pages/profile_creation_page.dart';
import 'features/auth/presentation/pages/profile_edit_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
// Note: You must create this file for the application to compile.
import 'features/home/presentation/pages/service_detail_page.dart'; 

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
    // --- New Route for Service Category Taps ---
    GoRoute(
      path: '/services/:id',
      builder: (context, state) => ServiceDetailPage(id: state.pathParameters['id']!),
    ),
  ],
  redirect: (context, state) {
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final isAuthenticated = authState is Authenticated;
    final targetPath = state.uri.path;

    if (!isAuthenticated) {
      if (['/login', '/register', '/otp'].contains(targetPath)) {
        return null;
      }
      return '/login';
    } else {
      if (['/login', '/register'].contains(targetPath)) {
        return '/';
      }
      return null;
    }
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);