import "package:typewriter_panel/typewriter_panel.dart";

class GraphMoveCommitPayload {
  const GraphMoveCommitPayload({
    required this.id,
    required this.x,
    required this.y,
  });

  final GraphIdentifier id;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GraphMoveCommitPayload &&
            other.id == id &&
            other.x == x &&
            other.y == y;
  }

  @override
  int get hashCode => Object.hash(id, x, y);
}

class GraphResizeCommitPayload {
  const GraphResizeCommitPayload({
    required this.id,
    required this.width,
    required this.height,
  });

  final GraphIdentifier id;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GraphResizeCommitPayload &&
            other.id == id &&
            other.width == width &&
            other.height == height;
  }

  @override
  int get hashCode => Object.hash(id, width, height);
}

typedef GraphMoveCommit = void Function(List<GraphMoveCommitPayload> changes);
typedef GraphResizeCommit =
    void Function(List<GraphResizeCommitPayload> changes);
