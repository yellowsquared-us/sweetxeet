import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class EmailVerificationStatus extends StatefulWidget {
  final String email;
  final VoidCallback? onVerified;
  final bool initialVerificationStatus;

  const EmailVerificationStatus({
    super.key,
    required this.email,
    this.onVerified,
    this.initialVerificationStatus = false,
  });

  @override
  State<EmailVerificationStatus> createState() =>
      _EmailVerificationStatusState();
}

class _EmailVerificationStatusState extends State<EmailVerificationStatus> {
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isVerified = false;
  Timer? _pollingTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.initialVerificationStatus;
    if (!_isVerified) {
      _startVerificationCheck();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    // Check every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final userProfile = await _apiService.getUserProfile();
        if (userProfile.emailVerified && mounted) {
          setState(() => _isVerified = true);
          widget.onVerified?.call();
          timer.cancel();
        }
      } catch (e) {
        // Silently handle errors during polling
      }
    });
  }

  Future<void> _resendVerification() async {
    if (_resendCooldown > 0 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.resendVerificationEmail(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Verification email sent!'
                  : 'Failed to send verification email. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          // Start cooldown timer
          setState(() => _resendCooldown = 60);
          _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) {
              setState(() {
                if (_resendCooldown > 0) {
                  _resendCooldown--;
                } else {
                  timer.cancel();
                }
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    if (_isVerified) {
      return const SizedBox.shrink(); // Hide widget when verified
    }

    return Card(
      elevation: 2,
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_resendCooldown > 0)
              Text(
                'Resend available in $_resendCooldown seconds',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ElevatedButton.icon(
                onPressed: _resendVerification,
                icon: const Icon(Icons.refresh),
                label: const Text('Resend verification email'),
              ),
            const SizedBox(height: 8),
            Text(
              "Didn't receive the email? Check your spam folder.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
