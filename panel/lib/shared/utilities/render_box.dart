import "package:typewriter_panel/typewriter_panel.dart";

/// Geometry helpers for laid out render boxes.
extension RenderBoxX on RenderBox {
  /// Returns this box's bounds in the global coordinate space.
  Rect get bounds {
    final offset = localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}
