import "package:typewriter_panel/typewriter_panel.dart";

/// Geometric helpers for Flutter rectangles.
extension RectExtension on Rect {
  /// Returns the rectangle's width multiplied by its height.
  double get area => width * height;
}
