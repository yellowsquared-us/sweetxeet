import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_auth_service.dart';
import '../services/email_auth_service.dart';
import '../models/user_profile.dart';
import '../models/auth_result.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isLogin;
  final String? error;
  final UserProfile? user;

  AuthState({
    this.isLoading = false,
    this.isLogin = true,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLogin,
    String? error,
    UserProfile? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLogin: isLogin ?? this.isLogin,
      error: error,  // Allow setting error to null
      user: user ?? this.user,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final EmailAuthService _emailAuthService = EmailAuthService();

  AuthStateNotifier() : super(AuthState());

  void toggleLoginMode() {
    state = state.copyWith(isLogin: !state.isLogin, error: null);
  }

  Future<void> handleGoogleSignIn() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result.success && result.user != null) {
        state = state.copyWith(
          isLoading: false,
          user: result.user,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Google sign in failed',
        );
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('cancel') && 
          !errorString.contains('aborted') && 
          !errorString.contains('sign_in_canceled')) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> handleEmailSignIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _emailAuthService.login(
        email: email,
        password: password,
      );
      
      if (result.success && result.data != null) {
        state = state.copyWith(
          isLoading: false,
          user: UserProfile(
            email: email,
            emailVerified: result.data?['email_verified'] ?? false,
            authProvider: 'email',
          ),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Sign in failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> handleEmailSignUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _emailAuthService.register(
        email: email,
        password: password,
      );
      
      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          user: UserProfile(
            email: email,
            emailVerified: false,
            authProvider: 'email',
          ),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Sign up failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (state.user?.authProvider == 'google') {
        await _googleAuthService.signOut();
      } else {
        await _emailAuthService.logout();
      }
      
      state = AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}