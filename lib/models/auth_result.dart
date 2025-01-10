import 'user_profile.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? accessToken;
  final UserProfile? user;
  final Map<String, dynamic>? data;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.accessToken,
    this.user,
    this.data,
  });

  factory AuthResult.success({
    String? accessToken,
    UserProfile? user,
    Map<String, dynamic>? data,
  }) {
    return AuthResult(
      success: true,
      accessToken: accessToken,
      user: user,
      data: data,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      errorMessage: message,
    );
  }
}