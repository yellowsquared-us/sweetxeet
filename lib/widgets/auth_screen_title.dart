import 'package:flutter/material.dart';

class AuthScreenTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthScreenTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontSize: 28,
              ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
