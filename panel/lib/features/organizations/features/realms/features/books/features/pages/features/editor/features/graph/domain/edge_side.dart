import "package:flutter/material.dart";

enum EdgeSide {
  top,
  bottom,
  left,
  right;

  Axis get axis {
    switch (this) {
      case EdgeSide.left:
      case EdgeSide.right:
        return Axis.horizontal;
      case EdgeSide.top:
      case EdgeSide.bottom:
        return Axis.vertical;
    }
  }

  Offset get unitVector {
    switch (this) {
      case EdgeSide.top:
        return const Offset(0, -1);
      case EdgeSide.bottom:
        return const Offset(0, 1);
      case EdgeSide.left:
        return const Offset(-1, 0);
      case EdgeSide.right:
        return const Offset(1, 0);
    }
  }
}
