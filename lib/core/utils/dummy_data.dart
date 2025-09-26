import '../../features/home/domain/entities/service_category.dart';
import '../../features/home/domain/entities/service.dart'; 
// Import the new provider entity
import '../../features/provider/domain/entities/service_provider.dart'; 

class DummyData {
  // --- PRIVATE LIST: Single source of truth for all services (essential for getServiceById) ---
  static const List<Service> _allServices = [
    // Plumbing Services (3)
    Service(id: 'pipe-repair', categoryId: 'plumbing', name: 'পাইপ মেরামত', description: 'লিকিং পাইপ ফিক্স করুন এবং ওয়াটারপ্রুফিং নিশ্চিত করুন।', price: 500.0, providerName: 'রহিম টেকনিশিয়ান'),
    Service(id: 'drain-clean', categoryId: 'plumbing', name: 'ড্রেন ক্লিনিং', description: 'ব্লকড ড্রেন পরিষ্কার করুন, যন্ত্রের মাধ্যমে দ্রুত সমাধান।', price: 300.0, providerName: 'করিম প্লাম্বার'),
    Service(id: 'toilet-fix', categoryId: 'plumbing', name: 'টয়লেট ফিক্স', description: 'টয়লেটের ফ্লাশিং মেরামত এবং নতুন পার্টস ইনস্টলেশন।', price: 450.0, providerName: 'শফিক সার্ভিস'),
    // Electrical Services (3)
    Service(id: 'wiring-fix', categoryId: 'electrical', name: 'ওয়্যারিং মেরামত', description: 'বাসা বা অফিসের ওয়্যারিং সমস্যা সমাধান, শর্ট সার্কিট ফিক্সিং।', price: 600.0, providerName: 'আমান ইলেকট্রিক'),
    Service(id: 'light-fix', categoryId: 'electrical', name: 'লাইট ফিক্সচার ইনস্টল', description: 'লাইট, ফ্যান, বা সুইচ লাগানো এবং মেরামত।', price: 200.0, providerName: 'বিদ্যুৎ সেবা'),
    Service(id: 'circuit-break', categoryId: 'electrical', name: 'সার্কিট ব্রেকার ফিক্স', description: 'ত্রুটিপূর্ণ সার্কিট ব্রেকার মেরামত ও নতুন ইনস্টলেশন।', price: 750.0, providerName: 'ইলেক্ট্রো সল্যুশন'),
    // Cleaning Services (3)
    Service(id: 'deep-clean', categoryId: 'cleaning', name: 'ডিপ ক্লিনিং', description: 'সম্পূর্ণ বাসার গভীরভাবে পরিষ্কার, কিচেন ও বাথরুম বিশেষ যত্ন।', price: 2500.0, providerName: 'শাইন ক্লিনার্স'),
    Service(id: 'carpet-clean', categoryId: 'cleaning', name: 'কার্পেট ক্লিনিং', description: 'পেশাদার কার্পেট ধোয়া এবং স্টীম ক্লিনিং সার্ভিস।', price: 800.0, providerName: 'ক্লিন অ্যান্ড কেয়ার'),
    Service(id: 'sofa-clean', categoryId: 'cleaning', name: 'সোফা ক্লিনিং', description: 'সোফা ও আসবাবপত্র পরিষ্কার, ফেব্রিক ও লেদার যত্নের সার্ভিস।', price: 1000.0, providerName: 'ফার্নিচার শাইন'),
    // Painting Services (3)
    Service(id: 'wall-paint', categoryId: 'painting', name: 'দেয়াল পেইন্টিং', description: 'রং করা ও ফিনিশিং, প্রিমিয়াম কোয়ালিটির রং ব্যবহার।', price: 800.0, providerName: 'পেইন্ট মাষ্টার'),
    Service(id: 'wood-polish', categoryId: 'painting', name: 'কাঠের পলিশ', description: 'কাঠের আসবাবে বার্নিশ ও পলিশ, দীর্ঘস্থায়ী গ্লস।', price: 950.0, providerName: 'গ্লোরি পেইন্ট'),
    Service(id: 'texture-paint', categoryId: 'painting', name: 'টেক্সচার পেইন্ট', description: 'আধুনিক টেক্সচার পেইন্টিং, বিশেষজ্ঞ ডিজাইনারের পরামর্শ।', price: 1500.0, providerName: 'আর্ট হোম'),
    // ... (rest of 45+ services here) ...
    Service(id: 'home-move', categoryId: 'movers', name: 'বাসা বদল', description: 'সম্পূর্ণ বাসা স্থানান্তরের সেবা', price: 8000.0, providerName: 'মুভার্স বিডি'),
    // Service(id: 'office-move', categoryId: 'movers', name: 'অফিসের সরঞ্জাম স্থানান্তরের সেবা', price: 12000.0, providerName: 'কুইক শিফট'),
    Service(id: 'ambulance', categoryId: 'emergency', name: 'অ্যাম্বুলেন্স', description: 'জরুরী চিকিত্সা সেবা', price: 1000.0, providerName: 'ইমার্জেন্সি রেসপন্স'),
  ];
  
