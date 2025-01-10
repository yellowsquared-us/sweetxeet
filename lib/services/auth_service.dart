import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sweetxeet/shared/constants.dart';
import '../config/environment.dart';
import 'api_service.dart';
import 'token_manager.dart';
import '../models/auth_result.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  final TokenManager _tokenManager = TokenManager();
  String get appName => AppConstants.appName;
  String get baseUrl => Environment.apiBaseUrl;

  AuthService._internal() {
    _tokenManager.initialize();
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenManager.getAccessToken();
    return token != null;
  }

  Future<void> logout() async {
    await _tokenManager.clearTokens();
    await storage.delete(key: 'user_email');
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (kDebugMode) {
        print('Register response status: ${response.statusCode}');
        print('Register response body: ${response.body}');
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['access_token'] != null) {
          await _tokenManager.setTokens(
            responseData['access_token'],
            refreshToken: responseData['refresh_token'],
          );
          return AuthResult(
            success: true,
            accessToken: responseData['access_token'],
            data: responseData,
          );
        } else {
          return AuthResult(
            success: false,
            errorMessage: 'No access token in response',
          );
        }
      } else {
        final errorMessage = responseData['detail'] ?? 'Registration failed';
        if (errorMessage.toLowerCase().contains('email already registered') ||
            response.statusCode == 409) {
          return AuthResult(
            success: false,
            errorMessage: 'Email already registered',
          );
        }
        return AuthResult(
          success: false,
          errorMessage: errorMessage,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during registration: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (kDebugMode) {
        print('Login response status: ${response.statusCode}');
        print('Login response body: ${response.body}');
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['access_token'] != null) {
          await _tokenManager.setTokens(
            responseData['access_token'],
            refreshToken: responseData['refresh_token'],
          );
          return AuthResult(
            success: true,
            accessToken: responseData['access_token'],
            data: responseData,
          );
        } else {
          return AuthResult(
            success: false,
            errorMessage: 'No access token in response',
          );
        }
      } else {
        return AuthResult(
          success: false,
          errorMessage: responseData['detail'] ?? 'Login failed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> requestPasswordReset(String email) async {
    try {
      if (kDebugMode) {
        print('Requesting password reset for: $email');
      }
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request_password_reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'app': appName,
        }),
      );
      if (kDebugMode) {
        print('Password reset request response status: ${response.statusCode}');
        print('Password reset request response body: ${response.body}');
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      } else {
        return AuthResult(
          success: false,
          errorMessage:
              responseData['detail'] ?? 'Failed to request password reset',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during password reset request: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<void> saveAuthData(String accessToken, {String? refreshToken}) async {
    await _tokenManager.setTokens(accessToken, refreshToken: refreshToken);
  }

  Future<AuthResult> verifyResetCode(String email, String resetCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify_reset_code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'reset_code': resetCode,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: responseData['valid'] ?? false,
          errorMessage: responseData['valid'] ? null : 'Invalid reset code',
        );
      } else {
        return AuthResult(
          success: false,
          errorMessage: responseData['detail'] ?? 'Failed to verify reset code',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> resetPasswordWithCode(
    String email,
    String resetCode,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset_password_with_code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'reset_code': resetCode,
          'new_password': newPassword,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      } else {
        return AuthResult(
          success: false,
          errorMessage: responseData['detail'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }
}
