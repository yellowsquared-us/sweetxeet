import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult({required this.success, this.errorMessage});
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
    final token = await storage.read(key: 'access_token');
    return token != null;
  }

  Future<void> saveAuthData(String accessToken, {String? refreshToken}) async {
    await storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> clearAuthData() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'user_email');
  }

  Future<String?> getEmailFromStorage() async {
    return await storage.read(key: 'user_email');
  }
}
