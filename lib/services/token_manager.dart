import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;

  final storage = const FlutterSecureStorage();
  Timer? _refreshTimer;

  TokenManager._internal();

  Future<String?> getAccessToken() async {
    final token = await storage.read(key: 'access_token');
    if (token == null) return null;

    try {
      if (_isTokenExpiringSoon(token)) {
        return await refreshToken();
      }
      return token;
    } catch (e) {
      return await refreshToken();
    }
  }

  bool _isTokenExpiringSoon(String token) {
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final expiryDate =
          DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      // If token expires in less than 5 minutes, consider it as expiring soon
      return DateTime.now()
          .isAfter(expiryDate.subtract(const Duration(minutes: 5)));
    } catch (e) {
      return true;
    }
  }

  Future<String?> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        await _clearTokens();
        return null;
      }

      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/auth/refresh'),
        headers: {'Authorization': 'Bearer $refreshToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await storage.write(key: 'access_token', value: newToken);
        if (newRefreshToken != null) {
          await storage.write(key: 'refresh_token', value: newRefreshToken);
        }

        _scheduleTokenRefresh(newToken);
        return newToken;
      }

      await _clearTokens();
      return null;
    } catch (e) {
      await _clearTokens();
      return null;
    }
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    _cancelRefreshTimer();
  }

  void _scheduleTokenRefresh(String token) {
    _cancelRefreshTimer();

    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final expiryDate =
          DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final refreshTime = expiryDate.subtract(const Duration(minutes: 5));
      final now = DateTime.now();

      if (refreshTime.isAfter(now)) {
        _refreshTimer = Timer(refreshTime.difference(now), () async {
          await refreshToken();
        });
      }
    } catch (e) {
      // If token parsing fails, try to refresh after 5 minutes
      _refreshTimer = Timer(const Duration(minutes: 5), () async {
        await refreshToken();
      });
    }
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> setTokens(String accessToken, {String? refreshToken}) async {
    await storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
    _scheduleTokenRefresh(accessToken);
  }

  Future<void> clearTokens() async {
    await _clearTokens();
  }

  // Call this when initializing your app
  Future<void> initialize() async {
    final token = await getAccessToken();
    if (token != null) {
      _scheduleTokenRefresh(token);
    }
  }
}
