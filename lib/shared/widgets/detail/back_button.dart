import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const AppBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}