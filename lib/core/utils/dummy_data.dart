import '../../features/home/domain/entities/service_category.dart';
import '../../features/home/domain/entities/service.dart'; 

class DummyData {
  // --- PRIVATE LIST: Single source of truth for all services ---
  // Moved the list here and made it private and final for efficiency and clean access.
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
    Service(id: 'carpet-clean', categoryId: 'cleaning', name: 'কার্পেট ক্লিনিং', description: 'পেশাদার কার্পেট ধোয়া এবং স্টীম ক্লিনিং সার্ভিস।', price: 800.0, providerName: 'ক্লিন অ্যান্ড কেয়ার'),
    Service(id: 'sofa-clean', categoryId: 'cleaning', name: 'সোফা ক্লিনিং', description: 'সোফা ও আসবাবপত্র পরিষ্কার, ফেব্রিক ও লেদার যত্নের সার্ভিস।', price: 1000.0, providerName: 'ফার্নিচার শাইন'),

    // Painting Services (3)
    Service(id: 'wall-paint', categoryId: 'painting', name: 'দেয়াল পেইন্টিং', description: 'রং করা ও ফিনিশিং, প্রিমিয়াম কোয়ালিটির রং ব্যবহার।', price: 800.0, providerName: 'পেইন্ট মাষ্টার'),
    Service(id: 'wood-polish', categoryId: 'painting', name: 'কাঠের পলিশ', description: 'কাঠের আসবাবে বার্নিশ ও পলিশ, দীর্ঘস্থায়ী গ্লস।', price: 950.0, providerName: 'গ্লোরি পেইন্ট'),
    Service(id: 'texture-paint', categoryId: 'painting', name: 'টেক্সচার পেইন্ট', description: 'আধুনিক টেক্সচার পেইন্টিং, বিশেষজ্ঞ ডিজাইনারের পরামর্শ।', price: 1500.0, providerName: 'আর্ট হোম'),
    
    // Carpentry Services (3)
    Service(id: 'table-make', categoryId: 'carpentry', name: 'টেবিল তৈরি', description: 'কাঠের কাস্টম টেবিল তৈরি', price: 4000.0, providerName: 'উডওয়ার্কস'),
    Service(id: 'door-fix', categoryId: 'carpentry', name: 'দরজা মেরামত', description: 'ভাঙা দরজা বা কপাট ফিক্স', price: 400.0, providerName: 'কারিগর সেবা'),
    Service(id: 'cabinet-install', categoryId: 'carpentry', name: 'কেবিনেট ইনস্টল', description: 'রান্নাঘরের কেবিনেট ইনস্টলেশন', price: 1800.0, providerName: 'ফার্নিচার গুরু'),
    
    // AC Repair Services (3)
    Service(id: 'ac-install', categoryId: 'ac_repair', name: 'এসি ইনস্টল', description: 'নতুন এসি ইনস্টলেশন সার্ভিস', price: 1200.0, providerName: 'কুল টেক'),
    Service(id: 'ac-service', categoryId: 'ac_repair', name: 'এসি সার্ভিসিং', description: 'এসি ডিপ ক্লিনিং ও সার্ভিস', price: 800.0, providerName: 'এসি মাস্টার'),
    Service(id: 'gas-refill', categoryId: 'ac_repair', name: 'গ্যাস রিফিল', description: 'এসির গ্যাস রিফিল করা', price: 1500.0, providerName: 'এসি সল্যুশন'),
    
    // Appliance Services (3)
    Service(id: 'fridge-repair', categoryId: 'appliances', name: 'ফ্রিজ মেরামত', description: 'ফ্রিজ বা ডিপ ফ্রিজ মেরামত', price: 700.0, providerName: 'হোম সার্ভিসেস'),
    Service(id: 'tv-repair', categoryId: 'appliances', name: 'টিভি মেরামত', description: 'LED/LCD টিভি ফিক্স', price: 900.0, providerName: 'টেক গুরু'),
    Service(id: 'wm-repair', categoryId: 'appliances', name: 'ওয়াশিং মেশিন মেরামত', description: 'ওয়াশিং মেশিন ফিক্স', price: 850.0, providerName: 'অ্যাপ্লায়েন্স ডক'),

    // Pest Control Services (3)
    Service(id: 'rat-control', categoryId: 'pest_control', name: 'ইঁদুর নিয়ন্ত্রণ', description: 'ইঁদুর ধরার ফাঁদ ও বিষ ব্যবহার', price: 1500.0, providerName: 'পেস্টিসাইড বিডি'),
    Service(id: 'cockroach-control', categoryId: 'pest_control', name: 'তেলাপোকা দমন', description: 'তেলাপোকা মারার স্প্রে ও জেল', price: 1200.0, providerName: 'পেস্টিসাইড বিডি'),
    Service(id: 'ant-control', categoryId: 'pest_control', name: 'পিঁপড়া নিয়ন্ত্রণ', description: 'পিঁপড়া মারার ওষুধ', price: 800.0, providerName: 'পেস্টিসাইড বিডি'),

