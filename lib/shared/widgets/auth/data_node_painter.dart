import 'package:flutter/material.dart';

/// Signature visual motif: a subtle "data node network" pattern, nodding to
/// health-data connectivity. Used on branded auth-screen panels.
class DataNodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final points = [
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.42, size.height * 0.10),
      Offset(size.width * 0.68, size.height * 0.22),
      Offset(size.width * 0.28, size.height * 0.42),
      Offset(size.width * 0.58, size.height * 0.48),
      Offset(size.width * 0.18, size.height * 0.68),
      Offset(size.width * 0.52, size.height * 0.74),
      Offset(size.width * 0.78, size.height * 0.62),
    ];

    const connections = [
      [0, 1], [1, 2], [0, 3], [3, 4], [1, 4],
      [3, 5], [4, 6], [6, 7], [4, 7],
    ];

    for (final c in connections) {
      canvas.drawLine(points[c[0]], points[c[1]], linePaint);
    }
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}