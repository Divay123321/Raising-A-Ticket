import 'package:filoi/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DetailField extends StatelessWidget {
  final String label;
  final String value;
  const DetailField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.slate, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 15)),
      ],
    );
  }
}
