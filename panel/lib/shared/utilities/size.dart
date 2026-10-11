import "package:typewriter_panel/typewriter_panel.dart";

/// Geometric helpers for Flutter sizes.
extension SizeExtension on Size {
  /// Returns the size's width multiplied by its height.
  double get area => width * height;
}
