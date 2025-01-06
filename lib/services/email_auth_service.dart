// lib/services/email_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sweetxeet/config/environment.dart';
import 'auth_service.dart';

class EmailAuthService extends ChangeNotifier {
  static final EmailAuthService _instance = EmailAuthService._internal();
  factory EmailAuthService() => _instance;

  final String baseUrl = Environment.apiBaseUrl;
  final AuthService _authService = AuthService();

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
        await _authService.saveAuthData(responseData['access_token']);
        await _authService.storage.write(key: 'user_email', value: email);
        notifyListeners();
        return AuthResult(success: true);
      }

      // Handle specific error messages
      String errorMessage = responseData['detail'] ?? 'Registration failed';
      return AuthResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      debugPrint('Error during registration: $e');
      return AuthResult(
          success: false,
          errorMessage: 'An error occurred during registration');
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

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await _authService.saveAuthData(responseData['access_token']);
        await _authService.storage.write(key: 'user_email', value: email);
        notifyListeners();
        return AuthResult(success: true);
      }

      // Handle specific error messages
      String errorMessage = responseData['detail'] ?? 'Login failed';
      return AuthResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      debugPrint('Error during login: $e');
      return AuthResult(
          success: false, errorMessage: 'An error occurred during login');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<String?> getAccessToken() async {
    return await _authService.storage.read(key: 'access_token');
  }

  Future<String?> getUserEmail() async {
    return await _authService.storage.read(key: 'user_email');
  }

  // Check sign-in status on app start
  Future<void> checkSignInStatus() async {
    await _authService.isLoggedIn();
    notifyListeners();
  }
}
