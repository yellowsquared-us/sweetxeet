// lib/features/auth/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/email_auth_service.dart';
import '../../services/google_auth_service.dart';

final emailAuthServiceProvider =
    Provider<EmailAuthService>((ref) => EmailAuthService());
final googleAuthServiceProvider =
    Provider<GoogleAuthService>((ref) => GoogleAuthService());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  final emailAuthService = ref.watch(emailAuthServiceProvider);
  final googleAuthService = ref.watch(googleAuthServiceProvider);
  return AuthNotifier(emailAuthService, googleAuthService);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final EmailAuthService _emailAuthService;
  final GoogleAuthService _googleAuthService;

  AuthNotifier(this._emailAuthService, this._googleAuthService)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final email = await _emailAuthService.getUserEmail();
      if (email != null) {
        // User logged in with email
        state = AsyncValue.data(UserProfile(email: email));
      } else {
        // Check google auth
        final token = await _emailAuthService.getAccessToken();
        if (token != null) {
          final googleEmail = await _emailAuthService.getUserEmail();
          if (googleEmail != null) {
            state = AsyncValue.data(UserProfile(email: googleEmail));
          } else {
            state = const AsyncValue.data(null);
          }
        } else {
          state = const AsyncValue.data(null);
        }
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result.success) {
        final email = await _emailAuthService.getUserEmail();
        if (email != null) {
          state = AsyncValue.data(UserProfile(email: email));
        } else {
          state = const AsyncValue.data(null);
        }
      } else {
        state = AsyncValue.error(
            result.errorMessage ?? 'Google sign-in failed', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> registerWithEmail(
      {required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final result =
          await _emailAuthService.register(email: email, password: password);
      if (result.success) {
        state = AsyncValue.data(UserProfile(email: email));
      } else {
        state = AsyncValue.error(
            result.errorMessage ?? 'Registration failed', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loginWithEmail(
      {required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final result =
          await _emailAuthService.login(email: email, password: password);
      if (result.success) {
        state = AsyncValue.data(UserProfile(email: email));
      } else {
        state = AsyncValue.error(
            result.errorMessage ?? 'Login failed', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final email = await _emailAuthService.getUserEmail();
      if (email != null) {
        await _emailAuthService.logout();
      } else {
        await _googleAuthService.signOut();
      }
      state = AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
