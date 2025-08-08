import "package:flutter/material.dart";

extension RenderBoxX on RenderBox {
  Rect get bounds {
    final offset = localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}
