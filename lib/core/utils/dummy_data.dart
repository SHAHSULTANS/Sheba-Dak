import 'package:uuid/uuid.dart'; // Uuid import
import '../../features/booking/domain/entities/booking_entity.dart';
import '../../features/auth/domain/entities/user_entity.dart'; // imported
import '../../features/home/domain/entities/service_category.dart';
import '../../features/home/domain/entities/service.dart';
// Import the new provider entity
import '../../features/provider/domain/entities/service_provider.dart';
// Import the provider application entity
import '../../../features/provider/domain/entities/provider_application.dart';
import '../../features/chat/domain/entities/chat_message.dart';

class DummyData {

  //chat message week 6.
  static List<ChatMessage> _messages = [];

  static void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  static List<ChatMessage> getMessagesByBooking(String bookingId) {
    return _messages
        .where((m) => m.bookingId == bookingId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));  // Sort by time.
  }


  // ==============================
  // Store for pending provider applications (Week 16)
  // ==============================
  static final List<ProviderApplication> _applications = [];

  /// Add new application for admin review
  static void addProviderApplication(ProviderApplication application) {
    _applications.add(application);
    print(
        'DEBUG: New Provider Application Added: ${application.name} (Total: ${_applications.length})');
  }

  /// Pending applications list for admin panel
  static List<ProviderApplication> getPendingApplications() {
    return List.unmodifiable(_applications);
  }

  // ==============================
  // Store for Bookings (Week 6 Foundation)
  // ==============================
  static final List<BookingEntity> _bookings = [];

  /// Add new booking
  static void addBooking(BookingEntity booking) {
    _bookings.add(booking);
    print(
        'DEBUG: New Booking Added: ${booking.id} for Customer ${booking.customerId}');
  }

  /// Get bookings by provider
  static List<BookingEntity> getBookingsByProvider(String providerId) {
    return _bookings.where((b) => b.providerId == providerId).toList();
  }


      /// Get bookings by customer (Upcoming first)
    static List<BookingEntity> getBookingsByCustomer(String customerId) {
      return _bookings
          .where((b) => b.customerId == customerId)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    // UPDATED: Both 'pending' and 'paymentPending' bookings are now considered as incoming requests
    static List<BookingEntity> getPendingBookingsByProvider(String providerId) {
      return _bookings
          .where((b) =>
              b.providerId == providerId &&
              (b.status == BookingStatus.pending ||
                b.status == BookingStatus.paymentPending)) // <-- UPDATED
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));  // Sort by date.
    }
  // Internal access for ApiClient (mutable list)
  static List<BookingEntity> getInternalBookingsList() => _bookings;


  // UPDATED: Dummy data includes new status
  static void initDummyBookings() {
        // Booking 1: Pending (Default for testing)
        addBooking(BookingEntity(
          id: 'booking1',
          customerId: 'customer1',
          providerId: 'provider1', // Match with ApiClient user.id
          serviceCategory: 'plumbing',
          scheduledAt: DateTime.now().add(Duration(days: 1, hours: 10)),
          status: BookingStatus.pending,
          price: 500.0,
          description: 'Dummy Plumbing Booking (Pending)',
        ));
        // Booking 2: Payment Pending (New status for testing)
        addBooking(BookingEntity(
          id: 'booking2',
          customerId: 'customer2',
          providerId: 'provider1',
          serviceCategory: 'electrical',
          scheduledAt: DateTime.now().add(Duration(days: 2, hours: 12)),
          status: BookingStatus.paymentPending, // <-- UPDATED
          price: 800.0,
          description: 'Dummy Electrical Booking (Payment Pending)',
        ));
        // Booking 3: Confirmed (For Confirmed Bookings Page)
        addBooking(BookingEntity(
          id: 'booking3',
          customerId: 'customer3',
          providerId: 'provider1',
          serviceCategory: 'cleaning',
          scheduledAt: DateTime.now().add(Duration(hours: 5)),
          status: BookingStatus.confirmed, // <-- Added confirmed booking
          price: 1500.0,
          description: 'Dummy Confirmed Cleaning Booking (Today)',
        ));
      }

  // ==============================
  // Existing Service & Provider Data
  // ==============================

  // --- PRIVATE LIST: Single source of truth for all services ---
  static const List<Service> _allServices = [
    // Plumbing Services (3)
    Service(
        id: 'pipe-repair',
        categoryId: 'plumbing',
        name: 'Pipe Repair',
        description: 'Fix leaking pipes and ensure waterproofing.',
        price: 500.0,
        providerName: 'Rahim Technician'),
    Service(
        id: 'drain-clean',
        categoryId: 'plumbing',
        name: 'Drain Cleaning',
        description: 'Clean blocked drains with quick machine solutions.',
        price: 300.0,
        providerName: 'Karim Plumber'),
    Service(
        id: 'toilet-fix',
        categoryId: 'plumbing',
        name: 'Toilet Fix',
        description: 'Repair toilet flushing and install new parts.',
        price: 450.0,
        providerName: 'Shafiq Service'),
    // Electrical Services (3)
    Service(
        id: 'wiring-fix',
        categoryId: 'electrical',
        name: 'Wiring Repair',
        description: 'Solve home or office wiring problems, fix short circuits.',
        price: 600.0,
        providerName: 'Aman Electric'),
    Service(
        id: 'light-fix',
        categoryId: 'electrical',
        name: 'Light Fixture Install',
        description: 'Install and repair lights, fans, or switches.',
        price: 200.0,
        providerName: 'Bidhut Service'),
    Service(
        id: 'circuit-break',
        categoryId: 'electrical',
        name: 'Circuit Breaker Fix',
        description: 'Repair faulty circuit breakers and new installations.',
        price: 750.0,
        providerName: 'Electro Solution'),
    // Cleaning Services (3)
    Service(
        id: 'deep-clean',
        categoryId: 'cleaning',
        name: 'Deep Cleaning',
        description: 'Deep clean entire home with special kitchen and bathroom care.',
        price: 2500.0,
        providerName: 'Shine Cleaners'),
    Service(
        id: 'carpet-clean',
        categoryId: 'cleaning',
        name: 'Carpet Cleaning',
        description: 'Professional carpet washing and steam cleaning service.',
        price: 800.0,
        providerName: 'Clean and Care'),
    Service(
        id: 'sofa-clean',
        categoryId: 'cleaning',
        name: 'Sofa Cleaning',
        description: 'Clean sofas and furniture with fabric and leather care service.',
        price: 1000.0,
        providerName: 'Furniture Shine'),
    // Painting Services (3)
    Service(
        id: 'wall-paint',
        categoryId: 'painting',
        name: 'Wall Painting',
        description: 'Painting and finishing with premium quality paint.',
        price: 800.0,
        providerName: 'Paint Master'),
    Service(
        id: 'wood-polish',
        categoryId: 'painting',
        name: 'Wood Polish',
        description: 'Varnish and polish wooden furniture for lasting gloss.',
        price: 950.0,
        providerName: 'Glory Paint'),
    Service(
        id: 'texture-paint',
        categoryId: 'painting',
        name: 'Texture Paint',
        description: 'Modern texture painting with expert designer consultation.',
        price: 1500.0,
        providerName: 'Art Home'),
    // Movers & Emergency
    Service(
        id: 'home-move',
        categoryId: 'movers',
        name: 'Home Moving',
        description: 'Complete home relocation service',
        price: 8000.0,
        providerName: 'Movers BD'),
    Service(
        id: 'ambulance',
        categoryId: 'emergency',
        name: 'Ambulance',
        description: 'Emergency medical service',
        price: 1000.0,
        providerName: 'Emergency Response'),
  ];

  // --- Existing getServiceCategories (No change needed) ---
  static List<ServiceCategory> getServiceCategories() {
    return const [
      ServiceCategory(
          id: 'plumbing',
          name: 'Plumbing',
          iconPath: 'assets/icons/plumbing.png',
          description: 'Pipe leaks, drain blocks etc'),
      ServiceCategory(
          id: 'electrical',
          name: 'Electrical',
          iconPath: 'assets/icons/electrical.png',
          description: 'Wiring, light fixtures etc'),
      ServiceCategory(
          id: 'cleaning',
          name: 'Cleaning',
          iconPath: 'assets/icons/cleaning.png',
          description: 'Home, office, car cleaning'),
      ServiceCategory(
          id: 'painting',
          name: 'Painting',
          iconPath: 'assets/icons/painting.png',
          description: 'Home or office wall painting'),
      ServiceCategory(
          id: 'carpentry',
          name: 'Carpentry',
          iconPath: 'assets/icons/carpentry.png',
          description: 'Furniture making and repair'),
      ServiceCategory(
          id: 'ac_repair',
          name: 'AC Repair',
          iconPath: 'assets/icons/ac_repair.png',
          description: 'AC installation and repair'),
      ServiceCategory(
          id: 'appliances',
          name: 'Appliance Repair',
          iconPath: 'assets/icons/appliances.png',
          description: 'Fridge, TV, washing machine repair'),
      ServiceCategory(
          id: 'pest_control',
          name: 'Pest Control',
          iconPath: 'assets/icons/pest_control.png',
          description: 'Cockroach, rat, ant control'),
      ServiceCategory(
          id: 'laundry',
          name: 'Laundry & Dry Cleaning',
          iconPath: 'assets/icons/laundry.png',
          description: 'Clothes washing and ironing'),
      ServiceCategory(
          id: 'beauty',
          name: 'Beauty Services',
          iconPath: 'assets/icons/beauty.png',
          description: 'Home beauty care'),
      ServiceCategory(
          id: 'car_wash',
          name: 'Car Wash',
          iconPath: 'assets/icons/car_wash.png',
          description: 'Car washing at home or office'),
      ServiceCategory(
          id: 'gardening',
          name: 'Gardening',
          iconPath: 'assets/icons/gardening.png',
          description: 'Planting and plant care in pots'),
      ServiceCategory(
          id: 'photography',
          name: 'Photography',
          iconPath: 'assets/icons/photography.png',
          description: 'Photographer for events'),
      ServiceCategory(
          id: 'movers',
          name: 'Home Moving',
          iconPath: 'assets/icons/movers.png',
          description: 'Home or office relocation service'),
      ServiceCategory(
          id: 'emergency',
          name: 'Emergency Services',
          iconPath: 'assets/icons/emergency.png',
          description: 'Ambulance, fire service etc'),
    ];
  }

  // --- Existing getServices ---
  static List<Service> getServices(String categoryId) {
    if (categoryId.isEmpty) {
      return _allServices;
    }
    return _allServices
        .where((service) => service.categoryId == categoryId)
        .toList();
  }

  // --- Existing getServiceById ---
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

  // --- NEW FIX: Dedicated method to find a single provider by ID ---
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

  // --- NEW METHOD: List of Service Providers ---
  static List<ServiceProvider> getProviders() {
    return const [
      ServiceProvider(
        id: 'provider1',
        name: 'Rahim Technician',
        rating: 4.5,
        isVerified: true,
        services: ['pipe-repair', 'drain-clean', 'toilet-fix'], // Plumbing
        description: 'Five years experienced skilled plumber. Ensure fast and reliable service.',
      ),
      ServiceProvider(
        id: 'provider2',
        name: 'Aman Electric',
        rating: 4.0,
        isVerified: false,
        services: ['wiring-fix', 'light-fix', 'circuit-break'], // Electrical
        description: 'Electrical specialist. Capable of solving any complex wiring problems in home or office.',
      ),
      ServiceProvider(
        id: 'provider3',
        name: 'Shine Cleaners',
        rating: 4.8,
        isVerified: true,
        services: ['deep-clean', 'carpet-clean'], // Cleaning
        description: 'We deeply clean your home or office by making it germ-free.',
      ),
      ServiceProvider(
        id: 'provider4',
        name: 'Paint Master',
        rating: 3.9,
        isVerified: true,
        services: ['wall-paint', 'texture-paint'], // Painting
        description: 'Professional painting service. Give new life to your walls.',
      ),
      ServiceProvider(
        id: 'provider5',
        name: 'Cool Tech',
        rating: 4.2,
        isVerified: false,
        services: ['ac-install', 'ac-service', 'gas-refill'], // AC Repair
        description: 'Contact for all types of AC installation, servicing and quick repairs.',
      ),
    ];
  }
}