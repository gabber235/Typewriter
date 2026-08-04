import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:vector_math/vector_math_64.dart" hide Colors;

typedef GraphResizeCallback = void Function(GraphIdentifier, int, int);

class Graph extends HookConsumerWidget {
  const Graph({
    required this.data,
    this.onElementsMoved,
    this.onElementsResized,
    super.key,
  });

  final GraphData data;
  final GraphMoveCommit? onElementsMoved;
  final GraphResizeCommit? onElementsResized;

  static const double kGraphMinScale = 0.1;
  static const double kGraphMaxScale = 2.5;
  static const double kGraphViewportOverscan = 200;

  Offset center(GraphLayoutResult layout, Size size) {
    return size.center(-layout.centerOfMass);
  }

  (int, int) directionToDelta(TraversalDirection direction) {
    return switch (direction) {
      TraversalDirection.left => (-1, 0),
      TraversalDirection.right => (1, 0),
      TraversalDirection.up => (0, -1),
      TraversalDirection.down => (0, 1),
    };
  }

  Set<GraphIdentifier> _selectedIds(WidgetRef ref, GraphData data) {
    final primary = SelectableScope.primaryFocusedId();
    final selectedIds = ref
        .read(selectionProvider)
        .map((identifier) => identifier.id)
        .toSet();
    final targetIds = <String>{
      if (primary == null || selectedIds.contains(primary.id)) ...selectedIds,
      if (primary != null) primary.id,
    };
    return {
      for (final element in data.elements)
        if (targetIds.contains(element.id.id)) element.id,
    };
  }

  void _centerFocusedChild({
    required GraphViewportController controller,
    required GlobalKey viewerKey,
  }) {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return;
    final focusedBox = focusedContext.findRenderObject() as RenderBox?;
    final viewerBox =
        viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (focusedBox == null || viewerBox == null) return;
    if (!_isDescendant(focusedBox, viewerBox)) return;

    final focusedCenter = focusedBox.localToGlobal(
      focusedBox.size.center(Offset.zero),
    );
    controller.centerViewportPoint(
      point: viewerBox.globalToLocal(focusedCenter),
      viewportCenter: viewerBox.size.center(Offset.zero),
    );
  }

