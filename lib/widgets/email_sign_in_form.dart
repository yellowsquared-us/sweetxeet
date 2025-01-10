import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetxeet/utils/validators.dart';
import '../providers/auth_state.dart';

class EmailSignInForm extends ConsumerStatefulWidget {
  final bool isLogin;
  final Function(bool) onToggleMode;
  final VoidCallback onSuccess;

  const EmailSignInForm({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
    required this.onSuccess,
  });

  @override
  ConsumerState<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends ConsumerState<EmailSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authStateProvider.notifier);
    final result = widget.isLogin
        ? await authNotifier.handleEmailSignIn(
            _emailController.text,
            _passwordController.text,
          )
        : await authNotifier.handleEmailSignUp(
            _emailController.text,
            _passwordController.text,
          );

    if (mounted) {
      final state = ref.read(authStateProvider);
      if (state.user != null) {
        _clearForm();
        widget.onSuccess();
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
    final authState = ref.watch(authStateProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'name@example.com',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.grey.shade600,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            validator: Validators.validateEmail,
            enabled: !authState.isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey.shade600,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: Validators.validatePassword,
            enabled: !authState.isLoading,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: authState.isLoading ? null : _submitForm,
            icon: authState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    widget.isLogin ? Icons.login : Icons.person_add,
                    color: Colors.white,
                    size: 20,
                  ),
            label: Text(
              widget.isLogin ? 'Sign in' : 'Sign up',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () => widget.onToggleMode(!widget.isLogin),
                child: Text(
                  widget.isLogin ? "Sign up" : "Sign in",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.isLogin)
                TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            '/forgot-password',
                            arguments: _emailController.text,
                          ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}