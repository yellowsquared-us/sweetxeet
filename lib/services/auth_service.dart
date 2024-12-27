import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/material.dart';

class GoogleAuthService {
  static const String _clientId =
      '682978310543-gpur1a213um0a1u83gagb53emiis3gcs.apps.googleusercontent.com';
  static const String _redirectUrl = 'com.example.sweetxeet:/oauth2redirect';

  // Google's OAuth endpoints
  static const String _discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  final FlutterAppAuth _appAuth = FlutterAppAuth();

  Future<AuthorizationTokenResponse?> signInWithGoogle() async {
    try {
      final AuthorizationTokenResponse? result =
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
          promptValues: ['select_account'], // Forces account selection
        ),
      );

      if (result != null) {
        // Store these securely in your app
        final String? accessToken = result.accessToken;
        final String? idToken = result.idToken;
        final String? refreshToken = result.refreshToken;

        return result;
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Error during Google sign in: $e');
      return null;
    }
  }

  Future<TokenResponse?> refreshAccessToken(String refreshToken) async {
    try {
      final TokenResponse? result = await _appAuth.token(
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
      await _appAuth.endSession(
        EndSessionRequest(
          postLogoutRedirectUrl: _redirectUrl,
          idTokenHint:
              'YOUR_ID_TOKEN', // Pass the ID token received during sign in
        ),
      );
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }
}

// Usage example
class GoogleSignInButton extends StatelessWidget {
  final GoogleAuthService _authService = GoogleAuthService();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await _authService.signInWithGoogle();
        if (result != null) {
          // Handle successful sign in
          print('Successfully signed in: ${result.accessToken}');
        } else {
          // Handle sign in failure
          print('Failed to sign in');
        }
      },
      child: Text('Sign in with Google'),
    );
  }
}
