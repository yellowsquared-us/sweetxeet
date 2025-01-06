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
        await _authService.saveAuthData(responseData['access_token']);
        await _authService.storage.write(key: 'user_email', value: email);
        notifyListeners();

        // Check if using temporary password
        final user = responseData['user'];
        final tempPasswordExpires = user?['temp_password_expires_at'];
        
        debugPrint('User data: $user');
        debugPrint('Temp password expires: $tempPasswordExpires');
        
        final bool isTemporaryPassword = tempPasswordExpires != null;
        
        debugPrint('Is temporary password: $isTemporaryPassword');
        
        return AuthResult(
          success: true,
          requiresPasswordChange: isTemporaryPassword,
          data: responseData,
        );
      }

      // Handle specific error messages
      String errorMessage = responseData['detail'] ?? 'Login failed';
      if (errorMessage.contains('temporary password has expired')) {
        return AuthResult(
          success: false,
          errorMessage: 'Your temporary password has expired. Please request a new password reset.',
        );
      }
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

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return AuthResult(
          success: false,
          errorMessage: 'Not authenticated',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      debugPrint('Change password response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return AuthResult(success: true, data: responseData);
      }

      final error = json.decode(response.body);
      return AuthResult(
        success: false,
        errorMessage: error['detail'] ?? 'Failed to change password',
      );
    } catch (e) {
      debugPrint('Error changing password: $e');
      return AuthResult(
        success: false,
        errorMessage: 'An error occurred while changing password',
      );
    }
  }

  // Check sign-in status on app start
  Future<void> checkSignInStatus() async {
    await _authService.isLoggedIn();
    notifyListeners();
  }
}