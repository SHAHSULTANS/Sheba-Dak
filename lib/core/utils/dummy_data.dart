import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../../features/booking/domain/entities/booking_entity.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/home/domain/entities/service_category.dart';
import '../../features/home/domain/entities/service.dart';
import '../../features/provider/domain/entities/service_provider.dart';
import '../../features/provider/domain/entities/provider_application.dart';
import '../../features/chat/domain/entities/chat_message.dart';
import 'package:smartsheba/features/booking/domain/entities/review_entity.dart';

class DummyData {

  // Add this method to your dummy_data.dart
  static void updateUserRole(String userId, Role newRole) {
    // In a real app, this would update the backend
    // For dummy data, we'll simulate the role change
    print('🔄 Updating user $userId role to: ${newRole.name}');
  }


  // Mock Dhaka coordinates for realistic testing
  static final LatLng dhanmondi = LatLng(23.7465, 90.3760);
  static final LatLng gulshan = LatLng(23.7940, 90.4154);
  static final LatLng uttara = LatLng(23.8759, 90.3795);
  static final LatLng mirpur = LatLng(23.8223, 90.3654);
  static final LatLng banani = LatLng(23.7948, 90.4054);

  // ==============================
  // Customers
  // ==============================
  static final List<UserEntity> _customers = [
    UserEntity(
      id: 'customer1',
      name: 'Karim Rahman',
      phoneNumber: '+8801712345678',
      email: 'karim@example.com',
      token: const Uuid().v4(),
      role: Role.customer,
      address: 'House 12, Road 5, Dhanmondi',
      city: 'Dhaka',
      postalCode: '1205',
      gender: Gender.male,
      dateOfBirth: DateTime(1990, 5, 15),
      profileImageUrl: null,
      isVerified: true,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'customer2',
      name: 'Fatima Begum',
      phoneNumber: '+8801812345678',
      email: 'fatima@example.com',
      token: const Uuid().v4(),
      role: Role.customer,
      address: 'Flat 3B, Gulshan Avenue',
      city: 'Dhaka',
      postalCode: '1212',
      gender: Gender.female,
      dateOfBirth: DateTime(1985, 10, 22),
      profileImageUrl: null,
      isVerified: true,
      createdAt: DateTime.now(),
    ),
  ];

  // ==============================
  // Providers
  // ==============================
  static final List<UserEntity> _providers = [
    UserEntity(
      id: 'provider1',
      name: 'Rahim Technician',
      phoneNumber: '+8801912345678',
      email: 'rahim@example.com',
      token: const Uuid().v4(),
      role: Role.provider,
      address: 'Mirpur, Dhaka',
      city: 'Dhaka',
      postalCode: '1216',
      gender: Gender.male,
      dateOfBirth: DateTime(1980, 3, 10),
      profileImageUrl: null,
      isVerified: true,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'provider2',
      name: 'Aman Electric',
      phoneNumber: '+8801719876543',
      email: 'aman@example.com',
      token: const Uuid().v4(),
      role: Role.provider,
      address: 'Banani, Dhaka',
      city: 'Dhaka',
      postalCode: '1213',
      gender: Gender.male,
      dateOfBirth: DateTime(1975, 7, 20),
      profileImageUrl: null,
      isVerified: false,
      createdAt: DateTime.now(),
    ),
  ];

