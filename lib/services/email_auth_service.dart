import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/environment.dart';
import 'auth_service.dart';
import '../models/user_profile.dart';
import '../models/auth_result.dart';
import 'token_manager.dart';

class EmailAuthService extends ChangeNotifier {
  static final EmailAuthService _instance = EmailAuthService._internal();
  factory EmailAuthService() => _instance;

  final String baseUrl = Environment.apiBaseUrl;
  final AuthService _authService = AuthService();
  final TokenManager _tokenManager = TokenManager();

  EmailAuthService._internal();

  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = responseData['access_token'];
        await _tokenManager.setTokens(
          accessToken,
          refreshToken: responseData['refresh_token'],
        );
        await _authService.storage.write(key: 'user_email', value: email);

        final user = UserProfile(
          email: email,
          emailVerified: responseData['email_verified'] ?? false,
          authProvider: 'email',
          picture: responseData['picture_url'],
        );

        notifyListeners();
        return AuthResult.success(
          accessToken: accessToken,
          user: user,
          data: responseData,
        );
      }

      String errorMessage = responseData['detail'] ?? 'Registration failed';
      return AuthResult.failure(errorMessage);
    } catch (e) {
      debugPrint('Error during registration: $e');
      return AuthResult.failure('An error occurred during registration');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting login for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final accessToken = responseData['access_token'];
        await _tokenManager.setTokens(
          accessToken,
          refreshToken: responseData['refresh_token'],
        );
        await _authService.storage.write(key: 'user_email', value: email);

        final user = UserProfile(
          email: email,
          emailVerified: responseData['email_verified'] ?? false,
          authProvider: 'email',
          picture: responseData['picture_url'],
        );

        notifyListeners();
        return AuthResult.success(
          accessToken: accessToken,
          user: user,
          data: responseData,
        );
      }

      String errorMessage = responseData['detail'] ?? 'Login failed';
      return AuthResult.failure(errorMessage);
    } catch (e) {
      debugPrint('Error during login: $e');
      return AuthResult.failure('An error occurred during login');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<String?> getAccessToken() async {
    return await _tokenManager.getAccessToken();
  }

  Future<String?> getUserEmail() async {
    return await _authService.storage.read(key: 'user_email');
  }
}