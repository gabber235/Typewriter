import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TimelineRuler extends StatelessWidget {
  const TimelineRuler({required this.viewport, required this.style, super.key});

  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: style.rulerHeight,
      child: CustomPaint(
        painter: _TimelineRulerPainter(
          viewport: viewport,
          style: style,
          textStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _TimelineRulerPainter extends CustomPainter {
  const _TimelineRulerPainter({
    required this.viewport,
    required this.style,
    required this.textStyle,
  });

  final TimelineViewport viewport;
  final TimelineStyle style;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final background = Paint()..color = style.palette.rulerBackground;
    canvas.drawRect(Offset.zero & size, background);

    final minorStep = _tickStep(
      viewport.pixelsPerFrame,
      style.gridMinorMinSpacing,
    );
    final majorStep = _tickStep(
      viewport.pixelsPerFrame,
      style.gridMajorMinSpacing,
    );
    final startFrame = (viewport.visibleStartFrame ~/ minorStep) * minorStep;

    final divider = Paint()
      ..color = style.palette.headerDivider
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      divider,
    );

    for (
      var frame = startFrame;
      frame <= viewport.visibleEndFrame + majorStep;
      frame += minorStep
    ) {
      final x = viewport.frameToPixel(frame) - viewport.horizontalOffset;
      final isMajor = frame % majorStep == 0;
      final linePaint = Paint()
        ..color = isMajor ? style.palette.gridMajor : style.palette.gridMinor
        ..strokeWidth = isMajor ? 1.2 : 1;
      final top = isMajor ? 0.0 : size.height * 0.5;
      canvas.drawLine(Offset(x, top), Offset(x, size.height), linePaint);

      if (!isMajor) continue;
      TextPainter(
          text: TextSpan(
            text: "$frame",
            style: textStyle?.copyWith(color: style.palette.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(x + 4, 6));
    }
  }

  int _tickStep(double pixelsPerFrame, double minSpacing) {
    for (final step in style.gridTickSteps) {
      if (step * pixelsPerFrame >= minSpacing) {
        return step;
      }
    }
    return style.gridTickSteps.last;
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) {
    return oldDelegate.viewport != viewport || oldDelegate.style != style;
  }
}
