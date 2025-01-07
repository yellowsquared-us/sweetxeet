import 'package:flutter/material.dart';
import 'logger.dart';

class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppError(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'AppError: $message${code != null ? ' (Code: $code)' : ''}';
}

class ErrorHandler {
  static void handleError(BuildContext context, dynamic error,
      {StackTrace? stack}) {
    String message;

    if (error is AppError) {
      message = error.message;
      Logger.log(
        'Application error occurred',
        level: LogLevel.error,
        error: error,
        stackTrace: stack,
      );
    } else {
      message = 'An unexpected error occurred';
      Logger.log(
        'Unexpected error',
        level: LogLevel.error,
        error: error,
        stackTrace: stack,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
