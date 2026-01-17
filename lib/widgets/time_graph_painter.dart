import 'package:flutter/material.dart';

/// Custom painter for Power axis on the right side
class PowerAxisPainter extends CustomPainter {
  final double maxPower;
  final Color color;

  PowerAxisPainter({
    required this.maxPower,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Draw axis label at top
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Power (W)',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, 0));

    // Draw 5 tick marks with labels
    const numTicks = 5;
    for (int i = 0; i <= numTicks; i++) {
      final y = (size.height - 20) * (i / numTicks) + 20; // Leave space for label
      final value = maxPower * (1 - i / numTicks); // Invert so 0 is at bottom
      
      // Draw tick mark
      canvas.drawLine(
        Offset(0, y),
        Offset(8, y),
        paint,
      );
      
      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: textStyle.copyWith(fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(10, y - 6));
    }
  }

  @override
  bool shouldRepaint(PowerAxisPainter oldDelegate) {
    return oldDelegate.maxPower != maxPower || oldDelegate.color != color;
  }
}
