import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FadeInImagePainter extends CustomPainter {
  final double progress;
  final ui.Image image;

  FadeInImagePainter({required this.progress, required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Create a gradient shader that goes from transparent to opaque
    final shader = ui.Gradient.linear(
      Offset(0, size.height),
      Offset(0, size.height * (1 - progress)),
      [Colors.transparent, Colors.white],
    );

    paint.shader = shader;

    // Draw the image
    canvas.drawImage(image, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}