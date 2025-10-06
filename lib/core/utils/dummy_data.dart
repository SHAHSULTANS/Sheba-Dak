import 'package:uuid/uuid.dart';
import '../../features/booking/domain/entities/booking_entity.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/home/domain/entities/service_category.dart';
import '../../features/home/domain/entities/service.dart';
import '../../features/provider/domain/entities/service_provider.dart';
import '../../features/provider/domain/entities/provider_application.dart';
import '../../features/chat/domain/entities/chat_message.dart';

class DummyData {
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
    // Sample messages for booking3 (confirmed, customer1 <-> provider1)
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      bookingId: 'booking3',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Hello, can you confirm the cleaning service for tomorrow?',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
    ));
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      bookingId: 'booking3',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'Yes, confirmed! Ill be there at 2 PM',
      timestamp: DateTime.now().subtract(Duration(hours: 1)),
    ));
    // Sample messages for booking4 (paymentCompleted, customer1 <-> provider1)
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      bookingId: 'booking4',
      senderId: 'customer1',
      recipientId: 'provider1',
      message: 'Payment completed for the painting service. When can you start?',
      timestamp: DateTime.now().subtract(Duration(hours: 3)),
    ));
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      bookingId: 'booking4',
      senderId: 'provider1',
      recipientId: 'customer1',
      message: 'Thanks for the payment! Ill start tomorrow at 10 AM.',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
    ));
  }

  static void addMessage(ChatMessage message) {
    _messages.add(message);
    print('DEBUG: New Message Added: ${message.id} for Booking ${message.bookingId}');
  }

  static List<ChatMessage> getMessagesByBooking(String bookingId) {
    return _messages
        .where((m) => m.bookingId == bookingId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
    return _bookings
        .where((b) => b.providerId == providerId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static List<BookingEntity> getBookingsByCustomer(String customerId) {
    return _bookings
        .where((b) => b.customerId == customerId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static List<BookingEntity> getCustomerBookings(String customerId, {BookingStatus? status}) {
    var customerBookings = _bookings
        .where((b) => b.customerId == customerId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (status != null) {
      customerBookings = customerBookings.where((b) => b.status == status).toList();
    }
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
    return List<BookingEntity>.from(_bookings); // Return a modifiable copy
  }

  static void initDummyBookings() {
    _bookings.clear(); // Clear existing bookings to avoid duplicates
    // Booking 1: Pending (Incoming tab for provider)
    addBooking(BookingEntity(
      id: 'booking1',
      customerId: 'customer1',
      providerId: 'provider1',
      serviceCategory: 'plumbing',
      scheduledAt: DateTime.now().add(Duration(days: 1, hours: 10)),
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
      scheduledAt: DateTime.now().add(Duration(days: 2, hours: 12)),
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
      scheduledAt: DateTime.now().add(Duration(hours: 5)),
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
      scheduledAt: DateTime.now().add(Duration(days: 3)),
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
      scheduledAt: DateTime.now().subtract(Duration(hours: 2)),
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
      scheduledAt: DateTime.now().subtract(Duration(days: 3)),
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
      scheduledAt: DateTime.now().subtract(Duration(days: 4)),
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
      scheduledAt: DateTime.now().add(Duration(days: 4, hours: 14)),
      status: BookingStatus.pending,
      price: 600.0,
      description: 'Install new light fixtures',
    ));
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
        name: 'Laundry & Dry Cleaning',
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
        name: 'Emergency Services',
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
    return const [
      ServiceProvider(
        id: 'provider1',
        name: 'Rahim Technician',
        rating: 4.5,
        isVerified: true,
        services: ['pipe-repair', 'drain-clean', 'toilet-fix', 'deep-clean', 'carpet-clean', 'sofa-clean', 'wall-paint', 'wood-polish', 'texture-paint'],
        description: 'Five years experienced skilled plumber and cleaner. Ensure fast and reliable service.',
      ),
      ServiceProvider(
        id: 'provider2',
        name: 'Aman Electric',
        rating: 4.0,
        isVerified: false,
        services: ['wiring-fix', 'light-fix', 'circuit-break'],
        description: 'Electrical specialist. Capable of solving any complex wiring problems in home or office.',
      ),
      ServiceProvider(
        id: 'provider3',
        name: 'Shine Cleaners',
        rating: 4.8,
        isVerified: true,
        services: ['deep-clean', 'carpet-clean', 'sofa-clean'],
        description: 'We deeply clean your home or office by making it germ-free.',
      ),
      ServiceProvider(
        id: 'provider4',
        name: 'Paint Master',
        rating: 3.9,
        isVerified: true,
        services: ['wall-paint', 'wood-polish', 'texture-paint'],
        description: 'Professional painting service. Give new life to your walls.',
      ),
      ServiceProvider(
        id: 'provider5',
        name: 'Cool Tech',
        rating: 4.2,
        isVerified: false,
        services: ['ac-install', 'ac-service', 'gas-refill'],
        description: 'Contact for all types of AC installation, servicing and quick repairs.',
      ),
    ];
  }

  static ServiceProvider getProviderById(String providerId) {
    return getProviders().firstWhere(
      (p) => p.id == providerId,
      orElse: () => const ServiceProvider(
        id: 'error',
        name: 'Provider Not Found',
        rating: 0.0,
        isVerified: false,
        services: [],
        description: 'The requested provider could not be found.',
      ),
    );
  }

  // ==============================
  // Initialize All Data
  // ==============================
  static void initializeAllData() {
    initDummyBookings();
    initDummyMessages();
    print('DEBUG: DummyData initialized with ${_bookings.length} bookings and ${_messages.length} messages');
  }
}