import "package:flutter/material.dart";

class Checkerboard extends StatelessWidget {
  const Checkerboard({
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: CustomPaint(painter: const _CheckerboardPainter(), child: child),
  );
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 8.0;
    final light = Paint()..color = const Color(0xFFF1F1F1);
    final dark = Paint()..color = const Color(0xFFBDBDBD);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final alternate = (x ~/ cell + y ~/ cell).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          alternate ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