    // Laundry Services (3)
    Service(id: 'wash-fold', categoryId: 'laundry', name: 'ওয়াশ ও ফোল্ড', description: 'কাপড় ধোয়া ও ভাঁজ করা', price: 150.0, providerName: 'দ্রুত ধোয়া'),
    Service(id: 'dry-clean', categoryId: 'laundry', name: 'ড্রাই ক্লিনিং', description: 'স্যুট ও বিশেষ কাপড় ড্রাই ক্লিনিং', price: 300.0, providerName: 'প্রিমিয়াম লন্ড্রি'),
    Service(id: 'ironing', categoryId: 'laundry', name: 'শুধুমাত্র ইস্ত্রি', description: 'কাপড় ইস্ত্রি করার সেবা', price: 50.0, providerName: 'আয়রন মাস্টার'),

    // Beauty Services (3)
    Service(id: 'facial', categoryId: 'beauty', name: 'ফেসিয়াল', description: 'স্কিন কেয়ার ও রূপচর্চা', price: 1200.0, providerName: 'বিউটি এক্সপার্ট'),
    Service(id: 'hair-cut', categoryId: 'beauty', name: 'পুরুষদের চুল কাটা', description: 'বাসায় এসে চুল কাটার সার্ভিস', price: 400.0, providerName: 'রূপ সজ্জা'),
    Service(id: 'pedicure', categoryId: 'beauty', name: 'পেডিকিউর ও ম্যানিকিউর', description: 'হাত ও পায়ের যত্ন', price: 800.0, providerName: 'হোম স্পা'),

    // Car Wash Services (3)
    Service(id: 'sedan-wash', categoryId: 'car_wash', name: 'সেডান ওয়াশ', description: 'ছোট গাড়ির সম্পূর্ণ ধোয়ার সার্ভিস', price: 400.0, providerName: 'ক্লিন কার'),
    Service(id: 'suv-wash', categoryId: 'car_wash', name: 'এসইউভি ওয়াশ', description: 'বড় গাড়ির ধোয়ার সার্ভিস', price: 550.0, providerName: 'কার কেয়ার'),
    Service(id: 'interior-clean', categoryId: 'car_wash', name: 'ইন্টেরিয়র ক্লিনিং', description: 'গাড়ির ভেতরের অংশ পরিষ্কার', price: 1000.0, providerName: 'ডিটেয়লিং প্রো'),

    // Gardening Services (3)
    Service(id: 'tree-trim', categoryId: 'gardening', name: 'গাছের ডাল ছাঁটা', description: 'ঝুঁকিপূর্ণ গাছের ডাল ছাঁটা', price: 900.0, providerName: 'গার্ডেন কেয়ার'),
    Service(id: 'plant-install', categoryId: 'gardening', name: 'গাছ লাগানো', description: 'নতুন গাছ ও টব ইনস্টল করা', price: 700.0, providerName: 'সবুজ সপন'),
    Service(id: 'soil-fertilize', categoryId: 'gardening', name: 'মাটি ও সার', description: 'টবে মাটি পরিবর্তন ও সার দেওয়া', price: 500.0, providerName: 'কৃষি সেবা'),

    // Photography Services (3)
    Service(id: 'event-photo', categoryId: 'photography', name: 'ইভেন্ট ফটোগ্রাফি', description: 'অনুষ্ঠানের জন্য পেশাদার ফটোগ্রাফার', price: 5000.0, providerName: 'ক্লিক প্রো'),
    Service(id: 'portrait-photo', categoryId: 'photography', name: 'পোর্ট্রেট ফটোগ্রাফি', description: 'ব্যক্তিগত বা ফ্যামিলি ফটোশুট', price: 3000.0, providerName: 'ফ্ল্যাশ স্টুডিও'),
    Service(id: 'wedding-photo', categoryId: 'photography', name: 'বিয়ে ফটোগ্রাফি', description: 'বিয়ে অনুষ্ঠানের প্যাকেজ', price: 15000.0, providerName: 'ওয়েডিং মেমরিজ'),

    // Movers Services (3)
    Service(id: 'home-move', categoryId: 'movers', name: 'বাসা বদল', description: 'সম্পূর্ণ বাসা স্থানান্তরের সেবা', price: 8000.0, providerName: 'মুভার্স বিডি'),
    // Service(id: 'office-move', categoryId: 'movers', name: 'অফিসের সরঞ্জাম স্থানান্তরের সেবা', price: 12000.0, providerName: 'কুইক শিফট'),
    Service(id: 'single-item-move', categoryId: 'movers', name: 'একক জিনিস স্থানান্তর', description: 'একটি বড় জিনিস (যেমন ফ্রিজ) স্থানান্তর', price: 2500.0, providerName: 'ট্রান্সপোর্ট সার্ভিস'),

