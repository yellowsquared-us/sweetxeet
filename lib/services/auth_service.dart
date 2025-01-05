import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

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

class GoogleAuthService {
  // Platform-specific client IDs
  static const String _androidClientId =
      '682978310543-gpur1a213um0a1u83gagb53emiis3gcs.apps.googleusercontent.com';
  static const String _iosClientId =
      '682978310543-rn5qcvctijr58sl2bgp5ap6b1f6tivpg.apps.googleusercontent.com';
  static const String _redirectUrl =
      'com.yellowsquared.sweetxeet:/oauth2redirect';
  static const String _discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  String? _idToken;

  String get _clientId {
    if (Platform.isAndroid) {
      return _androidClientId;
    } else if (Platform.isIOS) {
      return _iosClientId;
    } else {
      throw UnsupportedError('Unsupported platform for Google Sign In');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign In process...');
      }

      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'email', 'profile'],
          promptValues: ['select_account'],
        ),
      );

      if (result != null) {
        if (kDebugMode) {
          print('Received authorization response');
          print('Access Token: ${result.accessToken?.substring(0, 10)}...');
          print('ID Token present: ${result.idToken != null}');
        }

        _idToken = result.idToken;

        // Store tokens
        await _authService.saveAuthData(
          result.accessToken!,
          refreshToken: result.refreshToken,
        );

        // For mobile platforms, use ID token, for web use access token
        final tokenToSend = Platform.isAndroid || Platform.isIOS 
            ? result.idToken 
            : result.accessToken;

        if (tokenToSend == null) {
          if (kDebugMode) {
            print('No token available for authentication');
          }
          return false;
        }

        // Register with backend using appropriate token
        try {
          final response = await _apiService.registerWithGoogle(tokenToSend);
          if (kDebugMode) {
            print('Backend registration successful');
          }

          if (response['user'] != null && response['user']['email'] != null) {
            await _authService.storage.write(
              key: 'user_email',
              value: response['user']['email'],
            );
          }
          return true;
        } catch (e) {
          if (kDebugMode) {
            print('Error registering with backend: $e');
          }
          return false;
        }
      }

      if (kDebugMode) {
        print('No authorization response received');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error during Google sign in: $e');
      }
      return false;
    }
  }

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken =
          await _authService.storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final TokenResponse result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          refreshToken: refreshToken,
          scopes: ['openid', 'email', 'profile'],
        ),
      );

      if (result.accessToken != null) {
        await _authService.saveAuthData(
          result.accessToken!,
          refreshToken: result.refreshToken ?? refreshToken,
        );
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing token: $e');
      }
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (_idToken != null) {
        await _appAuth.endSession(
          EndSessionRequest(
            postLogoutRedirectUrl: _redirectUrl,
            idTokenHint: _idToken,
          ),
        );
        _idToken = null;
      }
      // Clear stored tokens
      await _authService.clearAuthData();
    } catch (e) {
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
    }
  }
}