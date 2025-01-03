import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class GoogleAuthService {
  // Platform-specific client IDs
  static const String _androidClientId =
      '682978310543-gpur1a213um0a1u83gagb53emiis3gcs.apps.googleusercontent.com';
  static const String _iosClientId =
      '682978310543-rn5qcvctijr58sl2bgp5ap6b1f6tivpg.apps.googleusercontent.com';

  // Get the appropriate client ID based on platform
  String get _clientId {
    if (Platform.isAndroid) {
      return _androidClientId;
    } else if (Platform.isIOS) {
      return _iosClientId;
    } else {
      throw UnsupportedError('Unsupported platform for Google Sign In');
    }
  }

  static const String _redirectUrl =
      'com.yellowsquared.sweetxeet:/oauth2redirect';
  static const String _discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  // Store the ID token for sign out
  String? _idToken;

  Future<AuthorizationTokenResponse?> signInWithGoogle() async {
    try {
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          scopes: [
            'openid',
            'email',
            'profile',
          ],
          promptValues: ['select_account'],
        ),
      );

      // Store the ID token for later use during sign out
      _idToken = result.idToken;

      return result;
    } on Exception catch (e) {
      debugPrint('Error during Google sign in: $e');
      return null;
    }
  }

  Future<TokenResponse?> refreshAccessToken(String refreshToken) async {
    try {
      final TokenResponse result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: _discoveryUrl,
          refreshToken: refreshToken,
          scopes: [
            'openid',
            'email',
            'profile',
          ],
        ),
      );

      return result;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
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
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }
}

class GoogleAuthButtons extends StatefulWidget {
  const GoogleAuthButtons({super.key});

  @override
  State<GoogleAuthButtons> createState() => _GoogleAuthButtonsState();
}

class _GoogleAuthButtonsState extends State<GoogleAuthButtons> {
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isSignedIn = false;

  Future<void> _handleSignIn() async {
    final result = await _authService.signInWithGoogle();
    if (result != null) {
      setState(() {
        _isSignedIn = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in')),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _isSignedIn = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isSignedIn
        ? ElevatedButton(
            onPressed: _handleSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign out'),
          )
        : ElevatedButton(
            onPressed: _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign in with Google'),
          );
  }
}