    // Emergency Services (3)
    Service(id: 'ambulance', categoryId: 'emergency', name: 'অ্যাম্বুলেন্স', description: 'জরুরী চিকিত্সা সেবা', price: 1000.0, providerName: 'ইমার্জেন্সি রেসপন্স'),
    Service(id: 'fire-service', categoryId: 'emergency', name: 'ফায়ার সার্ভিস', description: 'জরুরী অগ্নি নির্বাপক সেবা', price: 0.0, providerName: 'ফায়ার রেসপন্স'),
    Service(id: 'roadside-help', categoryId: 'emergency', name: 'রোডসাইড সহায়তা', description: 'গাড়ির জন্য জরুরী সহায়তা', price: 1500.0, providerName: 'অটো এইড'),
  ];

  // --- List of all Service Categories (15+ items) ---
  static List<ServiceCategory> getServiceCategories() {
    return const [
      ServiceCategory(
        id: 'plumbing',
        name: 'প্লাম্বিং',
        iconPath: 'assets/icons/plumbing.png',
        description: 'পাইপ লিক, ড্রেন ব্লক ইত্যাদি',
      ),
      ServiceCategory(
        id: 'electrical',
        name: 'বিদ্যুৎ',
        iconPath: 'assets/icons/electrical.png',
        description: 'ওয়্যারিং, লাইট ফিক্সচার ইত্যাদি',
      ),
      ServiceCategory(
        id: 'cleaning',
        name: 'পরিষ্কার-পরিচ্ছন্নতা',
        iconPath: 'assets/icons/cleaning.png',
        description: 'বাসা, অফিস, গাড়ি পরিষ্কার',
      ),
      ServiceCategory(
        id: 'painting',
        name: 'পেইন্টিং',
        iconPath: 'assets/icons/painting.png',
        description: 'বাসা বা অফিসের দেয়াল পেইন্টিং',
      ),
      ServiceCategory(
        id: 'carpentry',
        name: 'কাঠের কাজ',
        iconPath: 'assets/icons/carpentry.png',
        description: 'ফার্নিচার তৈরি ও মেরামত',
      ),
      ServiceCategory(
        id: 'ac_repair',
        name: 'এসি মেরামত',
        iconPath: 'assets/icons/ac_repair.png',
        description: 'এসি ইনস্টলেশন ও মেরামত',
      ),
      ServiceCategory(
        id: 'appliances',
        name: 'অ্যাপ্লায়েন্স মেরামত',
        iconPath: 'assets/icons/appliances.png',
        description: 'ফ্রিজ, টিভি, ওয়াশিং মেশিন মেরামত',
      ),
      ServiceCategory(
        id: 'pest_control',
        name: 'পোকামাকড় নিয়ন্ত্রণ',
        iconPath: 'assets/icons/pest_control.png',
        description: 'তেলাপোকা, ইঁদুর, পিঁপড়া দমন',
      ),
      ServiceCategory(
        id: 'laundry',
        name: 'লন্ড্রি ও ড্রাই ক্লিনিং',
        iconPath: 'assets/icons/laundry.png',
        description: 'কাপড় ধোয়া ও ইস্ত্রি',
      ),
      ServiceCategory(
        id: 'beauty',
        name: 'সৌন্দর্য সেবা',
        iconPath: 'assets/icons/beauty.png',
        description: 'ঘরে বসে রূপচর্চা',
      ),
      ServiceCategory(
        id: 'car_wash',
        name: 'গাড়ি ধোয়া',
        iconPath: 'assets/icons/car_wash.png',
        description: 'বাসা বা অফিসের সামনে গাড়ি ধোয়া',
      ),
      ServiceCategory(
        id: 'gardening',
        name: 'বাগান করা',
        iconPath: 'assets/icons/gardening.png',
        description: 'টবে গাছ লাগানো ও পরিচর্যা',
      ),
      ServiceCategory(
        id: 'photography',
        name: 'ফটোগ্রাফি',
        iconPath: 'assets/icons/photography.png',
        description: 'অনুষ্ঠান বা ইভেন্টের জন্য ফটোগ্রাফার',
      ),
      ServiceCategory(
        id: 'movers',
        name: 'বাসা বদল',
        iconPath: 'assets/icons/movers.png',
        description: 'বাসা বা অফিসের জিনিসপত্র স্থানান্তরের সেবা',
      ),
      ServiceCategory(
        id: 'emergency',
        name: 'জরুরী সেবা',
        iconPath: 'assets/icons/emergency.png',
        description: 'অ্যাম্বুলেন্স, ফায়ার সার্ভিস ইত্যাদি',
      ),
    ];
  }

  // --- Updated getServices: Uses private list and handles empty categoryId ---
  static List<Service> getServices(String categoryId) {
    if (categoryId.isEmpty) {
      // Return ALL services if categoryId is empty (e.g., for global search or initial load)
      return _allServices; 
    }
    // Filter services based on the provided categoryId.
    return _allServices.where((service) => service.categoryId == categoryId).toList();
  }

  // --- NEW FIX: Dedicated method to find a single service by ID ---
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
}