import "package:typewriter_panel/typewriter_panel.dart";

/// Supplies one graph projection owner and its physical viewport boundary.
class GraphDrag extends InheritedWidget {
  const GraphDrag({
    required this.controller,
    required this.containsGlobalPosition,
    required super.child,
    super.key,
  });

  final GraphInteractionController controller;
  final bool Function(Offset) containsGlobalPosition;

  @override
  bool updateShouldNotify(covariant GraphDrag oldWidget) =>
      controller != oldWidget.controller;

  static GraphDrag? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GraphDrag>();
}

/// Owns prepared envelopes for one mounted source, including outside a graph.
class GraphDragSource<T extends GraphDragData> {
  GraphDragSource(this._scope, this._rebuild);

  final GraphDrag? _scope;
  final VoidCallback _rebuild;
  bool _closed = false;
  GraphDragPayload<T>? _prepared;
  GraphDragPayload<T>? _active;
  Offset? _startPosition;

  GraphDragPayload<T> get payload => _active ?? _prepared!;
  ValueListenable<GraphDragSession?>? get state => _scope?.controller.dragState;

  /// Refreshes the next offer without changing an active avatar snapshot.
  void prepare(T value) {
    if (_closed || _active != null) return;
    final current = _prepared;
    if (current == null || !current.canHover || current.value != value) {
      current?.retire();
      _prepared = GraphDragPayload(value: value);
    }
  }

  Offset anchor(
    GraphDragPayload<T> offered,
    Draggable<Object> draggable,
    BuildContext context,
    Offset position,
  ) {
    // Each callback captures offered, the same immutable Draggable.data.
    if (!_closed && identical(draggable.data, offered)) {
      _startPosition = position;
    }
    return childDragAnchorStrategy(draggable, context, position);
  }

  void begin(GraphDragPayload<T> offered) {
    final position = _startPosition;
    if (_closed ||
        !identical(_prepared, offered) ||
        position == null ||
        !offered.start()) {
      return;
    }
    _active = offered;
    final scope = _scope;
    if (scope != null &&
        !scope.controller.beginDrag(
          offered,
          position,
          inside: scope.containsGlobalPosition(position),
        )) {
      offered.retire();
      _active = null;
    }
  }

  void update(GraphDragPayload<T> offered, DragUpdateDetails details) {
    if (_closed || !identical(_active, offered)) return;
    final scope = _scope;
    if (scope == null) return;
    scope.controller.updateDrag(
      offered,
      details.globalPosition,
      inside: scope.containsGlobalPosition(details.globalPosition),
    );
  }

  bool isInsideGraph(GraphDragPayload<T> offered) =>
      identical(_scope?.controller.value?.payload, offered) &&
      (_scope?.controller.value?.inside ?? false) &&
      offered.isDragging;

  bool showFeedback(GraphDragPayload<T> offered) =>
      offered.isDragging &&
      !_closed &&
      (_scope == null ||
          (_scope.controller.ownsDrag(offered) && !isInsideGraph(offered)));

  /// Retires this avatar without clearing another source session.
  void end(GraphDragPayload<T> offered) {
    offered.retire();
    _scope?.controller.endDrag(offered);
    if (!identical(_active, offered)) return;
    _active = null;
    if (!_closed) _rebuild();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    final active = _active;
    _prepared?.retire();
    active?.retire();
    // The payload notification and graph projection cleanup run safely after
    // source element disposal. Flutter still owns a surviving avatar.
    if (active != null) {
      scheduleMicrotask(() => _scope?.controller.endDrag(active));
    }
  }
}

GraphDragSource<T> useGraphDragSource<T extends GraphDragData>(
  BuildContext context,
  T value,
) {
  final revision = useState(0);
  final scope = GraphDrag.maybeOf(context);
  final source = useMemoized(
    () => GraphDragSource<T>(scope, () => revision.value++),
    [scope?.controller, value.graphId],
  )..prepare(value);
  useEffect(() => source.close, [source]);
  return source;
}
