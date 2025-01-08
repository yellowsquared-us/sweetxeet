// lib/services/google_auth_service.dart
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'api_service.dart';
import 'auth_service.dart';
import '../shared/constants.dart';

class GoogleAuthService {
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

  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign In process...');
      }

      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'email', 'profile'],
          promptValues: ['select_account'],
        ),
      );

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
        return AuthResult(
            success: false, errorMessage: 'No authentication token available');
      }

      // Register with backend using appropriate token and app name
      try {
        final response = await _apiService.registerWithGoogle(
          tokenToSend,
          app: _authService.appName, // Add app name to Google registration
        );
        if (kDebugMode) {
          print('Backend registration successful');
        }

        if (response['user'] != null && response['user']['email'] != null) {
          await _authService.storage.write(
            key: 'user_email',
            value: response['user']['email'],
          );
        }
        return AuthResult(success: true);
      } catch (e) {
        if (kDebugMode) {
          print('Error registering with backend: $e');
        }
        return AuthResult(
            success: false,
            errorMessage: 'Failed to register with backend: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during Google sign in: $e');
      }
      return AuthResult(
          success: false, errorMessage: 'Error during Google sign in: $e');
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

  Future<String?> getAuthToken() async {
    final token = await _authService.storage.read(key: 'access_token');
    return token; // Returns null if no token is found
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
      await _authService.logout();
    } catch (e) {
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
    }
  }
}
