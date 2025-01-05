import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
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
    await storage.write(key: 'access_token', value: token);
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Google Sign-In registration
  Future<Map<String, dynamic>> registerWithGoogle(String googleAccessToken) async {
    try {
      final platform = Platform.isAndroid || Platform.isIOS ? 'mobile' : 'web';
      
      final requestBody = platform == 'mobile'
          ? {
              'id_token': googleAccessToken,
              'platform': platform,
            }
          : {
              'code': googleAccessToken,
              'platform': platform,
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
        }

        return data;
      } else {
        throw Exception('Failed to register with Google: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in Google registration: $e');
      }
      rethrow;
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-email/$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking email: $e');
      }
      rethrow;
    }
  }

  // Register new user with email/password
  Future<Map<String, dynamic>> registerUser(
      String email, String password, String? name) async {
    try {
      final response = await post('/auth/register', body: {
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      });

      // Store the token if registration is successful
      if (response['access_token'] != null) {
        await setAccessToken(response['access_token']);
      }

      return response;
    } catch (e) {
      if (e.toString().contains('Email already registered')) {
        throw const EmailAlreadyExistsException();
      }
      rethrow;
    }
  }

  // Login with email/password
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    // Store the token if login is successful
    if (response['access_token'] != null) {
      await setAccessToken(response['access_token']);
    }

    return response;
  }

  // Verify email
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying email: $e');
      }
      return false;
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      if (kDebugMode) {
        print('POST Response status: ${response.statusCode}');
        print('POST Response body: ${response.body}');
      }

      if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in POST request: $e');
      }
      rethrow;
    }
  }

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in GET request: $e');
      }
      rethrow;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await post('/auth/resend-verification', body: {
        'email': email,
      });

      if (response['message'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error resending verification email: $e');
      }
      return false;
    }
  }

  // Get user profile
  Future<UserProfile> getUserProfile() async {
    final data = await get('/api/me');
    return UserProfile.fromJson(data);
  }

  Future<void> refreshToken() async {
    // Implement token refresh logic if needed
  }
}

// Custom exception for email already exists
class EmailAlreadyExistsException implements Exception {
  const EmailAlreadyExistsException();
}

// Models
class UserProfile {
  final String email;
  final String? name;
  final String? picture;
  final bool emailVerified;

  UserProfile({
    required this.email,
    this.name,
    this.picture,
    required this.emailVerified,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'],
      name: json['name'],
      picture: json['picture'],
      emailVerified: json['email_verified'] ?? false,
    );
  }
}