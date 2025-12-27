import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final String? initialValue;
  final bool isPassword;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.label,
    required this.placeholder,
    this.prefixIcon,
    this.controller,
    this.initialValue,
    this.isPassword = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue != null ? null : initialValue,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: theme.inputDecorationTheme.hintStyle?.color,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
