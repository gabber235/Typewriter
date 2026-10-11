import "package:typewriter_panel/typewriter_panel.dart";

/// Owns transient graph manipulation state for one mounted [Graph].
///
/// The controller creates previews during pointer interactions and converts
/// them into commit payloads on completion. It does not own canonical graph
/// data or selection. Its keyboard position map is a session baseline, reset
/// when keyboard move mode ends or the controller is disposed.
class GraphInteractionController extends ChangeNotifier {
  Set<GraphIdentifier> _movingIds = const {};
  Offset _moveOffset = Offset.zero;
  GraphResizePreview? _resize;
  final Map<GraphIdentifier, (int, int)> _keyboardPositions = {};
  final ValueNotifier<bool> draggingInsideGraph = ValueNotifier(false);
  final ValueNotifier<GraphIdentifier?> activeDragId = ValueNotifier(null);

  Set<GraphIdentifier> get movingIds => _movingIds;
  Offset get moveOffset => _moveOffset;
  GraphResizePreview? get resize => _resize;

  /// Projects the current transient state into grid deltas and resize data.
  GraphInteractionPreview preview(double cellSize) {
    return GraphInteractionPreview(
      movingIds: _movingIds,
      moveDelta: (
        (_moveOffset.dx / cellSize).round(),
        (_moveOffset.dy / cellSize).round(),
      ),
      resize: _resize,
    );
  }

  /// Starts moving [origin], selected elements, and elements contained by them.
  ///
  /// The origin must exist in [data]. The method clears the previous pointer
  /// offset and marks the graph as the active drag source.
  void beginMove({
    required GraphData data,
    required GraphIdentifier origin,
    required Set<GraphIdentifier> selectedIds,
  }) {
    final originElement = data.keyedElements[origin];
    if (originElement == null) return;

    final selectedElements = <GraphElement>{
      if (selectedIds.contains(origin))
        ...selectedIds.map((id) => data.keyedElements[id]).nonNulls,
      originElement,
    };
    _movingIds = {
      for (final element in data.elements)
        if (selectedElements.any(element.inside)) element.id,
    };
    _moveOffset = Offset.zero;
    draggingInsideGraph.value = true;
    notifyListeners();
  }

  /// Updates the pointer displacement in scene pixels.
  void updateMove(Offset offset) {
    if (_movingIds.isEmpty || _moveOffset == offset) return;
    _moveOffset = offset;
    notifyListeners();
  }

  /// Converts the move preview to absolute grid positions and clears it.
  ///
  /// Returns no changes when no move is active.
  List<GraphMoveCommitPayload> finishMove(GraphData data) {
    if (_movingIds.isEmpty) return const [];
    final preview = this.preview(data.cellSize);
    final (dx, dy) = preview.moveDelta;
    final changes = _movingIds
        .map((id) {
          final element = data.keyedElements[id];
          if (element == null) return null;
          return GraphMoveCommitPayload(
            id: id,
            x: element.x + dx,
            y: element.y + dy,
          );
        })
        .nonNulls
        .toList(growable: false);
    cancelMove();
    return changes;
  }

  /// Discards the move preview without changing [GraphData].
  void cancelMove() {
    if (_movingIds.isEmpty &&
        _moveOffset == Offset.zero &&
        !draggingInsideGraph.value) {
      return;
    }
    _movingIds = const {};
    _moveOffset = Offset.zero;
    draggingInsideGraph.value = false;
    notifyListeners();
  }

  /// Starts a resize preview for [id] at the supplied dimensions.
  void beginResize(GraphIdentifier id, int width, int height) {
    updateResize(id, width, height);
  }

  /// Replaces the active resize preview with positive dimensions.
  void updateResize(GraphIdentifier id, int width, int height) {
    assert(width > 0 && height > 0, "Dimensions must be positive");
    final next = GraphResizePreview(id: id, width: width, height: height);
    if (_resize?.id == next.id &&
        _resize?.width == next.width &&
        _resize?.height == next.height) {
      return;
    }
    _resize = next;
    notifyListeners();
  }

  /// Converts and clears the active resize preview, if one exists.
  GraphResizeCommitPayload? finishResize() {
    final resize = _resize;
    if (resize == null) return null;
    _resize = null;
    notifyListeners();
    return GraphResizeCommitPayload(
      id: resize.id,
      width: resize.width,
      height: resize.height,
    );
  }

  /// Discards the active resize preview without emitting a commit.
  void cancelResize() {
    if (_resize == null) return;
    _resize = null;
    notifyListeners();
  }

  /// Produces absolute positions for keyboard movement of [ids].
  ///
  /// Repeated steps accumulate from the last emitted position rather than the
  /// unchanged [data] snapshot, allowing the caller to commit each step while
  /// the source snapshot catches up.
  List<GraphMoveCommitPayload> moveSelection({
    required GraphData data,
    required Set<GraphIdentifier> ids,
    required int dx,
    required int dy,
  }) {
    _keyboardPositions.removeWhere((id, _) => !ids.contains(id));
    return ids
        .map((id) {
          final element = data.keyedElements[id];
          if (element == null) return null;
          final current = _keyboardPositions[id] ?? (element.x, element.y);
          final next = (current.$1 + dx, current.$2 + dy);
          _keyboardPositions[id] = next;
          return GraphMoveCommitPayload(id: element.id, x: next.$1, y: next.$2);
        })
        .nonNulls
        .toList(growable: false);
  }

  /// Drops accumulated keyboard positions and resumes from the next snapshot.
  void resetKeyboardMovement() {
    _keyboardPositions.clear();
  }

  /// Produces absolute dimensions for keyboard resizing of [ids].
  ///
  /// Dimensions are clamped to at least one grid cell.
  List<GraphResizeCommitPayload> resizeSelection({
    required GraphData data,
    required Set<GraphIdentifier> ids,
    required int dw,
    required int dh,
  }) {
    return ids
        .map((id) => data.keyedElements[id])
        .nonNulls
        .map(
          (element) => GraphResizeCommitPayload(
            id: element.id,
            width: max(element.width + dw, 1),
            height: max(element.height + dh, 1),
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    draggingInsideGraph.dispose();
    activeDragId.dispose();
    super.dispose();
  }
}

/// Creates and disposes an interaction controller with the current hook.
GraphInteractionController useGraphInteractionController() {
  final controller = useMemoized(GraphInteractionController.new);
  useListenable(controller);
  useEffect(() => controller.dispose, [controller]);
  return controller;
}