  void _scheduleCenterFocused({
    required GraphViewportController controller,
    required GlobalKey viewerKey,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerFocusedChild(controller: controller, viewerKey: viewerKey);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return HookBuilder(
          builder: (context) {
            final baseLayout = useMemoized(
              () => const GraphLayoutEngine().build(data: data),
              [data],
            );
            final centerOffset = useMemoized(
              () => center(baseLayout, constraints.biggest),
              [baseLayout, constraints.biggest],
            );
            final tickerProvider = useSingleTickerProvider();
            final viewportController = useGraphViewportController(
              tickerProvider: tickerProvider,
              initialTransform: Matrix4.identity()
                ..translateByDouble(centerOffset.dx, centerOffset.dy, 0, 1),
            );
            final interactionController = useGraphInteractionController();
            final preview = interactionController.preview(data.cellSize);
            final layout = useMemoized(
              () =>
                  const GraphLayoutEngine().build(data: data, preview: preview),
              [
                data,
                interactionController.movingIds,
                interactionController.moveOffset,
                interactionController.resize,
              ],
            );
            final graphKey = useGlobalKey();
            final viewerKey = useGlobalKey();
            final dragStart = useState<Offset?>(null);
            final ignoreCentering = useState<List<FocusNode>>([]);
            final currentMode = ref.watch(currentInteractionModeProvider);

            useEffect(() {
              if (currentMode is! GraphMoveMode) {
                interactionController.resetKeyboardMovement();
              }
              return null;
            }, [currentMode, interactionController]);

            useEffect(() {
              void onFocusChange() {
                final primaryFocus = FocusManager.instance.primaryFocus;
                if (primaryFocus == null) return;
                if (ignoreCentering.value.remove(primaryFocus)) return;
                _scheduleCenterFocused(
                  controller: viewportController,
                  viewerKey: viewerKey,
                );
              }

              FocusManager.instance.addListener(onFocusChange);
              return () => FocusManager.instance.removeListener(onFocusChange);
            }, [viewportController]);

            Offset? viewportCenter() {
              final box =
                  viewerKey.currentContext?.findRenderObject() as RenderBox?;
              return box?.size.center(Offset.zero);
            }

            return ManagedActionSet(
              shortcuts: buildGraphShortcuts(
                canMove: onElementsMoved != null,
                canResize: onElementsResized != null,
                currentMode: currentMode,
                activateMoveMode: () {
                  ref
                      .read(currentInteractionModeProvider.notifier)
                      .setMode(GraphMoveMode());
                  _scheduleCenterFocused(
                    controller: viewportController,
                    viewerKey: viewerKey,
                  );
                },
                activateResizeMode: () {
                  ref
                      .read(currentInteractionModeProvider.notifier)
                      .setMode(GraphResizeMode());
                  _scheduleCenterFocused(
                    controller: viewportController,
                    viewerKey: viewerKey,
                  );
                },
                zoomIn: () {
                  final focalPoint = viewportCenter();
                  if (focalPoint == null) return;
                  viewportController.zoomAt(focalPoint, 1.1);
                },
                zoomOut: () {
                  final focalPoint = viewportCenter();
                  if (focalPoint == null) return;
                  viewportController.zoomAt(focalPoint, 1 / 1.1);
                },
                resetZoom: () => viewportController.reset(centerOffset),
              ),
              child: InteractiveViewer.builder(
                key: viewerKey,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                alignment: Alignment.center,
                minScale: kGraphMinScale,
                maxScale: kGraphMaxScale,
                transformationController: viewportController.transformation,
                builder: (context, viewport) {
                  final viewportRect = _quadToRect(viewport);
                  final focusedId = SelectableScope.primaryFocusedId()?.id;
                  final visibleElements = layout
                      .visibleElements(
                        viewportRect,
                        overscan: kGraphViewportOverscan,
                        retainedIds: {?focusedId},
                      )
                      .toList(growable: false);
                  return GraphDragTargetSurface(
                    viewport: viewportRect,
                    enabled: onElementsMoved != null,
                    graph: GraphDrag(
                      draggingInsideGraph:
                          interactionController.draggingInsideGraph,
                      child: Actions(
                        actions: {
                          SelectedSelectorIntent:
                              CallbackAction<SelectedSelectorIntent>(
                                onInvoke: (intent) {
                                  if (!intent.throughTap) return null;
                                  ignoreCentering.value = [
                                    ...ignoreCentering.value,
                                    intent.focusNode,
                                  ];
                                  return null;
                                },
                              ),
                          GraphMoveIntent: CallbackAction<GraphMoveIntent>(
                            onInvoke: (intent) {
                              assert(
                                onElementsMoved != null,
                                "onElementsMoved must be provided",
                              );
                              final (dx, dy) = directionToDelta(
                                intent.direction,
                              );
                              final selectedIds = _selectedIds(ref, data);
                              final changes = interactionController
                                  .moveSelection(
                                    data: data,
                                    ids: selectedIds,
                                    dx: dx,
                                    dy: dy,
                                  );
                              if (changes.isEmpty) return null;
                              onElementsMoved!(changes);
                              _scheduleCenterFocused(
                                controller: viewportController,
                                viewerKey: viewerKey,
                              );
                              return null;
                            },
                          ),
                          GraphResizeIntent: CallbackAction<GraphResizeIntent>(
                            onInvoke: (intent) {
                              assert(
                                onElementsResized != null,
                                "onElementsResized must be provided",
                              );
                              final (dw, dh) = directionToDelta(
                                intent.direction,
                              );
                              final changes = interactionController
                                  .resizeSelection(
                                    data: data,
                                    ids: _selectedIds(ref, data),
                                    dw: dw,
                                    dh: dh,
                                  );
                              if (changes.isEmpty) return null;
                              onElementsResized!(changes);
                              _scheduleCenterFocused(
                                controller: viewportController,
                                viewerKey: viewerKey,
                              );
                              return null;
                            },
                          ),
                          GraphCenterFocusedIntent:
                              CallbackAction<GraphCenterFocusedIntent>(
                                onInvoke: (_) {
                                  _centerFocusedChild(
                                    controller: viewportController,
                                    viewerKey: viewerKey,
                                  );
                                  return null;
                                },
                              ),
                        },
                        child: GraphSurface(
                          key: graphKey,
                          layout: layout,
                          viewport: viewportRect,
                          dotColor: Colors.grey.withValues(alpha: 0.8),
                          visibleElements: visibleElements,
                          buildChild: (placed) {
                            final element = placed.element;
                            return Builder(
                              builder: (context) {
                                var child = element.builder(context);
                                if (onElementsResized != null) {
                                  child = ResizableElement(
                                    element: element,
                                    cellSize: data.cellSize,
                                    onResizeStart:
                                        interactionController.beginResize,
                                    onResizeUpdate:
                                        interactionController.updateResize,
                                    onResizeEnd: (id, width, height) {
                                      interactionController.updateResize(
                                        id,
                                        width,
                                        height,
                                      );
                                      final change = interactionController
                                          .finishResize();
                                      if (change != null) {
                                        onElementsResized!([change]);
                                      }
                                    },
                                    onResizeCancel:
                                        interactionController.cancelResize,
                                    child: child,
                                  );
                                }
                                return IgnorePointer(
                                  ignoring: interactionController.movingIds
                                      .contains(element.id),
                                  child: child,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    dragTarget: DragTarget<GraphDragData>(
                      onWillAcceptWithDetails: (details) {
                        final placed =
                            layout.placementsById[details.data.graphId];
                        if (placed == null) return false;
                        final renderBox =
                            graphKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        assert(renderBox != null, "Graph render box not found");
                        dragStart.value = placed.position;
                        interactionController
                          ..beginMove(
                            data: data,
                            origin: placed.id,
                            selectedIds: ref
                                .read(selectionProvider)
                                .map((id) => GraphIdentifier(id.id))
                                .toSet(),
                          )
                          ..updateMove(
                            renderBox!.globalToLocal(details.offset) -
                                dragStart.value!,
                          );
                        return true;
                      },
                      onMove: (details) {
                        final start = dragStart.value;
                        if (start == null) return;
                        final renderBox =
                            graphKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        assert(renderBox != null, "Graph render box not found");
                        interactionController.updateMove(
                          renderBox!.globalToLocal(details.offset) - start,
                        );
                      },
                      onLeave: (_) {
                        dragStart.value = null;
                        interactionController.cancelMove();
                      },
                      onAcceptWithDetails: (_) {
                        dragStart.value = null;
                        final changes = interactionController.finishMove(data);
                        if (changes.isNotEmpty) onElementsMoved!(changes);
                      },
                      builder: (_, _, _) => const SizedBox.expand(),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Rect _quadToRect(Quad quad) {
    return Rect.fromLTRB(
      quad.point0.x,
      quad.point0.y,
      quad.point2.x,
      quad.point2.y,
    );
  }

  bool _isDescendant(RenderObject descendant, RenderObject ancestor) {
    RenderObject? current = descendant;
    while (current != null) {
      if (identical(current, ancestor)) return true;
      current = current.parent;
    }
    return false;
  }
}
