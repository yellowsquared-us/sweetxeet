import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../shared/constants.dart';
import '../config/environment.dart'; // Ensure this import is correct
import 'api_service.dart'; // Import ApiService

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  final ApiService _apiService = ApiService(); // Initialize ApiService
  String get appName => AppConstants.appName; // Use constant here
  String get baseUrl => Environment.apiBaseUrl;

  AuthService._internal();

  Future<bool> isLoggedIn() async {
    final token = await _apiService.getAccessToken();
    return token != null;
  }

  Future<void> logout() async {
    await _apiService.storage.delete(key: 'access_token');
    await _apiService.storage.delete(key: 'refresh_token');
    await _apiService.storage.delete(key: 'user_email');
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
          'app': appName,
        }),
      );

      if (kDebugMode) {
        print('Register response status: ${response.statusCode}');
        print('Register response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          await _apiService.setAccessToken(data['access_token']);
          return AuthResult(success: true, data: data);
        } else {
          return AuthResult(
            success: false,
            errorMessage: 'No access token in response',
          );
        }
      } else {
        final error = json.decode(response.body);
        String message = error['detail'] ?? 'Registration failed';
        if (message.contains('Email already registered')) {
          throw const EmailAlreadyExistsException();
        }
        return AuthResult(success: false, errorMessage: message);
      }
    } catch (e) {
      if (e is EmailAlreadyExistsException) {
        rethrow;
      }
      if (kDebugMode) {
        print('Error during registration: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Registration failed: $e',
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
          'app': appName,
        }),
      );

      if (kDebugMode) {
        print('Login response status: ${response.statusCode}');
        print('Login response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          await _apiService.setAccessToken(data['access_token']);
          return AuthResult(
            success: true,
            data: data,
          );
        } else {
          return AuthResult(
            success: false,
            errorMessage: 'No access token in response',
          );
        }
      } else {
        final error = json.decode(response.body);
        String message = error['detail'] ?? 'Login failed';

        return AuthResult(
          success: false,
          errorMessage: message,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Login failed: $e',
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

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      } else {
        return AuthResult(
          success: false,
          errorMessage: data['detail'] ?? 'Failed to request password reset',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during password reset request: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Network error: $e',
      );
    }
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

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: data['valid'] ?? false,
          errorMessage: data['valid'] ? null : 'Invalid reset code',
        );
      } else {
        return AuthResult(
          success: false,
          errorMessage: data['detail'] ?? 'Failed to verify reset code',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error: $e',
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

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      } else {
        return AuthResult(
          success: false,
          errorMessage: data['detail'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error: $e',
      );
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    return await _apiService.resendVerificationEmail(email);
  }

  Future<void> saveAuthData(String accessToken, {String? refreshToken}) async {
    await _apiService.setAccessToken(accessToken);
    if (refreshToken != null) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
  }
}

class EmailAlreadyExistsException implements Exception {
  const EmailAlreadyExistsException();
  @override
  String toString() {
    return 'Email already exists';
  }
}
