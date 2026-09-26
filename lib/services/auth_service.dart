import 'database_service.dart';

/// Thin validation + orchestration layer over [DatabaseService] for
/// registration, login and logout. Keeping this separate from
/// DatabaseService mirrors the project's existing services/ convention
/// (one focused service per concern).
class AuthService {
  static final RegExp _emailPattern = RegExp(
    r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$',
  );

  static String? validateRegistration({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (name.trim().isEmpty) {
      return 'Please enter your full name.';
    }

    if (!_emailPattern.hasMatch(email.trim())) {
      return 'Please enter a valid email address.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return DatabaseService.registerUser(
      name: name,
      email: email,
      password: password,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Please enter both email and password.');
    }

    return DatabaseService.loginUser(email: email, password: password);
  }

  static Future<void> logout() => DatabaseService.logout();
}
