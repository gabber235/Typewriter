import "package:typewriter_panel/typewriter_panel.dart";

/// Geometric helpers for Flutter rectangles.
extension RectExtension on Rect {
  double get area => width * height;
}
