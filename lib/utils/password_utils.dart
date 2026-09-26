/// Lightweight password hashing utility.
///
/// This project intentionally avoids adding an external crypto package so
/// the app keeps working with only the dependencies already declared in
/// pubspec.yaml. The hash below is a simple, deterministic mixing function
/// -- it keeps plain-text passwords out of the local SQLite database, but
/// it is NOT a cryptographically secure hash. Do not reuse this approach
/// for an application that stores real user credentials in production.
class PasswordUtils {
  static const int _seedA = 0x811C9DC5;
  static const int _seedB = 0x9E3779B9;
  static const int _mask32 = 0xFFFFFFFF;

  static String hash(String password) {
    int h1 = _seedA;
    int h2 = _seedB;

    for (final codeUnit in password.codeUnits) {
      h1 = (h1 ^ codeUnit) & _mask32;
      h1 = (h1 * 0x01000193) & _mask32;

      h2 = (h2 + codeUnit) & _mask32;
      h2 = ((h2 << 5) | (h2 >> 27)) & _mask32;
      h2 = (h2 ^ codeUnit) & _mask32;
    }

    final combined = (h1 ^ (h2 << 1)) & _mask32;

    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}'
        '${combined.toRadixString(16).padLeft(8, '0')}';
  }

  static bool matches(String password, String storedHash) {
    return hash(password) == storedHash;
  }
}
