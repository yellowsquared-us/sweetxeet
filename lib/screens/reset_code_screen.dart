import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_screen_title.dart';
import '../widgets/auth_container.dart';
import '../widgets/reset_token_field.dart';

class ResetCodeScreen extends StatefulWidget {
  final String email;

  const ResetCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.verifyResetCode(
        widget.email,
        _codeController.text,
      );

      if (mounted) {
        if (result.success) {
          Navigator.pushReplacementNamed(
            context,
            '/new-password',
            arguments: {
              'email': widget.email,
              'resetCode': _codeController.text,
            },
          );
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Invalid reset code';
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

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.requestPasswordReset(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'New code sent to your email'
                  : result.errorMessage ?? 'Failed to send reset code',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
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
      appBar: const AuthAppBar(title: 'Enter Reset Code'),
      body: SafeArea(
        child: AuthContainer(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthScreenTitle(
                  title: 'Check your email',
                  subtitle: 'We sent a 6-digit code to ${widget.email}',
                ),
                const SizedBox(height: 32),
                ResetTokenField(
                  controller: _codeController,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                AuthButton(
                  text: 'Verify Code',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                ),
                TextButton(
                  onPressed: _isLoading ? null : _resendCode,
                  child: Text(
                    'Send new code',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_errorMessage != null) AuthErrorText(_errorMessage!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