  static UserEntity getUserById(String userId) {
    final allUsers = [..._customers, ..._providers];
    return allUsers.firstWhere(
      (user) => user.id == userId,
      orElse: () => UserEntity(
        id: 'error',
        name: 'Unknown User',
        phoneNumber: 'N/A',
        token: 'N/A',
        role: Role.customer,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ==============================
  // Chat Messages
  // ==============================
  static final List<ChatMessage> _messages = [];

  static void initDummyMessages() {
    _messages.clear();
    
    // 🚀 FIX: Ensure messages exist for ALL customer1 bookings with proper IDs
    print('DEBUG: Initializing dummy messages for customer1 bookings...');
    
    // Messages for booking1 (customer1 -> provider1)
    _messages.add(ChatMessage(
      id: 'msg_booking1_1',
      bookingId: 'booking1',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Hello, I need help with fixing a leaking pipe in my kitchen.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking1_2',
      bookingId: 'booking1',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'Sure, I can help with plumbing issues. When would be a good time?',
      timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking1_3',
      bookingId: 'booking1',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Tomorrow at 10 AM would work for me.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
    ));

    // Messages for booking2 (customer1 -> provider1)
    _messages.add(ChatMessage(
      id: 'msg_booking2_1',
      bookingId: 'booking2',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'I have electrical wiring issues in my living room.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking2_2',
      bookingId: 'booking2',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'I can help with electrical repairs. What specific issues are you facing?',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ));

    // Messages for booking3 (customer1 -> provider1)
    _messages.add(ChatMessage(
      id: 'msg_booking3_1',
      bookingId: 'booking3',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'I need deep cleaning service for my apartment.',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking3_2',
      bookingId: 'booking3',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'Confirmed! I\'ll be there at 2 PM for the cleaning service.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ));

    // Messages for booking4 (customer1 -> provider1)
    _messages.add(ChatMessage(
      id: 'msg_booking4_1',
      bookingId: 'booking4',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Payment completed for the painting service. When can you start?',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking4_2',
      bookingId: 'booking4',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'Thanks for the payment! I\'ll start tomorrow at 10 AM.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ));

    // Messages for booking5 (customer1 -> provider1)
    _messages.add(ChatMessage(
      id: 'msg_booking5_1',
      bookingId: 'booking5',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'I\'m on my way for the plumbing service.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking5_2',
      bookingId: 'booking5',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Great, I\'ll be waiting. The main gate will be open.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ));

    // Messages for booking6 (customer1 -> provider1)
    _messages.add(ChatMessage(
      id: 'msg_booking6_1',
      bookingId: 'booking6',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'The office cleaning is complete. Everything looks great!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking6_2',
      bookingId: 'booking6',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Thank you for the excellent service! The office looks amazing.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, minutes: 30)),
    ));

    // Additional messages for different scenarios
    _messages.add(ChatMessage(
      id: 'msg_booking7_1',
      bookingId: 'booking7',
      senderId: 'customer1',
      recipientId: 'provider2',
      message: 'Do you provide emergency electrical services?',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ));
    _messages.add(ChatMessage(
      id: 'msg_booking7_2',
      bookingId: 'booking7',
      senderId: 'provider2',
      recipientId: 'customer1',
      message: 'Yes, we provide 24/7 emergency electrical services.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
    ));

    print('DEBUG: Initialized ${_messages.length} dummy messages');
    // Debug: Print all booking IDs with messages
    final uniqueBookingIds = _messages.map((m) => m.bookingId).toSet().toList();
    print('DEBUG: Messages available for booking IDs: $uniqueBookingIds');
  }
    
  static void addMessage(ChatMessage message) {
    _messages.add(message);
    print('DEBUG: New Message Added: ${message.id} for Booking ${message.bookingId}');
    print('DEBUG: From: ${message.senderId} -> To: ${message.recipientId}');
    print('DEBUG: Message: ${message.message}');
  }

  static List<ChatMessage> getMessagesByBooking(String bookingId) {
    final messages = _messages
        .where((m) => m.bookingId == bookingId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    print('DEBUG: getMessagesByBooking($bookingId) found ${messages.length} messages');
    for (var msg in messages) {
      print('DEBUG: - ${msg.senderId} -> ${msg.recipientId}: ${msg.message}');
    }
    
    return messages;
  }

  // ==============================
  // Provider Applications
  // ==============================
  static final List<ProviderApplication> _applications = [];

  static void addProviderApplication(ProviderApplication application) {
    _applications.add(application);
    print('DEBUG: New Provider Application Added: ${application.name} (Total: ${_applications.length})');
  }

  static List<ProviderApplication> getPendingApplications() {
    return List.unmodifiable(_applications);
  }

  // ==============================
  // Bookings
  // ==============================
  static final List<BookingEntity> _bookings = [];

  // NEW METHOD: Update booking status
  static void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final oldBooking = _bookings[index];
      _bookings[index] = oldBooking.copyWith(status: newStatus);
      print('DEBUG: Updated booking $bookingId status from ${oldBooking.status} to $newStatus');
    } else {
      print('DEBUG: Booking $bookingId not found for status update');
    }
  }

  static void addBooking(BookingEntity booking) {
    _bookings.add(booking);
    print('DEBUG: New Booking Added: ${booking.id} (${booking.status}) for Customer ${booking.customerId} by Provider ${booking.providerId}');
  }

  static List<BookingEntity> getBookingsByProvider(String providerId) {
    final bookings = _bookings
        .where((b) => b.providerId == providerId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    
    print('DEBUG: getBookingsByProvider($providerId) found ${bookings.length} bookings');
    return bookings;
  }

  static List<BookingEntity> getBookingsByCustomer(String customerId) {
    final bookings = _bookings
        .where((b) => b.customerId == customerId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    
    print('DEBUG: getBookingsByCustomer($customerId) found ${bookings.length} bookings');
    for (var booking in bookings) {
      print('DEBUG: - Booking ${booking.id}: ${booking.serviceCategory} (${booking.status})');
    }
    
    return bookings;
  }

  static List<BookingEntity> getCustomerBookings(String customerId, {BookingStatus? status}) {
    var customerBookings = _bookings
        .where((b) => b.customerId == customerId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    
    if (status != null) {
      customerBookings = customerBookings.where((b) => b.status == status).toList();
    }
    
    print('DEBUG: getCustomerBookings($customerId, status: $status) found ${customerBookings.length} bookings');
    return customerBookings;
  }

  static List<BookingEntity> getPendingBookingsByProvider(String providerId) {
    return _bookings
        .where((b) => b.providerId == providerId && b.status == BookingStatus.pending)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static List<BookingEntity> getInternalBookingsList() {
    if (_bookings.isEmpty) {
      print('DEBUG: Bookings list is empty, reinitializing');
      initDummyBookings();
    }
    return List<BookingEntity>.from(_bookings);
  }

  static final List<ReviewEntity> _reviews = [];

  static void addReview(ReviewEntity review) {
    _reviews.add(review);
    print('DEBUG: New Review Added: ${review.id} for Booking ${review.bookingId}');
  }

  static List<ReviewEntity> getReviewsByBooking(String bookingId) {
    return _reviews
        .where((r) => r.bookingId == bookingId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static List<ReviewEntity> getReviewsByProvider(String providerId) {
    return _reviews
        .where((r) => r.providerId == providerId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static void initDummyBookings() {
    _bookings.clear();
    print('DEBUG: Initializing dummy bookings for customer1...');
    
    // Booking 1: Pending (Incoming tab for provider)
    addBooking(BookingEntity(
      id: 'booking1',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'plumbing',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 10)),
      status: BookingStatus.pending,
      price: 500.0,
      description: 'Fix leaking pipe in kitchen',
    ));
    // Booking 2: Payment Pending (Confirmed tab for provider)
    addBooking(BookingEntity(
      id: 'booking2',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'electrical',
      scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 12)),
      status: BookingStatus.paymentPending,
      price: 800.0,
      description: 'Repair wiring in living room',
    ));
    // Booking 3: Confirmed (Confirmed tab for provider)
    addBooking(BookingEntity(
      id: 'booking3',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'cleaning',
      scheduledAt: DateTime.now().add(const Duration(hours: 5)),
      status: BookingStatus.confirmed,
      price: 1500.0,
      description: 'Deep cleaning of apartment',
    ));
    // Booking 4: Payment Completed (Confirmed tab for provider)
    addBooking(BookingEntity(
      id: 'booking4',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'painting',
      scheduledAt: DateTime.now().add(const Duration(days: 3)),
      status: BookingStatus.paymentCompleted,
      price: 1000.0,
      description: 'Wall painting for bedroom',
    ));
    // Booking 5: In Progress (Active tab for provider)
    addBooking(BookingEntity(
      id: 'booking5',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'plumbing',
      scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: BookingStatus.inProgress,
      price: 700.0,
      description: 'Install new toilet system',
    ));
    // Booking 6: Completed (Completed tab for provider)
    addBooking(BookingEntity(
      id: 'booking6',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'cleaning',
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      status: BookingStatus.completed,
      price: 1200.0,
      description: 'Completed office cleaning',
    ));
    // Booking 7: Cancelled (Not shown in tabs, for testing)
    addBooking(BookingEntity(
      id: 'booking7',
      customerId: 'customer2',
      providerId: 'provider1',
      serviceCategory: 'painting',
      scheduledAt: DateTime.now().subtract(const Duration(days: 4)),
      status: BookingStatus.cancelled,
      price: 1000.0,
      description: 'Cancelled exterior painting',
    ));
    // Booking 8: Pending for customer2 (Incoming tab for provider2)
    addBooking(BookingEntity(
      id: 'booking8',
      customerId: 'customer2',
      providerId: 'provider2',
      serviceCategory: 'electrical',
      scheduledAt: DateTime.now().add(const Duration(days: 4, hours: 14)),
      status: BookingStatus.pending,
      price: 600.0,
      description: 'Install new light fixtures',
    ));

    // Initialize dummy reviews for completed bookings
    _reviews.clear();
    _reviews.add(
      ReviewEntity(
        id: const Uuid().v4(),
        bookingId: 'booking4',
        providerId: 'provider1',
        customerId: 'customer1',
        rating: 4,
        comment: 'Great service, but could be faster.',
        createdAt: DateTime.now(),
      ),
    );
    
    print('DEBUG: Initialized ${_bookings.length} dummy bookings and ${_reviews.length} reviews');
    print('DEBUG: Customer1 booking IDs: ${_bookings.where((b) => b.customerId == 'customer1').map((b) => b.id).toList()}');
  }

  static BookingEntity? getBookingById(String bookingId) {
    final booking = _bookings.firstWhere(
      (booking) => booking.id == bookingId,
      orElse: () => BookingEntity(
        id: 'error',
        customerId: 'unknown',
        providerId: 'unknown',
        serviceCategory: 'Unknown Service',
        scheduledAt: DateTime.now(),
        status: BookingStatus.pending,
        price: 0.0,
        description: 'Booking not found',
      ),
    );
    
    print('DEBUG: getBookingById($bookingId) found: ${booking.id != 'error' ? booking.serviceCategory : 'NOT FOUND'}');
    return booking.id != 'error' ? booking : null;
  }

  static bool hasReviewForBooking(String bookingId) {
    return _reviews.any((review) => review.bookingId == bookingId);
  }

  // ==============================
  // Services & Providers
  // ==============================
  static const List<Service> _allServices = [
    Service(
      id: 'pipe-repair',
      categoryId: 'plumbing',
      name: 'Pipe Repair',
      description: 'Fix leaking pipes and ensure waterproofing.',
      price: 500.0,
      providerName: 'Rahim Technician',
    ),
    Service(
      id: 'drain-clean',
      categoryId: 'plumbing',
      name: 'Drain Cleaning',
      description: 'Clean blocked drains with quick machine solutions.',
      price: 300.0,
      providerName: 'Rahim Technician',
    ),
    Service(
      id: 'toilet-fix',
      categoryId: 'plumbing',
      name: 'Toilet Fix',
      description: 'Repair toilet flushing and install new parts.',
      price: 450.0,
      providerName: 'Rahim Technician',
    ),
    Service(
      id: 'wiring-fix',
      categoryId: 'electrical',
      name: 'Wiring Repair',
      description: 'Solve home or office wiring problems, fix short circuits.',
      price: 600.0,
      providerName: 'Aman Electric',
    ),
    Service(
      id: 'light-fix',
      categoryId: 'electrical',
      name: 'Light Fixture Install',
      description: 'Install and repair lights, fans, or switches.',
      price: 200.0,
      providerName: 'Aman Electric',
    ),
    Service(
      id: 'circuit-break',
      categoryId: 'electrical',
      name: 'Circuit Breaker Fix',
      description: 'Repair faulty circuit breakers and new installations.',
      price: 750.0,
      providerName: 'Aman Electric',
    ),
    Service(
      id: 'deep-clean',
      categoryId: 'cleaning',
      name: 'Deep Cleaning',
      description: 'Deep clean entire home with special kitchen and bathroom care.',
      price: 1500.0,
      providerName: 'Shine Cleaners',
    ),
    Service(
      id: 'carpet-clean',
      categoryId: 'cleaning',
      name: 'Carpet Cleaning',
      description: 'Professional carpet washing and steam cleaning service.',
      price: 800.0,
      providerName: 'Shine Cleaners',
    ),
    Service(
      id: 'sofa-clean',
      categoryId: 'cleaning',
      name: 'Sofa Cleaning',
      description: 'Clean sofas and furniture with fabric and leather care service.',
      price: 1000.0,
      providerName: 'Shine Cleaners',
    ),
    Service(
      id: 'wall-paint',
      categoryId: 'painting',
      name: 'Wall Painting',
      description: 'Painting and finishing with premium quality paint.',
      price: 1000.0,
      providerName: 'Paint Master',
    ),
    Service(
      id: 'wood-polish',
      categoryId: 'painting',
      name: 'Wood Polish',
      description: 'Varnish and polish wooden furniture for lasting gloss.',
      price: 950.0,
      providerName: 'Paint Master',
    ),
    Service(
      id: 'texture-paint',
      categoryId: 'painting',
      name: 'Texture Paint',
      description: 'Modern texture painting with expert designer consultation.',
      price: 1500.0,
      providerName: 'Paint Master',
    ),
    Service(
      id: 'home-move',
      categoryId: 'movers',
      name: 'Home Moving',
      description: 'Complete home relocation service',
      price: 8000.0,
      providerName: 'Movers BD',
    ),
    Service(
      id: 'ambulance',
      categoryId: 'emergency',
      name: 'Ambulance',
      description: 'Emergency medical service',
      price: 1000.0,
      providerName: 'Emergency Response',
    ),
  ];

  static List<ServiceCategory> getServiceCategories() {
    return const [
      ServiceCategory(
        id: 'plumbing',
        name: 'Plumbing',
        iconPath: 'assets/icons/plumbing.png',
        description: 'Pipe leaks, drain blocks etc',
      ),
      ServiceCategory(
        id: 'electrical',
        name: 'Electrical',
        iconPath: 'assets/icons/electrical.png',
        description: 'Wiring, light fixtures etc',
      ),
      ServiceCategory(
        id: 'cleaning',
        name: 'Cleaning',
        iconPath: 'assets/icons/cleaning.png',
        description: 'Home, office, car cleaning',
      ),
      ServiceCategory(
        id: 'painting',
        name: 'Painting',
        iconPath: 'assets/icons/painting.png',
        description: 'Home or office wall painting',
      ),
      ServiceCategory(
        id: 'carpentry',
        name: 'Carpentry',
        iconPath: 'assets/icons/carpentry.png',
        description: 'Furniture making and repair',
      ),
      ServiceCategory(
        id: 'ac_repair',
        name: 'AC Repair',
        iconPath: 'assets/icons/ac_repair.png',
        description: 'AC installation and repair',
      ),
      ServiceCategory(
        id: 'appliances',
        name: 'Appliance Repair',
        iconPath: 'assets/icons/appliances.png',
        description: 'Fridge, TV, washing machine repair',
      ),
      ServiceCategory(
        id: 'pest_control',
        name: 'Pest Control',
        iconPath: 'assets/icons/pest_control.png',
        description: 'Cockroach, rat, ant control',
      ),
      ServiceCategory(
        id: 'laundry',
        name: 'Laundry & Dry',
        iconPath: 'assets/icons/laundry.png',
        description: 'Clothes washing and ironing',
      ),
      ServiceCategory(
        id: 'beauty',
        name: 'Beauty Services',
        iconPath: 'assets/icons/beauty.png',
        description: 'Home beauty care',
      ),
      ServiceCategory(
        id: 'car_wash',
        name: 'Car Wash',
        iconPath: 'assets/icons/car_wash.png',
        description: 'Car washing at home or office',
      ),
      ServiceCategory(
        id: 'gardening',
        name: 'Gardening',
        iconPath: 'assets/icons/gardening.png',
        description: 'Planting and plant care in pots',
      ),
      ServiceCategory(
        id: 'photography',
        name: 'Photography',
        iconPath: 'assets/icons/photography.png',
        description: 'Photographer for events',
      ),
      ServiceCategory(
        id: 'movers',
        name: 'Home Moving',
        iconPath: 'assets/icons/movers.png',
        description: 'Home or office relocation service',
      ),
      ServiceCategory(
        id: 'emergency',
        name: 'Emergency',
        iconPath: 'assets/icons/emergency.png',
        description: 'Ambulance, fire service etc',
      ),
    ];
  }

  static List<Service> getServices(String categoryId) {
    if (categoryId.isEmpty) {
      return _allServices;
    }
    return _allServices
        .where((service) => service.categoryId == categoryId)
        .toList();
  }

  static Service getServiceById(String serviceId) {
    return _allServices.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => const Service(
        id: 'error',
        categoryId: '',
        name: 'Service Not Found',
        description: 'The requested service is currently unavailable. Please return to service list.',
        price: 0,
        providerName: 'N/A',
      ),
    );
  }

  static List<ServiceProvider> getProviders() {
    return [
      ServiceProvider(
        id: 'provider1',
        name: 'Rahim Technician',
        rating: 4.5,
        isVerified: true,
        services: ['pipe-repair', 'drain-clean', 'toilet-fix', 'deep-clean', 'carpet-clean', 'sofa-clean', 'wall-paint', 'wood-polish', 'texture-paint'],
        description: 'Five years experienced skilled plumber and cleaner. Ensure fast and reliable service.',
        businessLocation: dhanmondi,
        serviceRadius: 15.0,
        servedAreas: ['Dhanmondi', 'Mohammadpur', 'Lalbag'],
        isOnline: true,
        lastActive: DateTime.now(),
      ),
      ServiceProvider(
        id: 'provider2',
        name: 'Aman Electric',
        rating: 4.0,
        isVerified: false,
        services: ['wiring-fix', 'light-fix', 'circuit-break'],
        description: 'Electrical specialist. Capable of solving any complex wiring problems in home or office.',
        businessLocation: gulshan,
        serviceRadius: 12.0,
        servedAreas: ['Gulshan', 'Banani', 'Baridhara'],
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ServiceProvider(
        id: 'provider3',
        name: 'Shine Cleaners',
        rating: 4.8,
        isVerified: true,
        services: ['deep-clean', 'carpet-clean', 'sofa-clean'],
        description: 'We deeply clean your home or office by making it germ-free.',
        businessLocation: uttara,
        serviceRadius: 20.0,
        servedAreas: ['Uttara', 'Tejgaon', 'Ashulia'],
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ServiceProvider(
        id: 'provider4',
        name: 'Paint Master',
        rating: 3.9,
        isVerified: true,
        services: ['wall-paint', 'wood-polish', 'texture-paint'],
        description: 'Professional painting service. Give new life to your walls.',
        businessLocation: mirpur,
        serviceRadius: 8.0,
        servedAreas: ['Mirpur', 'Sheorapara', 'Pallabi'],
        isOnline: true,
        lastActive: DateTime.now(),
      ),
      ServiceProvider(
        id: 'provider5',
        name: 'Cool Tech',
        rating: 4.2,
        isVerified: false,
        services: ['ac-install', 'ac-service', 'gas-refill'],
        description: 'Contact for all types of AC installation, servicing and quick repairs.',
        businessLocation: banani,
        serviceRadius: 10.0,
        servedAreas: ['Banani', 'Gulshan', 'Mohakhali'],
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // Helper method to filter providers by location
  static List<ServiceProvider> getNearbyProviders(LatLng userLocation, {double maxDistance = 25.0}) {
    final providers = getProviders();
    return providers.where((provider) {
      if (provider.businessLocation == null) return true;
      
      final distance = _calculateDistance(provider.businessLocation!, userLocation);
      return distance <= maxDistance && provider.isOnline;
    }).toList();
  }

  static double _calculateDistance(LatLng start, LatLng end) {
    // Same calculation as in ServiceProvider entity
    const earthRadius = 6371.0;
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);
    
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static ServiceProvider getProviderById(String providerId) {
    return getProviders().firstWhere(
      (p) => p.id == providerId,
      orElse: () => ServiceProvider(
        id: 'error',
        name: 'Provider Not Found',
        rating: 0.0,
        isVerified: false,
        services: [],
        description: 'The requested provider could not be found.',
        businessLocation: null,
        serviceRadius: 0.0,
        servedAreas: [],
        isOnline: false,
        lastActive: DateTime.now(),
      ),
    );
  }


  
  // ==============================
  // Initialize All Data
  // ==============================
  static void initializeAllData() {
    print('🚀 DEBUG: Initializing all dummy data...');
    initDummyBookings();
    initDummyMessages();
    print('🚀 DEBUG: DummyData initialized with ${_bookings.length} bookings and ${_messages.length} messages');
    
    // Verify customer1 data
    final customer1Bookings = getBookingsByCustomer('customer1');
    print('🚀 DEBUG: Customer1 has ${customer1Bookings.length} bookings:');
    for (var booking in customer1Bookings) {
      final messages = getMessagesByBooking(booking.id);
      print('🚀 DEBUG: - Booking ${booking.id}: ${messages.length} messages');
    }
  }

 // Add this method for personalized recommendations
static List<Service> getRecommendedServices() {
  return [
    Service(
      id: 'rec1',
      categoryId: 'plumbing', // Make sure this matches your parameter order
      name: 'জরুরি প্লাম্বিং সার্ভিস', // Changed from 'title' to 'name'
      description: 'তাৎক্ষণিক পানির লাইন এবং ড্রেনেজ সার্ভিস',
      price: 800,
      providerName: 'প্রফেশনাল প্লাম্বিং সার্ভিস', // ✅ Add providerName
    ),
    Service(
      id: 'rec2',
      categoryId: 'ac_service',
      name: 'এসি রিপেয়ার', // Changed from 'title' to 'name'
      description: 'এয়ার কন্ডিশনার মেরামত এবং পরিষ্কার',
      price: 1200,
      providerName: 'কুল এয়ার টেকনিশিয়ান', // ✅ Add providerName
    ),
    Service(
      id: 'rec3',
      categoryId: 'electrical',
      name: 'ইলেকট্রিক্যাল ওয়্যারিং', // Changed from 'title' to 'name'
      description: 'বাড়ির ইলেকট্রিক সেটআপ এবং মেরামত',
      price: 1500,
      providerName: 'সেফ ইলেকট্রিক সার্ভিস', // ✅ Add providerName
    ),
    // Add more as needed
  ];
}

}