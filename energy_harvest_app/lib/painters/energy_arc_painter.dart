import 'dart:math';
import 'package:flutter/material.dart';

class EnergyArcPainter extends CustomPainter {
  const EnergyArcPainter({
    required this.animation,
    required this.color,
    required this.width,
    this.shadowColor = Colors.white,
    this.blurRadius = 10.0,
    this.spreadRadius = 0.0,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double width;
  final Color shadowColor;
  final double blurRadius;
  final double spreadRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - (width / 2);
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * animation.value.clamp(0.0, 1.0);

    // Draw background circle with box shadow
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    // Apply box shadow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = shadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = width / 3 + spreadRadius * 4,
    );

    // Draw the actual white circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
