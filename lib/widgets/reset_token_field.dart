import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_text_field.dart';

class ResetTokenField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const ResetTokenField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      labelText: 'Reset Code',
      hintText: '000000',
      prefixIcon: Icon(
        Icons.key_outlined,
        color: Colors.grey.shade600,
        size: 20,
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 8,
        fontWeight: FontWeight.bold,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the reset code';
        }
        if (value.length != 6) {
          return 'Code must be 6 digits';
        }
        return null;
      },
      enabled: enabled,
    );
  }
}
