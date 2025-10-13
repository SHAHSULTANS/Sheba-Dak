class Validators {
  static String? requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'এই ঘরটি পূরণ করা প্রয়োজন';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'ফোন নম্বর প্রয়োজন';
    }
    final regex = RegExp(r'^(01|\+8801)[3-9]\d{8}$');
    if (!regex.hasMatch(value)) {
      return 'অবৈধ ফোন নম্বর ফর্ম্যাট';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'অবৈধ ইমেইল ফর্ম্যাট';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'ঠিকানা প্রয়োজন';
    }
    if (value.length < 10) {
      return 'ঠিকানা কমপক্ষে ১০ অক্ষরের হতে হবে';
    }
    return null;
  }

  static String? postalCodeValidator(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final regex = RegExp(r'^\d{4}$'); // Bangladesh postal code
    return regex.hasMatch(value) ? null : 'Invalid postal code (e.g., 1200)';
  }

  static String? validateRequired(String? value, String message) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }
}
