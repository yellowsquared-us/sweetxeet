import 'package:flutter/material.dart';
import 'package:sweetxeet/services/auth_service.dart';
import 'package:sweetxeet/utils/validators.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_screen_title.dart';
import '../widgets/auth_container.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? email =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (email != null) {
        _emailController.text = email;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await _authService.requestPasswordReset(_emailController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _emailSent = true;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/reset-code',
                  arguments: _emailController.text,
                );
              }
            });
          } else {
            _errorMessage = result.errorMessage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _navigateBack() {
    Navigator.pop(context, _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const AuthAppBar(title: 'Reset Password'),
        body: SafeArea(
          child: AuthContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_read,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                AuthScreenTitle(
                  title: 'Check your email',
                  subtitle:
                      'We sent a password reset code to ${_emailController.text}',
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AuthAppBar(
        title: 'Reset Password',
        onBackPressed: _navigateBack,
      ),
      body: SafeArea(
        child: AuthContainer(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const AuthScreenTitle(
                  title: 'Forgot Password?',
                  subtitle:
                      'Enter your email address and we will send you a code to reset your password.',
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  validator: Validators.validateEmail,
                  enabled: !_isLoading,
                ),
                if (_errorMessage != null) AuthErrorText(_errorMessage!),
                const SizedBox(height: 24),
                AuthButton(
                  text: 'Send Reset Code',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  icon: Icons.send_outlined,
                ),
                TextButton(
                  onPressed: _navigateBack,
                  child: Text(
                    'Back to Sign in',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
    _emailController.dispose();
    super.dispose();
  }
}
