import "package:typewriter_panel/typewriter_panel.dart";

/// Requests one grid step for the currently active graph move mode.
class GraphMoveIntent extends Intent {
  const GraphMoveIntent({required this.direction});

  final TraversalDirection direction;
}

/// Requests one grid step for the currently active graph resize mode.
class GraphResizeIntent extends Intent {
  const GraphResizeIntent({required this.direction});

  final TraversalDirection direction;
}
