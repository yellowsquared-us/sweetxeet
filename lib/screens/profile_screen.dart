// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_state.dart';
import '../models/user_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ApiService _apiService = ApiService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _loginMethod;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Check auth state first
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _apiService.getUserProfile();
      if (!mounted) return;

      setState(() {
        _userProfile = profile;
        _loginMethod = profile.authProvider;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the Riverpod auth state notifier to handle sign out
      await ref.read(authStateProvider.notifier).signOut();

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
    // Watch the auth state
    final authState = ref.watch(authStateProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null || authState.user == null) {
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
