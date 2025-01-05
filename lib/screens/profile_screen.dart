// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/email_auth_service.dart';
import '../services/google_auth_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final EmailAuthService _emailAuthService = EmailAuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _loginMethod;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getUserProfile();
      final loginMethod = await _determineLoginMethod();
      setState(() {
        _userProfile = profile;
        _loginMethod = loginMethod;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    }
  }

  Future<String?> _determineLoginMethod() async {
    final email = await _emailAuthService.getUserEmail();
    if (email != null) {
      return 'email';
    } else {
      return 'google';
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_loginMethod == 'email') {
        await _emailAuthService.logout();
      } else if (_loginMethod == 'google') {
        await _googleAuthService.signOut();
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not signed in'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userProfile?.picture != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_userProfile!.picture!),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _userProfile!.email,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Email verified: ${_userProfile!.emailVerified ? 'Yes' : 'No'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Login method: ${_loginMethod ?? "Unknown"}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
