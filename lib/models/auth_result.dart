import 'user_profile.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? accessToken;
  final UserProfile? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.accessToken,
    this.user,
  });

  factory AuthResult.success(
      {required String accessToken, required UserProfile user}) {
    return AuthResult(
      success: true,
      accessToken: accessToken,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      errorMessage: message,
    );
  }
}
