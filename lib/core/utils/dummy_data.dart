import '../../features/home/domain/entities/service_category.dart';

class DummyData {
  static List<ServiceCategory> getServiceCategories() {
    return [
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
      // ServiceCategory(
      //   id: 'painting',
      //   name: 'পেইন্টিং',
      //   iconPath: 'assets/icons/painting.png',
      //   description: 'বাসা বা অফিসের দেয়াল পেইন্টিং',
      // ),
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
      // ServiceCategory(
      //   id: 'pest_control',
      //   name: 'পোকামাকড় নিয়ন্ত্রণ',
      //   iconPath: 'assets/icons/pest_control.png',
      //   description: 'তেলাপোকা, ইঁদুর, পিঁপড়া দমন',
      // ),
      // ServiceCategory(
      //   id: 'laundry',
      //   name: 'লন্ড্রি ও ড্রাই ক্লিনিং',
      //   iconPath: 'assets/icons/laundry.png',
      //   description: 'কাপড় ধোয়া ও ইস্ত্রি',
      // ),
      // ServiceCategory(
      //   id: 'beauty',
      //   name: 'সৌন্দর্য সেবা',
      //   iconPath: 'assets/icons/beauty.png',
      //   description: 'ঘরে বসে রূপচর্চা',
      // ),
      ServiceCategory(
        id: 'car_wash',
        name: 'গাড়ি ধোয়া',
        iconPath: 'assets/icons/car_wash.png',
        description: 'বাসা বা অফিসের সামনে গাড়ি ধোয়া',
      ),
      // ServiceCategory(
      //   id: 'gardening',
      //   name: 'বাগান করা',
      //   iconPath: 'assets/icons/gardening.png',
      //   description: 'টবে গাছ লাগানো ও পরিচর্যা',
      // ),
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
}