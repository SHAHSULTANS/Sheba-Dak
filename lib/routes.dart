// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/pages/address_input_page.dart';
import 'package:smartsheba/features/auth/presentation/pages/profile_veiw.dart';
import 'package:smartsheba/features/booking/presentation/pages/incoming_requests_page.dart';
import 'package:smartsheba/features/booking/presentation/pages/incoming_request_details_page.dart';
import 'package:smartsheba/features/booking/presentation/pages/review_page.dart';
import 'package:smartsheba/features/provider/domain/entities/service_provider.dart';
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
import 'package:smartsheba/features/provider/presentation/pages/service_area_setup_page.dart';

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
          phoneNumber: phoneNumber ?? '',
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

    // --- LOCATION & ADDRESS ROUTES ---
    GoRoute(
      path: '/address-input',
      builder: (context, state) => const AddressInputPage(),
    ),

    // --- SERVICES ROUTES (PUBLIC) ---
    GoRoute(
      path: '/services',
      redirect: (context, state) {
        return '/services/all';
      },
    ),
    GoRoute(
      path: '/services/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        return ServiceListPage(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/service-detail/:serviceId',
      builder: (context, state) => ServiceDetailPage(
        id: state.pathParameters['serviceId']!,
      ),
    ),

    // --- PROVIDER ROUTES (PUBLIC) ---
    GoRoute(
      path: '/providers',
      builder: (context, state) => const ProviderListPage(),
    ),
    GoRoute(
      path: '/provider-detail/:id',
      builder: (context, state) => ProviderDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/contact-provider/:id',
      builder: (context, state) => const ContactProviderPage(),
    ),

    // --- BOOKING ROUTES (REQUIRE AUTH) ---
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

    // --- PAYMENT ROUTES (REQUIRE AUTH) ---
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
      path: '/provider-dashboard',
      builder: (context, state) => const ProviderDashboardPage(),
    ),
    GoRoute(
      path: '/provider-registration',
      builder: (context, state) => const ProviderRegistrationPage(),
    ),

    // --- INCOMING REQUESTS ROUTES (PROVIDER ONLY) ---
    GoRoute(
      path: '/incoming-requests',
      builder: (context, state) => const IncomingRequestsPage(),
    ),
    GoRoute(
      path: '/incoming-requests/:id',
      builder: (context, state) => IncomingRequestDetailsPage(
        id: state.pathParameters['id']!,
      ),
    ),

    // --- CHAT ROUTE (REQUIRE AUTH) ---
    GoRoute(
      path: '/chat/:bookingId/:customerId/:providerId',
      builder: (context, state) => ChatPage(
        bookingId: state.pathParameters['bookingId']!,
        customerId: state.pathParameters['customerId']!,
        providerId: state.pathParameters['providerId']!,
      ),
    ),

    // --- REVIEW ROUTE (REQUIRE AUTH) ---
    GoRoute(
      path: '/review/:bookingId',
      builder: (context, state) => ReviewPage(
        bookingId: state.pathParameters['bookingId']!,
      ),
    ),

    // Add to lib/routes.dart
   GoRoute(
      path: '/service-area-setup',
      builder: (context, state) {
        final extra = state.extra;
        ServiceProvider? provider;

        if (extra != null) {
          if (extra is ServiceProvider) {
            provider = extra;
          } else if (extra is Map<String, dynamic>) {
            provider = ServiceProvider.fromJson(extra);
          }
        }

        return ServiceAreaSetupPage(existingProvider: provider);
      },
    ),


  ],

  // --- ✅ FIXED REDIRECT LOGIC: Proper Pattern Matching with Trailing Slashes ---
  redirect: (context, state) {
    final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
    final isAuthenticated = authState is Authenticated;
    final targetPath = state.uri.path;
    final userRole = isAuthenticated ? (authState as Authenticated).user.role : null;

    print('🔍 REDIRECT: Target: $targetPath, Auth: $isAuthenticated, Role: $userRole');

    // ✅ STEP 1: PUBLIC ROUTES - Exact matches (no auth needed)
    const publicRoutes = [
      '/',
      '/login',
      '/register',
      '/otp-verification',
      '/services',
      '/providers',
    ];

    if (publicRoutes.contains(targetPath)) {
      print('✅ Public exact match: $targetPath');
      return null;
    }

    // ✅ STEP 2: PUBLIC BROWSING - Parameterized routes (no auth needed)
    if (targetPath.startsWith('/services/') ||
        targetPath.startsWith('/service-detail/') ||
        targetPath.startsWith('/provider-detail/')) {
      print('✅ Public browsing: $targetPath');
      return null;
    }

    // ✅ STEP 3: PROTECTED ROUTES - Check authentication requirement
    // ⚠️ CRITICAL: Use trailing slashes for parameterized routes
    const protectedPatterns = [
      '/profile-view',
      '/profile-edit',
      '/profile-creation',
      '/my-bookings',
      '/booking/',          // ✅ Trailing slash for /booking/:providerId/:serviceCategory/:price
      '/payment/',          // ✅ Trailing slash for /payment/:bookingId
      '/payment-status/',   // ✅ Trailing slash for /payment-status/:id
      '/address-input',
      '/chat/',             // ✅ Trailing slash for /chat/:bookingId/:customerId/:providerId
      '/review/',           // ✅ Trailing slash for /review/:bookingId
      '/provider-dashboard',
      '/provider-registration',
      '/incoming-requests', // Both with and without params
      '/contact-provider/', // ✅ Trailing slash for /contact-provider/:id
    ];

    // Check if target path matches any protected pattern
    for (String pattern in protectedPatterns) {
      if (targetPath == pattern || targetPath.startsWith(pattern)) {
        if (!isAuthenticated) {
          print('❌ AUTH REQUIRED: $targetPath → Redirecting to /login');
          return '/login';
        }
        break; // Authentication passed, continue to role checks
      }
    }

    // ✅ STEP 4: Block authenticated users from auth pages
    if (isAuthenticated && 
        ['/login', '/register', '/otp-verification'].contains(targetPath)) {
      print('✅ Already authenticated → Redirecting to home');
      return '/';
    }

    // ✅ STEP 5: ROLE-BASED ACCESS CONTROL (only for authenticated users)
    if (isAuthenticated) {
      // 🔵 CUSTOMER-ONLY ROUTES
      const customerRoutes = [
        '/my-bookings',
        '/booking/',      // ✅ Trailing slash
        '/payment/',      // ✅ Trailing slash
        '/review/',       // ✅ Trailing slash
        '/contact-provider/', // ✅ Trailing slash
      ];

      for (String route in customerRoutes) {
        if (targetPath == route || targetPath.startsWith(route)) {
          if (userRole != Role.customer) {
            print('❌ CUSTOMER-ONLY: $targetPath blocked for ${userRole?.name}');
            if (userRole == Role.provider) {
              return '/provider-dashboard'; // Redirect providers to their dashboard
            }
            return '/';
          }
          return null; // Access granted
        }
      }

      // 🟢 PROVIDER-ONLY ROUTES
      const providerRoutes = [
        '/provider-dashboard',
        '/incoming-requests', // Both exact and with params
      ];

      for (String route in providerRoutes) {
        if (targetPath == route || targetPath.startsWith(route)) {
          if (userRole != Role.provider) {
            print('❌ PROVIDER-ONLY: $targetPath blocked for ${userRole?.name}');
            return '/';
          }
          return null; // Access granted
        }
      }

      // 🟡 Block providers/admins from customer registration flow
      if (targetPath == '/provider-registration' &&
          (userRole == Role.provider || userRole == Role.admin)) {
        print('❌ Provider/Admin blocked from registration');
        return '/provider-dashboard';
      }
    }

    // ✅ STEP 6: Allow access to all other routes
    print('✅ ACCESS GRANTED: $targetPath');
    return null;
  },

  // --- ERROR BUILDER ---
  errorBuilder: (context, state) {
    print('❌ ROUTE ERROR: ${state.error}');
    print('❌ URI: ${state.uri}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('পেজ লোড হয়নি'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('দুঃখিত! ${state.uri.path} পেজ খুঁজে পাওয়া যায়নি'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('হোমে যান'),
            ),
          ],
        ),
      ),
    );
  },
);