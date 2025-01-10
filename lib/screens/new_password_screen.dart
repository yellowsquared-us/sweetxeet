import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_screen_title.dart';
import '../widgets/auth_container.dart';
import '../widgets/password_text_field.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetCode;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetCode,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.resetPasswordWithCode(
        widget.email,
        widget.resetCode,
        _passwordController.text,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/auth');
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Failed to reset password';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AuthAppBar(title: 'Set New Password'),
      body: SafeArea(
        child: AuthContainer(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthScreenTitle(
                  title: 'Create New Password',
                  subtitle:
                      'Your new password must be 6 characters long and contain at least one number',
                ),
                const SizedBox(height: 32),
                PasswordTextField(
                  controller: _passwordController,
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                PasswordTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your new password',
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                if (_errorMessage != null) AuthErrorText(_errorMessage!),
                const SizedBox(height: 24),
                AuthButton(
                  text: 'Reset Password',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
