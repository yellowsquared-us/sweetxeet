import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import '../widgets/email_sign_in_form.dart';
import '../widgets/google_sign_in_button.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  void _handleAuthSuccess(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Watch for user state changes and navigate if logged in
    ref.listen(authStateProvider, (previous, next) {
      if (next.user != null) {
        _handleAuthSuccess(context);
      }
    });

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
                    authState.isLogin ? 'Welcome back' : 'Create account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontSize: 28,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    authState.isLogin
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
                    onPressed: () => ref
                        .read(authStateProvider.notifier)
                        .handleGoogleSignIn(),
                    isLoading: authState.isLoading,
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
                    isLogin: authState.isLogin,
                    onToggleMode: (_) =>
                        ref.read(authStateProvider.notifier).toggleLoginMode(),
                    onSuccess: () => _handleAuthSuccess(context),
                  ),
                  if (authState.error != null)
                    Text(
                      authState.error!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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
