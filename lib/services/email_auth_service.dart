import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class EmailAuthService extends ChangeNotifier {
  static final EmailAuthService _instance = EmailAuthService._internal();
  factory EmailAuthService() => _instance;

  static const String baseUrl = 'http://localhost:8000'; // Change in production
  final AuthService _authService = AuthService();

  EmailAuthService._internal();

  Future<bool> register({
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await _authService.saveAuthData(data['access_token']);
        await _authService.storage.write(key: 'user_email', value: email);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    }
  }

  Future<bool> login({
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _authService.saveAuthData(data['access_token']);
        await _authService.storage.write(key: 'user_email', value: email);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearAuthData();
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
