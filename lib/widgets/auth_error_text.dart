import 'package:flutter/material.dart';

class AuthErrorText extends StatelessWidget {
  final String text;

  const AuthErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.red.shade600,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
