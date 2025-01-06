import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user_profile.dart';

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

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  final ApiService _apiService = ApiService();

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
        Uri.parse('${_apiService.baseUrl}/auth/register'),
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
        Uri.parse('${_apiService.baseUrl}/auth/login'),
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

      if (response.statusCode == 200) {
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
        return AuthResult(
          success: false,
          errorMessage: error['detail'] ?? 'Login failed',
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
        Uri.parse('${_apiService.baseUrl}/auth/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (kDebugMode) {
        print('Password reset request response status: ${response.statusCode}');
        print('Password reset request response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResult(success: true, data: data);
      } else {
        final error = json.decode(response.body);
        return AuthResult(
          success: false,
          errorMessage: error['detail'] ?? 'Failed to request password reset',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during password reset request: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Failed to request password reset: $e',
      );
    }
  }

  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      if (kDebugMode) {
        print('Resetting password with token: ${token.substring(0, 10)}...');
      }

      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      if (kDebugMode) {
        print('Password reset response status: ${response.statusCode}');
        print('Password reset response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResult(success: true, data: data);
      } else {
        final error = json.decode(response.body);
        return AuthResult(
          success: false,
          errorMessage: error['detail'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during password reset: $e');
      }
      return AuthResult(
        success: false,
        errorMessage: 'Failed to reset password: $e',
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
