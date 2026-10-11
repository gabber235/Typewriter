import "package:typewriter_panel/typewriter_panel.dart";

part "graph_commit.freezed.dart";

/// One node's committed grid position after a move interaction.
@freezed
abstract class GraphMoveCommitPayload with _$GraphMoveCommitPayload {
  const factory GraphMoveCommitPayload({
    required GraphIdentifier id,
    required int x,
    required int y,
  }) = _GraphMoveCommitPayload;
}

/// One node's committed grid dimensions after a resize interaction.
@freezed
abstract class GraphResizeCommitPayload with _$GraphResizeCommitPayload {
  const factory GraphResizeCommitPayload({
    required GraphIdentifier id,
    required int width,
    required int height,
  }) = _GraphResizeCommitPayload;
}

/// Receives the complete set of positions produced by one move operation.
///
/// The graph has already ended its transient preview when this callback runs.
typedef GraphMoveCommit = void Function(List<GraphMoveCommitPayload> changes);

/// Receives the complete set of dimensions produced by one resize operation.
///
/// The graph has already ended its transient preview when this callback runs.
typedef GraphResizeCommit = void Function(
  List<GraphResizeCommitPayload> changes,
);