  // --- Existing getServiceCategories (No change needed) ---
  static List<ServiceCategory> getServiceCategories() {
    // ... (your 15 categories here) ...
    return const [
      // ... (all 15 categories) ...
      ServiceCategory(id: 'plumbing', name: 'প্লাম্বিং', iconPath: 'assets/icons/plumbing.png', description: 'পাইপ লিক, ড্রেন ব্লক ইত্যাদি'),
      ServiceCategory(id: 'electrical', name: 'বিদ্যুৎ', iconPath: 'assets/icons/electrical.png', description: 'ওয়্যারিং, লাইট ফিক্সচার ইত্যাদি'),
      ServiceCategory(id: 'cleaning', name: 'পরিষ্কার-পরিচ্ছন্নতা', iconPath: 'assets/icons/cleaning.png', description: 'বাসা, অফিস, গাড়ি পরিষ্কার'),
      ServiceCategory(id: 'painting', name: 'পেইন্টিং', iconPath: 'assets/icons/painting.png', description: 'বাসা বা অফিসের দেয়াল পেইন্টিং'),
      ServiceCategory(id: 'carpentry', name: 'কাঠের কাজ', iconPath: 'assets/icons/carpentry.png', description: 'ফার্নিচার তৈরি ও মেরামত'),
      ServiceCategory(id: 'ac_repair', name: 'এসি মেরামত', iconPath: 'assets/icons/ac_repair.png', description: 'এসি ইনস্টলেশন ও মেরামত'),
      ServiceCategory(id: 'appliances', name: 'অ্যাপ্লায়েন্স মেরামত', iconPath: 'assets/icons/appliances.png', description: 'ফ্রিজ, টিভি, ওয়াশিং মেশিন মেরামত'),
      ServiceCategory(id: 'pest_control', name: 'পোকামাকড় নিয়ন্ত্রণ', iconPath: 'assets/icons/pest_control.png', description: 'তেলাপোকা, ইঁদুর, পিঁপড়া দমন'),
      ServiceCategory(id: 'laundry', name: 'লন্ড্রি ও ড্রাই ক্লিনিং', iconPath: 'assets/icons/laundry.png', description: 'কাপড় ধোয়া ও ইস্ত্রি'),
      ServiceCategory(id: 'beauty', name: 'সৌন্দর্য সেবা', iconPath: 'assets/icons/beauty.png', description: 'ঘরে বসে রূপচর্চা'),
      ServiceCategory(id: 'car_wash', name: 'গাড়ি ধোয়া', iconPath: 'assets/icons/car_wash.png', description: 'বাসা বা অফিসের সামনে গাড়ি ধোয়া'),
      ServiceCategory(id: 'gardening', name: 'বাগান করা', iconPath: 'assets/icons/gardening.png', description: 'টবে গাছ লাগানো ও পরিচর্যা'),
      ServiceCategory(id: 'photography', name: 'ফটোগ্রাফি', iconPath: 'assets/icons/photography.png', description: 'অনুষ্ঠান বা ইভেন্টের জন্য ফটোগ্রাফার'),
      ServiceCategory(id: 'movers', name: 'বাসা বদল', iconPath: 'assets/icons/movers.png', description: 'বাসা বা অফিসের জিনিসপত্র স্থানান্তরের সেবা'),
      ServiceCategory(id: 'emergency', name: 'জরুরী সেবা', iconPath: 'assets/icons/emergency.png', description: 'অ্যাম্বুলেন্স, ফায়ার সার্ভিস ইত্যাদি'),
    ];
  }

