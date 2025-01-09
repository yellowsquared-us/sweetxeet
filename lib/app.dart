// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetxeet/screens/forgot_password_screen.dart';
import 'package:sweetxeet/screens/reset_code_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reset_code_screen.dart';
import 'screens/new_password_screen.dart';
import 'theme/app_theme.dart';

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
        switch (settings.name) {
          case '/':
          case '/auth':
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
