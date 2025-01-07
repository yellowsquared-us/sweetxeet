import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import '../widgets/email_sign_in_form.dart';
import '../widgets/google_sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _googleAuthService = GoogleAuthService();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle();

      if (result.success && mounted) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else if (mounted) {
        if (result.errorMessage != null &&
            !result.errorMessage!.toLowerCase().contains('cancel') &&
            !result.errorMessage!.toLowerCase().contains('aborted')) {
          setState(() {});
        }
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('cancel') &&
          !errorString.contains('aborted') &&
          !errorString.contains('sign_in_canceled')) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAuthSuccess() {
    Navigator.pushReplacementNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),
                  // Header Text
                  Text(
                    _isLogin ? 'Welcome back' : 'Create account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontSize: 28,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _isLogin
                        ? 'Sign in to continue'
                        : 'Start your journey with us',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Google Sign-in Button
                  GoogleSignInButton(
                    onPressed: _handleGoogleSignIn,
                    isLoading: _isLoading,
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                  ),

                  // Email Sign-in Form
                  EmailSignInForm(
                    isLogin: _isLogin,
                    onToggleMode: (isLogin) {
                      setState(() {
                        _isLogin = isLogin;
                      });
                    },
                    onSuccess: _handleAuthSuccess,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Text(
          'by Yellowsquared',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
