// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetxeet/screens/forgot_password_screen.dart';
import 'package:sweetxeet/screens/reset_code_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/new_password_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_state.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SweetXeet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/auth',
      onGenerateRoute: (settings) {
        // Watch auth state to handle navigation
        final authState = ref.watch(authStateProvider);

        // If user is not authenticated and trying to access protected routes,
        // redirect to auth screen
        if (authState.user == null &&
            settings.name != '/auth' &&
            settings.name != '/forgot-password' &&
            settings.name != '/reset-code' &&
            settings.name != '/new-password') {
          return MaterialPageRoute(builder: (_) => const AuthScreen());
        }

        switch (settings.name) {
          case '/':
          case '/auth':
            // If user is already authenticated, redirect to profile
            if (authState.user != null) {
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            }
            return MaterialPageRoute(builder: (_) => const AuthScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case '/reset-code':
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ResetCodeScreen(email: email),
            );
          case '/new-password':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => NewPasswordScreen(
                email: args['email']!,
                resetCode: args['resetCode']!,
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const AuthScreen());
        }
      },
    );
  }
}
