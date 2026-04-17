/// Utility functions for phone number handling
class PhoneUtils {
  PhoneUtils._();

  /// Normalizes a phone number by stripping spaces and dashes
  static String normalize(String number) {
    return number.replaceAll(RegExp(r'[\s\-()]'), '');
  }

  /// Checks if two phone numbers match (accounts for different formats)
  static bool numbersMatch(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    if (na == nb) return true;
    // Check if one is a suffix of the other (e.g. +91 prefix)
    if (na.length >= 10 && nb.length >= 10) {
      return na.endsWith(nb.substring(nb.length - 10)) ||
          nb.endsWith(na.substring(na.length - 10));
    }
    return false;
  }

  /// Validates if the string is a plausible phone number
  static bool isValid(String number) {
    final cleaned = normalize(number);
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned);
  }

  /// Returns a display-friendly version of the number
  static String display(String number) {
    final n = normalize(number);
    if (n.startsWith('+')) return n;
    return n;
  }
}
