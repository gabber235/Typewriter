import "package:typewriter_panel/typewriter_panel.dart";

/// Receives an element identifier and its preview dimensions during resizing.
typedef GraphResizeCallback = void Function(GraphIdentifier, int, int);

/// Wraps the graph viewport, for example in a drop target. [toGrid] converts
/// a global position into grid units of the canvas, or null while the canvas
/// is not laid out.
typedef GraphCanvasBuilder = Widget Function(
  BuildContext context,
  Offset? Function(Offset globalPosition) toGrid,
  Widget canvas,
);

/// Interactive graph surface backed by an immutable [GraphData] snapshot.
///
/// Selection is read from the shared selection provider. A focused item outside
/// that selection becomes the sole keyboard target; focus inside the selection
/// preserves the selected batch. Pointer and
/// keyboard edits are previews until the corresponding callback receives
/// absolute grid values. Callers own persistence and rebuild the graph with the
/// resulting snapshot.
class Graph extends HookConsumerWidget {
  const Graph({
    required this.data,
    this.onViewportCenterChanged,
    this.onElementsMoved,
    this.onElementsResized,
    this.canvasBuilder,
    super.key,
  });

  /// Current canonical graph snapshot. Replacing it reconciles layout state.
  final GraphData data;

  /// Receives the visible scene center in grid coordinates after each change.
  ///
  /// Delivery occurs after the current frame and duplicate centers are
  /// suppressed. Disposal reports null. Callers may use this as an optional
  /// placement hint, but remain responsible for persistence and fallback.
  final ValueChanged<Offset?>? onViewportCenterChanged;

  /// Receives completed move changes. Null disables moving.
  final GraphMoveCommit? onElementsMoved;

  /// Receives completed resize changes. Null disables resizing.
  final GraphResizeCommit? onElementsResized;

  /// Wraps the viewport. Drags the graph does not own fall through its own
  /// move target to drop targets installed here.
  final GraphCanvasBuilder? canvasBuilder;

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

            final viewportCenterCallback = useRef(onViewportCenterChanged)
              ..value = onViewportCenterChanged;
            final reportedViewportCenter = useRef<Offset?>(null);
            final pendingViewportCenter = useRef<Offset?>(null);
            final viewportReportScheduled = useRef(false);

            bool sameViewportCenter(Offset? left, Offset right) =>
                left != null && (left - right).distanceSquared < 1e-12;

