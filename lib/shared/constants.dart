// lib/shared/constants.dart
class AppConstants {
  static const List<String> googleScopes = ['openid', 'email', 'profile'];
  static const String appName = 'sweetxeet'; // Add app name here
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.data,
  });
}

class EmailAlreadyExistsException implements Exception {
  const EmailAlreadyExistsException();
}