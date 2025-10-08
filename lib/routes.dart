// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/pages/profile_veiw.dart';
import 'package:smartsheba/features/booking/presentation/pages/incoming_requests_page.dart';
import 'package:smartsheba/features/booking/presentation/pages/incoming_request_details_page.dart'; // New import
import 'package:smartsheba/features/booking/presentation/pages/review_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/provider_confirmed_booking.dart';
import 'package:smartsheba/features/auth/presentation/pages/login_page.dart';
import 'package:smartsheba/features/auth/presentation/pages/register_page.dart';
import 'package:smartsheba/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:smartsheba/features/auth/presentation/pages/profile_creation_page.dart';
import 'package:smartsheba/features/auth/presentation/pages/profile_edit_page.dart';
import 'package:smartsheba/features/home/presentation/pages/home_page.dart';
import 'package:smartsheba/features/home/presentation/pages/service_list_page.dart';
import 'package:smartsheba/features/home/presentation/pages/service_detail_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/provider_list_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/provider_detail_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/provider_dashboard_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/contact_provider_page.dart';
import 'package:smartsheba/features/provider/presentation/pages/provider_registration_page.dart';
import 'package:smartsheba/features/booking/presentation/pages/book_service_page.dart';
import 'package:smartsheba/features/booking/presentation/pages/my_bookings_page.dart';
import 'package:smartsheba/features/payment/presentation/pages/payment_page.dart';
import 'package:smartsheba/features/chat/presentation/pages/chat_page.dart';
import 'package:smartsheba/features/booking/presentation/pages/payment_status_page.dart';

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

    // --- PAYMENT ROUTES ---
    GoRoute(
      path: '/payment/:bookingId',
      builder: (context, state) => PaymentPage(
        bookingId: state.pathParameters['bookingId']!,
      ),
    ),
    GoRoute(
      path: '/payment-status/:id',
      builder: (context, state) => PaymentStatusPage(
        id: state.pathParameters['id']!,
      ),
    ),

    // --- PROVIDER MANAGEMENT ROUTES ---
    GoRoute(
      path: '/providers',
      builder: (context, state) => const ProviderListPage(),
    ),
    GoRoute(
      path: '/provider-detail/:id',
      builder: (context, state) => ProviderDetailPage(id: state.pathParameters['id']!),
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

    // --- INCOMING REQUESTS ROUTES ---
    GoRoute(
      path: '/incoming-requests',
      builder: (context, state) => const IncomingRequestsPage(),
    ),
    GoRoute(
      path: '/incoming-requests/:id', // New route
      builder: (context, state) => IncomingRequestDetailsPage(
        id: state.pathParameters['id']!,
      ),
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

    GoRoute(
    path: '/review/:bookingId',
    builder: (context, state) => ReviewPage(
      bookingId: state.pathParameters['bookingId']!,
    ),
  ),
  ],
  

  // --- REDIRECT LOGIC ---
  redirect: (context, state) {
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final isAuthenticated = authState is Authenticated;
    final targetPath = state.uri.path;
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
    if (targetPath.startsWith('/incoming-requests')) { // Updated to cover /incoming-requests/:id
      if (userRole != Role.provider) {
        print('DEBUG: Redirecting non-provider from $targetPath to /');
        return '/';
      }
      print('DEBUG: Allowing provider access to $targetPath');
      return null;
    }

    // E. RBAC: PAYMENT PAGE (Customers only)
    if (targetPath.startsWith('/payment/')) {
      if (!isAuthenticated) {
        print('DEBUG: Redirecting unauthenticated user from $targetPath to /login');
        return '/login';
      }
      if (userRole != Role.customer) {
        print('DEBUG: Redirecting non-customer from $targetPath to /login');
        return '/login';
      }
      print('DEBUG: Allowing customer access to $targetPath');
      return null;
    }

    // F. RBAC: PAYMENT STATUS PAGE (Providers only)
    if (targetPath.startsWith('/payment-status/')) {
      if (!isAuthenticated) {
        print('DEBUG: Redirecting unauthenticated user from $targetPath to /login');
        return '/login';
      }
      if (userRole != Role.provider) {
        print('DEBUG: Redirecting non-provider from $targetPath to /');
        return '/';
      }
      print('DEBUG: Allowing provider access to $targetPath');
      return null;
    }

    // G. RBAC: CHAT PAGE (Customers and Providers only)
    if (targetPath.startsWith('/chat')) {
      if (!isAuthenticated) {
        print('DEBUG: Redirecting unauthenticated user from $targetPath to /login');
        return '/login';
      }
      if (userRole != Role.customer && userRole != Role.provider) {
        print('DEBUG: Redirecting non-customer/provider from $targetPath to /login');
        return '/login';
      }
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


  // RBAC: REVIEW PAGE (Customers only)
    if (targetPath.startsWith('/review')) {
      if (!isAuthenticated) {
        print('DEBUG: Redirecting unauthenticated user from $targetPath to /login');
        return '/login';
      }
      if (userRole != Role.customer) {
        print('DEBUG: Redirecting non-customer from $targetPath to /');
        return '/';
      }
      print('DEBUG: Allowing customer access to $targetPath');
      return null;
    }




    // ... existing redirect logic ...
  
    // H. RBAC: Prevent providers/admin from registration page
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