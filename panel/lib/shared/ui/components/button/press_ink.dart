import "package:typewriter_panel/typewriter_panel.dart";

/// Paints a button's press splash: a circle of [color] that grows from
/// [center] with [grow] to cover the button and fades as [drain] runs.
///
/// The circle reaches 2.1 times the button's diagonal, so it covers every
/// corner from any press point.
final class PressInk extends CustomPainter {
  PressInk({
    required this.center,
    required this.color,
    required this.grow,
    required this.drain,
  }) : super(repaint: Listenable.merge([grow, drain]));

  /// Where the press landed, in the button's own coordinates.
  final Offset center;

  /// The splash colour at full strength.
  final Color color;

  final Animation<double> grow;
  final Animation<double> drain;

  /// How far the splash has grown, from 0 to 1.
  double get grown => grow.value.clamp(0.0, 1.0);

  /// How strongly the splash shows, from 0 (gone) to its colour's own.
  double get opacity => color.a * (1 - drain.value.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || grown <= 0) return;
    final reach = size.longestSide == 0
        ? 0.0
        : Offset(size.width, size.height).distance * 2.1 / 2;
    canvas.drawCircle(
      center,
      reach * grown,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(PressInk old) =>
      old.center != center || old.color != color;
}
