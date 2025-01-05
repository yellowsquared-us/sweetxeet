import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmailVerificationStatus extends StatefulWidget {
  final String email;
  final VoidCallback? onVerified;

  const EmailVerificationStatus({
    super.key,
    required this.email,
    this.onVerified,
  });

  @override
  State<EmailVerificationStatus> createState() => _EmailVerificationStatusState();
}

class _EmailVerificationStatusState extends State<EmailVerificationStatus> {
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _resendVerification() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _apiService.resendVerificationEmail(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Verification email sent!'
                  : 'Failed to send verification email',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Please verify your email',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to ${widget.email}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: _resendVerification,
                child: const Text('Resend verification email'),
              ),
          ],
        ),
      ),
    );
  }
}