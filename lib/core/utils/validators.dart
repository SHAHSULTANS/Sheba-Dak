class Validators {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'ফোন নম্বর প্রয়োজন'; // Phone number required in Bangla.
    }
    // Corrected regex for Bangladesh phone numbers,
    // handling both '01' and '+8801' formats.
    final regex = RegExp(r'^(01|\+8801)[3-9]\d{8}$'); 
    if (!regex.hasMatch(value)) {
      return 'অবৈধ ফোন নম্বর ফর্ম্যাট'; // Invalid format in Bangla.
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional, so no error for empty value.
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'অবৈধ ইমেইল ফর্ম্যাট'; // Invalid email format in Bangla.
    }
    return null;
  }
}