  // --- Existing getServices ---
  static List<Service> getServices(String categoryId) {
    if (categoryId.isEmpty) {
      return _allServices;
    }
    return _allServices.where((service) => service.categoryId == categoryId).toList();
  }

  // --- Existing getServiceById ---
  static Service getServiceById(String serviceId) {
    return _allServices.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => const Service(
        id: 'error',
        categoryId: '',
        name: 'সেবা পাওয়া যায়নি',
        description: 'অনুরোধ করা সেবাটি বর্তমানে পাওয়া যাচ্ছে না। অনুগ্রহ করে সার্ভিস লিস্টে ফিরে যান।',
        price: 0,
        providerName: 'N/A',
      ),
    );
  }

  // --- NEW FIX: Dedicated method to find a single service by ID ---
  static ServiceProvider getProviderById(String providerId) {
      return getProviders().firstWhere(
        (p) => p.id == providerId,
        orElse: () => const ServiceProvider(
          id: 'error',
          name: 'প্রোভাইডার পাওয়া যায়নি',
          rating: 0.0,
          isVerified: false,
          services: [],
          description: 'অনুরোধ করা প্রোভাইডারকে খুঁজে পাওয়া যায়নি।',
        ),
      );
  }

  // --- NEW METHOD: List of Service Providers ---
  static List<ServiceProvider> getProviders() {
    return const [
      ServiceProvider(
        id: 'provider1',
        name: 'রহিম টেকনিশিয়ান',
        rating: 4.5,
        isVerified: true,
        services: ['pipe-repair', 'drain-clean', 'toilet-fix'], // Plumbing
        description: 'পাঁচ বছরের অভিজ্ঞতাসম্পন্ন দক্ষ প্লাম্বার। দ্রুত ও নির্ভরযোগ্য সেবা নিশ্চিত করি।',
      ),
      ServiceProvider(
        id: 'provider2',
        name: 'আমান ইলেকট্রিক',
        rating: 4.0,
        isVerified: false,
        services: ['wiring-fix', 'light-fix', 'circuit-break'], // Electrical
        description: 'বিদ্যুৎ বিশেষজ্ঞ। বাসা বা অফিসের যেকোনো জটিল ওয়্যারিং সমস্যা সমাধানে সক্ষম।',
      ),
      ServiceProvider(
        id: 'provider3',
        name: 'শাইন ক্লিনার্স',
        rating: 4.8,
        isVerified: true,
        services: ['deep-clean', 'carpet-clean'], // Cleaning
        description: 'আমরা আপনার বাসা বা অফিসকে জীবাণুমুক্ত করে গভীরভাবে পরিষ্কার করি।',
      ),
      ServiceProvider(
        id: 'provider4',
        name: 'পেইন্ট মাষ্টার',
        rating: 3.9,
        isVerified: true,
        services: ['wall-paint', 'texture-paint'], // Painting
        description: 'পেশাদার পেইন্টিং সার্ভিস। আপনার দেয়ালকে নতুন জীবন দিন।',
      ),
      ServiceProvider(
        id: 'provider5',
        name: 'কুল টেক',
        rating: 4.2,
        isVerified: false,
        services: ['ac-install', 'ac-service', 'gas-refill'], // AC Repair
        description: 'সব ধরনের এসি ইনস্টলেশন, সার্ভিসিং এবং দ্রুত মেরামতের জন্য যোগাযোগ করুন।',
      ),
    ];
  }
}