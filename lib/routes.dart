import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- AUTH IMPORTS ---
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';

// --- Auth Page Imports ---
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_verification_page.dart';
import 'features/auth/presentation/pages/profile_creation_page.dart';
import 'features/auth/presentation/pages/profile_edit_page.dart';

// --- Home/Service Imports ---
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/service_list_page.dart';
import 'features/home/presentation/pages/service_detail_page.dart';

// --- PROVIDER IMPORTS ---
import 'features/provider/presentation/pages/provider_list_page.dart';
import 'features/provider/presentation/pages/provider_detail_page.dart';
import 'features/provider/presentation/pages/provider_dashboard_page.dart';
import 'features/provider/presentation/pages/contact_provider_page.dart';
import 'features/provider/presentation/pages/provider_registration_page.dart';

// ✅ NEW: Booking Page Import
import 'features/booking/presentation/pages/book_service_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- CORE HOME ROUTE ---
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    // --- AUTH ROUTES ---
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final phoneNumber = state.uri.queryParameters['phoneNumber'];
        return OtpVerificationPage(
          phoneNumber: phoneNumber.toString(),
        );
      },
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

    // ✅ NEW BOOKING ROUTE (Dynamic Parameters)
    GoRoute(
      path: '/booking/:providerId/:serviceCategory/:price',
      builder: (context, state) {
        final providerId = state.pathParameters['providerId']!;
        final serviceCategory = state.pathParameters['serviceCategory']!;
        final priceString = state.pathParameters['price']!;
        final price = double.tryParse(priceString) ?? 0.0;

        return BookServicePage(
          providerId: providerId,
          serviceCategory: serviceCategory,
          price: price,
        );
      },
    ),

    // --- PROVIDER MANAGEMENT ROUTES ---
    GoRoute(
      path: '/providers',
      builder: (context, state) => const ProviderListPage(),
    ),
    GoRoute(
      path: '/provider-detail/:id',
      builder: (context, state) =>
          ProviderDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/provider-dashboard',
      builder: (context, state) => const ProviderDashboardPage(),
    ),
    GoRoute(
      path: '/contact-provider/:id',
      builder: (context, state) => const ContactProviderPage(),
    ),

    // ✅ NEW: PROVIDER REGISTRATION ROUTE
    GoRoute(
      path: '/provider-registration',
      builder: (context, state) => const ProviderRegistrationPage(),
    ),
  ],

  // --- REDIRECT LOGIC ---
  redirect: (context, state) {
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final isAuthenticated = authState is Authenticated;
    final targetPath = state.uri.path;

    // Retrieve user role for RBAC check
    final userRole =
        isAuthenticated ? (authState as Authenticated).user.role : null;

    // A. UNAUTHENTICATED REDIRECTS
    if (!isAuthenticated) {
      // Allow public pages
      const publicPaths = [
        '/login',
        '/register',
        '/otp-verification',
        '/services',
        '/service-detail',
        '/providers',
        '/provider-detail',
        '/provider-registration',
      ];
      if (publicPaths.any(targetPath.startsWith)) {
        return null;
      }
      return '/login'; // Redirect private paths to login
    }

    // B. AUTHENTICATED REDIRECTS (Block login/register pages)
    if (isAuthenticated &&
        ['/login', '/register', '/otp-verification', '/profile-creation']
            .contains(targetPath)) {
      return '/';
    }

    // C. RBAC: PROVIDER DASHBOARD ACCESS CONTROL
    if (targetPath == '/provider-dashboard') {
      if (userRole == Role.provider) {
        return null;
      } else {
        return '/';
      }
    }

    // D. RBAC: Prevent providers/admin from registration page
    if (targetPath == '/provider-registration') {
      if (userRole == Role.provider || userRole == Role.admin) {
        return '/';
      }
    }

    return null;
  },

  // --- ERROR HANDLER ---
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);
