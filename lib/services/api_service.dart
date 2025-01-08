// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../models/user_profile.dart';
import '../config/environment.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = Environment.apiBaseUrl;
  final storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<void> setAccessToken(String token) async {
    if (kDebugMode) {
      print('Setting access token: ${token.substring(0, 10)}...');
    }
    await storage.write(key: 'access_token', value: token);
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getAccessToken();
    if (kDebugMode) {
      print('Getting headers with token: ${token?.substring(0, 10)}...');
    }
    if (token == null) {
      throw Exception('No access token found');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> registerWithGoogle(String token,
      {required String app}) async {
    try {
      final platform = Platform.isAndroid || Platform.isIOS ? 'mobile' : 'web';
      final String tokenType = platform == 'mobile' ? 'id_token' : 'code';
      final requestBody = {
        tokenType: token,
        'platform': platform,
        'app': app,
      };

      if (kDebugMode) {
        print('Sending Google auth request with body: $requestBody');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('Google auth response status: ${response.statusCode}');
        print('Google auth response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Store the backend token
        if (data['access_token'] != null) {
          await setAccessToken(data['access_token']);
          if (kDebugMode) {
            print('Successfully stored access token from Google auth');
            final storedToken = await getAccessToken();
            print('Verified stored token: ${storedToken?.substring(0, 10)}...');
          }
        } else {
          throw Exception('No access token in response');
        }
        return data;
      } else {
        if (kDebugMode) {
          print(
              'Failed to register with Google: ${response.statusCode}, ${response.body}');
        }
        throw Exception('Failed to register with Google: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during Google registration: $e');
      }
      throw Exception('Error during Google registration: $e');
    }
  }

  Future<UserProfile> getUserProfile() async {
    try {
      final headers = await getHeaders();
      if (kDebugMode) {
        print('Getting user profile with headers: $headers');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/me'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Profile response status: ${response.statusCode}');
        print('Profile response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = UserProfile.fromJson(data);
        return profile;
      } else {
        if (kDebugMode) {
          print(
              'Failed to get user profile: ${response.statusCode}, ${response.body}');
        }
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during get user profile: $e');
      }
      throw Exception('Error during get user profile: $e');
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      final authService = AuthService();
      if (kDebugMode) {
        print('Requesting verification email resend for: $email');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend_verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'app': authService.appName,
        }),
      );

      if (kDebugMode) {
        print('Resend verification response status: ${response.statusCode}');
        print('Resend verification response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] != null;
      } else {
        if (kDebugMode) {
          print(
              'Failed to resend verification email: ${response.statusCode}, ${response.body}');
        }
        throw Exception(
            'Failed to resend verification email: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during verification email resend: $e');
      }
      throw Exception('Error during verification email resend: $e');
    }
  }

  Future<void> refreshToken() async {
    // Implement token refresh logic if needed
  }
}
