import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "graph_commit.freezed.dart";

@freezed
abstract class GraphMoveCommitPayload with _$GraphMoveCommitPayload {
  const factory GraphMoveCommitPayload({
    required GraphIdentifier id,
    required int x,
    required int y,
  }) = _GraphMoveCommitPayload;
}

@freezed
abstract class GraphResizeCommitPayload with _$GraphResizeCommitPayload {
  const factory GraphResizeCommitPayload({
    required GraphIdentifier id,
    required int width,
    required int height,
  }) = _GraphResizeCommitPayload;
}

typedef GraphMoveCommit = void Function(List<GraphMoveCommitPayload> changes);
typedef GraphResizeCommit =
    void Function(List<GraphResizeCommitPayload> changes);
