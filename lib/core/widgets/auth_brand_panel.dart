import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'data_node_painter.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: DataNodePainter())),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'FILOI',
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 6),
                ),
                const SizedBox(height: 4),
                Text(
                  'ENTERPRISE OPERATIONS PORTAL',
                  style: TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Unlocking Data,\nEmpowering Impact',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}