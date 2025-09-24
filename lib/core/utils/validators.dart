class Validators {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'ফোন নম্বর প্রয়োজন';  // Phone number required in Bangla.
    }
    final regex = RegExp(r'^\01[3-9]\d{8}$');  // Bangladesh format: +8801X-XXXXXXX.
    if (!regex.hasMatch(value)) {
      return 'অবৈধ ফোন নম্বর ফর্ম্যাট';  // Invalid format in Bangla.
    }
    return null;
  }
}