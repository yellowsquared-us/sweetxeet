// lib/config/environment.dart
import 'dart:io';

class Environment {
  static const String dev = 'dev';
  static const String staging = 'staging';
  static const String prod = 'prod';

  static const String currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: dev,
  );

  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case dev:
        return 'http://localhost:8000';
      case staging:
        return 'https://api.staging.sweetxeet.com';
      case prod:
        return 'https://api.sweetxeet.com';
      default:
        return 'http://localhost:8000';
    }
  }

  static String get googleAndroidClientId {
    switch (currentEnvironment) {
      case dev:
      case staging:
      case prod:
        return '682978310543-suq149gvpfns266r5sq92v3t5u2aa6pa.apps.googleusercontent.com';
      default:
        return '';
    }
  }

  static String get googleIosClientId {
    switch (currentEnvironment) {
      case dev:
      case staging:
      case prod:
        return '682978310543-rn5qcvctijr58sl2bgp5ap6b1f6tivpg.apps.googleusercontent.com';
      default:
        return '';
    }
  }

  static bool get shouldCollectCrashlytics => currentEnvironment == prod;
  static bool get shouldCollectAnalytics => currentEnvironment != dev;
}
