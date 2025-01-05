import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'api_service.dart';
import 'auth_service.dart';

class GoogleAuthService extends ChangeNotifier {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  static const String _androidClientId =
      "682978310543-suq149gvpfns266r5sq92v3t5u2aa6pa.apps.googleusercontent.com";
  static const String _iosClientId =
      "682978310543-rn5qcvctijr58sl2bgp5ap6b1f6tivpg.apps.googleusercontent.com";
  static const String _redirectUrl =
      'com.yellowsquared.sweetxeet:/oauth2redirect';
  static const String _discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  GoogleAuthService._internal();

  String get _clientId => Platform.isAndroid ? _androidClientId : _iosClientId;

  Future<bool> signInWithGoogle() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'email'],
          promptValues: ['select_account'],
        ),
      );

      if (result != null) {
        await _authService.saveAuthData(
          result.accessToken!,
          refreshToken: result.refreshToken,
        );

        final response =
            await _apiService.registerWithGoogle(result.accessToken!);
        if (response['user'] != null && response['user']['email'] != null) {
          await _authService.storage.write(
            key: 'user_email',
            value: response['user']['email'],
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during Google sign in: $e');
      return false;
    }
  }

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken =
          await _authService.storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          refreshToken: refreshToken,
          scopes: ['openid', 'email'],
        ),
      );

      if (result.accessToken != null) {
        await _authService.saveAuthData(
          result.accessToken!,
          refreshToken: result.refreshToken ?? refreshToken,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.clearAuthData();
    notifyListeners();
  }

  // Check sign-in status on app start
  Future<void> checkSignInStatus() async {
    await _authService.isLoggedIn();
    notifyListeners();
  }
}
