import "package:typewriter_panel/typewriter_panel.dart";

/// Geometry helpers for laid out render boxes.
extension RenderBoxX on RenderBox {
  /// Combines the global origin with this box's local layout size.
  ///
  /// Ancestor rotation and scaling are not applied to the returned size.
  Rect get bounds {
    final offset = localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}
