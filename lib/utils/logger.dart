import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final prefix = '[${level.name.toUpperCase()}] $timestamp';
      
      print('$prefix: $message');
      if (error != null) {
        print('$prefix Error: $error');
        if (stackTrace != null) {
          print('$prefix StackTrace: $stackTrace');
        }
      }
    }
  }
}