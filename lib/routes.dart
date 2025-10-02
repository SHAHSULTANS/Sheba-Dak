import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- AUTH IMPORTS ---
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/pages/profile_veiw.dart';
import 'package:smartsheba/features/booking/presentation/pages/incoming_requests_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/provider_confirmed_booking.dart';

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

// --- Booking Page Imports ---
import 'features/booking/presentation/pages/book_service_page.dart';
import 'features/booking/presentation/pages/my_bookings_page.dart';

// --- Chat Page Imports ---
import 'features/chat/presentation/pages/chat_page.dart';

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
    GoRoute(
      path: '/profile-view',
      builder: (context, state) => const ProfileViewPage(),
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

    // --- BOOKING ROUTES ---
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
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const MyBookingsPage(),
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
    GoRoute(
      path: '/provider-registration',
      builder: (context, state) => const ProviderRegistrationPage(),
    ),

    // --- INCOMING REQUESTS ROUTE ---
    GoRoute(
      path: '/incoming-requests',
      builder: (context, state) => const IncomingRequestsPage(),
    ),

    // --- CHAT ROUTE ---
    GoRoute(
      path: '/chat/:bookingId/:customerId/:providerId',
      builder: (context, state) => ChatPage(
        bookingId: state.pathParameters['bookingId']!,
        customerId: state.pathParameters['customerId']!,
        providerId: state.pathParameters['providerId']!,
      ),
    ),

    GoRoute(
      path: '/confirmed-bookings',
      builder: (context, state) => const ConfirmedBookingsPage(),
    ),    
  ],

  // --- REDIRECT LOGIC ---
  redirect: (context, state) {
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final isAuthenticated = authState is Authenticated;
    final targetPath = state.uri.path;

    // Retrieve user role and ID for RBAC check
    final userRole = isAuthenticated ? (authState as Authenticated).user.role : null;
    final userId = isAuthenticated ? (authState as Authenticated).user.id : null;

    print('DEBUG: Redirect check - Target: $targetPath, Authenticated: $isAuthenticated, Role: $userRole, User ID: $userId');

    // A. UNAUTHENTICATED REDIRECTS
    if (!isAuthenticated) {
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
        print('DEBUG: Allowing public path: $targetPath');
        return null;
      }
      print('DEBUG: Redirecting unauthenticated user to /login');
      return '/login';
    }

    // B. AUTHENTICATED REDIRECTS (Block login/register pages)
    if (isAuthenticated &&
        ['/login', '/register', '/otp-verification'].contains(targetPath)) {
      print('DEBUG: Redirecting authenticated user from $targetPath to /');
      return '/';
    }

    // C. RBAC: PROVIDER DASHBOARD
    if (targetPath == '/provider-dashboard') {
      if (userRole == Role.provider) {
        print('DEBUG: Allowing provider access to /provider-dashboard');
        return null;
      } else {
        print('DEBUG: Redirecting non-provider from /provider-dashboard to /');
        return '/';
      }
    }

    // D. RBAC: INCOMING REQUESTS (Providers only)
    if (targetPath == '/incoming-requests') {
      if (userRole != Role.provider) {
        print('DEBUG: Redirecting non-provider from /incoming-requests to /');
        return '/';
      }
      print('DEBUG: Allowing provider access to /incoming-requests');
      return null;
    }

    // E. RBAC: CHAT PAGE (Customers and Providers only)
    if (targetPath.startsWith('/chat')) {
      if (!isAuthenticated) {
        print('DEBUG: Redirecting unauthenticated user from $targetPath to /login');
        return '/login';
      }
      // Check if userRole is customer or provider (using enum comparison)
      if (userRole != Role.customer && userRole != Role.provider) {
        print('DEBUG: Redirecting non-customer/provider from $targetPath to /login');
        return '/login';
      }
      // Additional check: Ensure user is part of the booking
      final pathSegments = state.uri.path.split('/');
      if (pathSegments.length >= 5) {
        final customerId = pathSegments[3];
        final providerId = pathSegments[4];
        if (userId != customerId && userId != providerId) {
          print('DEBUG: Redirecting user $userId from $targetPath to / (not part of booking)');
          return '/';
        }
      }
      print('DEBUG: Allowing access to $targetPath for user $userId');
      return null;
    }

    // F. RBAC: Prevent providers/admin from registration page
    if (targetPath == '/provider-registration') {
      if (userRole == Role.provider || userRole == Role.admin) {
        print('DEBUG: Redirecting provider/admin from /provider-registration to /');
        return '/';
      }
    }

    print('DEBUG: No redirect needed for $targetPath');
    return null;
  },

  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);