import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _clientId =
      '682978310543-gpur1a213um0a1u83gagb53emiis3gcs.apps.googleusercontent.com';
  static const String _redirectUrl = 'com.example.sweetxeet:/oauth2redirect';
  static const String _discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  // Separate authorization and token exchange
  Future<String?> _authorize() async {
    try {
      final state = _generateRandomState();
      debugPrint('Generated state: $state');

      await _secureStorage.write(key: 'oauth_state', value: state);
      debugPrint('Stored state in secure storage');

      final AuthorizationResponse? authResponse = await _appAuth.authorize(
        AuthorizationRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'email', 'profile'],
          promptValues: ['select_account'],
        ),
      );

      if (authResponse != null) {
        debugPrint('Received authorization response');
        final storedState = await _secureStorage.read(key: 'oauth_state');
        debugPrint('Retrieved stored state: $storedState');

        return authResponse.authorizationCode;
      }
      debugPrint('No authorization response received');
      return null;
    } catch (e, s) {
      debugPrint('Error during authorization: $e');
      debugPrint('Stack trace: $s');
      return null;
    }
  }

  Future<TokenResponse?> _exchangeToken(String authCode) async {
    try {
      final TokenResponse? result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          authorizationCode: authCode,
          discoveryUrl: _discoveryUrl,
          codeVerifier:
              null, // This needs to match the one used in authorization
        ),
      );

      debugPrint('Token exchange completed: ${result != null}');
      return result;
    } catch (e) {
      debugPrint('Error exchanging token: $e');
      return null;
    }
  }

  String _generateRandomState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In process');

      // Clear any existing state
      await _secureStorage.delete(key: 'oauth_state');
      debugPrint('Cleared existing state');

      // First step: Authorization
      final authCode = await _authorize();
      if (authCode == null) {
        debugPrint('Authorization failed');
        return false;
      }

      // Second step: Token exchange
      final tokenResponse = await _exchangeToken(authCode);
      if (tokenResponse == null) {
        debugPrint('Token exchange failed');
        return false;
      }

      // Store tokens
      await _secureStorage.write(
          key: 'access_token', value: tokenResponse.accessToken);
      debugPrint('Stored access token');

      if (tokenResponse.refreshToken != null) {
        await _secureStorage.write(
            key: 'refresh_token', value: tokenResponse.refreshToken);
        debugPrint('Stored refresh token');
      }

      if (tokenResponse.idToken != null) {
        await _secureStorage.write(
            key: 'id_token', value: tokenResponse.idToken);
        debugPrint('Stored ID token');
      }

      // Clear state after successful authentication
      await _secureStorage.delete(key: 'oauth_state');
      debugPrint('Cleared state after successful authentication');

      return true;
    } catch (e, s) {
      debugPrint('Error during sign in process:');
      if (e is PlatformException) {
        debugPrint('Platform Exception:');
        debugPrint('  Code: ${e.code}');
        debugPrint('  Message: ${e.message}');
        debugPrint('  Details: ${e.details}');
      } else {
        debugPrint('  Error: $e');
        debugPrint('  Stack trace: $s');
      }

      // Clean up on error
      await _secureStorage.delete(key: 'oauth_state');
      debugPrint('Cleared state due to error');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('Starting sign out process');
      final String? idToken = await _secureStorage.read(key: 'id_token');

      if (idToken != null) {
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: _redirectUrl,
            discoveryUrl: _discoveryUrl,
          ),
        );
        debugPrint('EndSession completed');
      }

      await _secureStorage.deleteAll();
      debugPrint('Cleared all secure storage');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Ensure tokens are cleared even if logout fails
      await _secureStorage.deleteAll();
      debugPrint('Cleared all secure storage after error');
    }
  }

  Future<bool> isAuthenticated() async {
    final String? accessToken = await _secureStorage.read(key: 'access_token');
    return accessToken != null;
  }

  Future<bool> refreshTokenIfNeeded() async {
    try {
      debugPrint('Starting token refresh');
      final String? refreshToken =
          await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        debugPrint('No refresh token found');
        return false;
      }

      final TokenResponse? result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          refreshToken: refreshToken,
          scopes: ['openid', 'email', 'profile'],
        ),
      );

      if (result != null) {
        await _secureStorage.write(
            key: 'access_token', value: result.accessToken);
        debugPrint('Updated access token');

        if (result.refreshToken != null) {
          await _secureStorage.write(
              key: 'refresh_token', value: result.refreshToken);
          debugPrint('Updated refresh token');
        }

        if (result.idToken != null) {
          await _secureStorage.write(key: 'id_token', value: result.idToken);
          debugPrint('Updated ID token');
        }

        return true;
      }
      debugPrint('Token refresh failed - no result');
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }
}