            void reportViewportCenter(Rect viewport) {
              if (viewportCenterCallback.value == null) return;
              final center = viewport.center / data.cellSize;
              if (!center.dx.isFinite || !center.dy.isFinite) return;
              if (sameViewportCenter(reportedViewportCenter.value, center) ||
                  sameViewportCenter(pendingViewportCenter.value, center)) {
                return;
              }
              pendingViewportCenter.value = center;
              if (viewportReportScheduled.value) return;
              viewportReportScheduled.value = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                viewportReportScheduled.value = false;
                final next = pendingViewportCenter.value;
                pendingViewportCenter.value = null;
                if (!context.mounted ||
                    next == null ||
                    sameViewportCenter(reportedViewportCenter.value, next)) {
                  return;
                }
                reportedViewportCenter.value = next;
                viewportCenterCallback.value?.call(next);
              });
            }

            useEffect(() {
              return () => viewportCenterCallback.value?.call(null);
            }, const []);

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

            bool containsGlobalPosition(Offset position) {
              final box = viewerKey.currentContext?.findRenderObject();
              if (box is! RenderBox || !box.attached || !box.hasSize) {
                return false;
              }
              return (Offset.zero & box.size).contains(
                box.globalToLocal(position),
              );
            }

            useEffect(() {
              var mounted = true;
              var pending = false;
              void scheduleCheck() {
                if (!mounted ||
                    pending ||
                    interactionController.value == null) {
                  return;
                }
                pending = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  pending = false;
                  if (!mounted) return;
                  interactionController.refreshDragContainment(
                    containsGlobalPosition,
                  );
                  scheduleCheck();
                });
              }

              interactionController.addListener(scheduleCheck);
              scheduleCheck();
              return () {
                mounted = false;
                interactionController.removeListener(scheduleCheck);
              };
            }, [interactionController, viewerKey]);

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

            Offset? toGrid(Offset globalPosition) {
              final box = graphKey.currentContext?.findRenderObject();
              if (box is! RenderBox || !box.attached || !box.hasSize) {
                return null;
              }
              return box.globalToLocal(globalPosition) / data.cellSize;
            }

            Widget wrapCanvas(Widget canvas) =>
                canvasBuilder?.call(context, toGrid, canvas) ?? canvas;

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
              child: wrapCanvas(
                InteractiveViewer.builder(
                  key: viewerKey,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  alignment: Alignment.center,
                  minScale: kGraphMinScale,
                  maxScale: kGraphMaxScale,
                  transformationController: viewportController.transformation,
                  builder: (context, viewport) {
                    final viewportRect = _quadToRect(viewport);
                    reportViewportCenter(viewportRect);
                    final focusedId = SelectableScope.primaryFocusedId()?.id;
                    final visibleElements = layout
                        .visibleElements(
                          viewportRect,
                          overscan: kGraphViewportOverscan,
                          retainedIds: {?focusedId},
                        )
                        .toList(growable: false);
                    bool updateGraphMove(
                      DragTargetDetails<GraphDragPayload<GraphDragData>>
                      details,
                    ) {
                      final offered = details.data;
                      if (!interactionController.ownsDrag(offered)) {
                        return false;
                      }
                      final placed =
                          layout.placementsById[offered.value.graphId];
                      final box = graphKey.currentContext?.findRenderObject();
                      if (placed == null ||
                          box is! RenderBox ||
                          !box.attached ||
                          !box.hasSize) {
                        dragStart.value = null;
                        interactionController.cancelMove();
                        return false;
                      }
                      if (interactionController.movingIds.isEmpty) {
                        dragStart.value = placed.position;
                        interactionController.beginMove(
                          data: data,
                          origin: placed.id,
                          selectedIds: ref
                              .read(selectionProvider)
                              .map((id) => GraphIdentifier(id.id))
                              .toSet(),
                        );
                      }
                      interactionController.updateMove(
                        box.globalToLocal(details.offset) - dragStart.value!,
                      );
                      return true;
                    }

                    return GraphDragTargetSurface(
                      viewport: viewportRect,
                      enabled: onElementsMoved != null,
                      dragState: interactionController.dragState,
                      graph: GraphDrag(
                        controller: interactionController,
                        containsGlobalPosition: containsGlobalPosition,
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
                            GraphResizeIntent:
                                CallbackAction<GraphResizeIntent>(
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
                            dotColor: Color.alphaBlend(
                              Colors.grey.withValues(alpha: 0.5),
                              Surface.colorOf(context),
                            ),
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
                      dragTarget: DragTarget<GraphDragPayload<GraphDragData>>(
                        // Flutter asks this before onDragStarted. Ready admission has no effects.
                        onWillAcceptWithDetails: (details) =>
                            details.data.canHover &&
                            layout.placementsById.containsKey(
                              details.data.value.graphId,
                            ),
                        onMove: updateGraphMove,
                        onLeave: (offered) {
                          if (offered == null ||
                              !interactionController.ownsDrag(offered)) {
                            return;
                          }
                          dragStart.value = null;
                          interactionController.cancelMove();
                        },
                        onAcceptWithDetails: (details) {
                          if (!updateGraphMove(details) ||
                              !details.data.claim()) {
                            return;
                          }
                          dragStart.value = null;
                          final changes = interactionController.finishMove(
                            data,
                          );
                          if (changes.isNotEmpty) onElementsMoved!(changes);
                        },
                        builder: (_, _, _) => const SizedBox.expand(),
                      ),
                    );
                  },
                ),
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
