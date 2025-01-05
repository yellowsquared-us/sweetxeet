// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../services/email_auth_service.dart';
import '../services/google_auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailAuthService = EmailAuthService();
  final _googleAuthService = GoogleAuthService();

  bool _isLoading = false;
  bool _isLogin = true; // Toggle between login and registration
  String? _errorMessage;

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _errorMessage = null;
  }

  Future<void> _submitForm() async {
    debugPrint('_submitForm called, _isLogin: $_isLogin');

    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Attempting authentication. IsLogin: $_isLogin');
      final result = _isLogin
          ? await _emailAuthService.login(
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await _emailAuthService.register(
              email: _emailController.text,
              password: _passwordController.text,
            );

      if (result.success && mounted) {
        debugPrint('Authentication successful');
        _clearForm(); // Clear form on success
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      } else {
        debugPrint('Authentication failed with message: ${result.errorMessage}');
        setState(() {
          _errorMessage = result.errorMessage ?? 'Authentication failed';
        });
      }
    } catch (e) {
      debugPrint('Error during authentication: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      debugPrint('Authentication process completed.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result.success && mounted) {
        _clearForm(); // Clear form on success
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Google sign-in failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isLogin ? 'Login' : 'Register'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            debugPrint('Toggle _isLogin to: ${!_isLogin}');
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                            _clearForm(); // Clear form when switching between login/register
                          });
                        },
                  child: Text(_isLogin
                      ? 'Need an account? Register'
                      : 'Have an account? Login'),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.network(
                    'https://developers.google.com/identity/images/g-logo.png',
                    height: 24,
                  ),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}