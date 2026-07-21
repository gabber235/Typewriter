import "package:typewriter_panel/typewriter_panel.dart";

/// Direction for graph layout flow
enum GraphDirection {
  leftToRight(EdgeSide.right, EdgeSide.left),
  rightToLeft(EdgeSide.left, EdgeSide.right),
  topToBottom(EdgeSide.bottom, EdgeSide.top),
  bottomToTop(EdgeSide.top, EdgeSide.bottom);

  const GraphDirection(this.sourceSide, this.targetSide);

  final EdgeSide sourceSide;
  final EdgeSide targetSide;

  T main<T>(T width, T height) => switch (this) {
    GraphDirection.leftToRight => width,
    GraphDirection.rightToLeft => width,
    GraphDirection.topToBottom => height,
    GraphDirection.bottomToTop => height,
  };

  T cross<T>(T width, T height) => switch (this) {
    GraphDirection.leftToRight => height,
    GraphDirection.rightToLeft => height,
    GraphDirection.topToBottom => width,
    GraphDirection.bottomToTop => width,
  };
}
