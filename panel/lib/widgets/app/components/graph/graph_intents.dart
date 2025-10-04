import "package:flutter/material.dart";

class GraphMoveIntent extends Intent {
  const GraphMoveIntent({required this.direction});

  final TraversalDirection direction;
}

class GraphResizeIntent extends Intent {
  const GraphResizeIntent({required this.direction});

  final TraversalDirection direction;
}

class GraphCenterFocusedIntent extends Intent {
  const GraphCenterFocusedIntent();
}
