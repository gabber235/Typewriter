import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ion.dart";
import "package:iconify_flutter_plus/icons/lucide.dart";
import "package:typewriter_panel/hooks/global_key.dart";
import "package:typewriter_panel/logic/graph/edge_side.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_edge.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/graph_modes.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/adaptive_single_activator.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/rect.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_intents.dart";
import "package:typewriter_panel/widgets/app/components/graph/resizable_element.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:vector_math/vector_math_64.dart" hide Colors;

typedef GraphResizeCallback = void Function(GraphIdentifier, int, int);

enum _GraphSlot { graph, dragTarget }

class _CenterAnimListeners {
  const _CenterAnimListeners({
    required this.valueListener,
    required this.statusListener,
  });

  final VoidCallback valueListener;
  final void Function(AnimationStatus) statusListener;
}

class Graph extends HookConsumerWidget {
  const Graph({
    required this.data,
    this.onElementsDragged,
    this.onElementsResize,
    super.key,
  });

  /// Immutable model describing the current graph snapshot.
  final GraphData data;

  /// Called when one or more elements are dragged. New positions are in cell units.
  final void Function(List<(GraphIdentifier, int, int)>)? onElementsDragged;

  /// Called during resize interactions to commit the new size in cell units for one or more elements.
  final void Function(List<(GraphIdentifier, int, int)>)? onElementsResize;

  static const bool kAnimateGraphTransforms = true;
  static const double kGraphMinScale = 0.6;
  static const double kGraphMaxScale = 2.5;

  void _animateTransform({
    required BuildContext context,
    required TransformationController controller,
    required Matrix4 target,
    required AnimationController animationController,
    required ValueNotifier<_CenterAnimListeners?> listeners,
  }) {
    final prev = listeners.value;
    if (prev != null) {
      animationController
        ..removeListener(prev.valueListener)
        ..removeStatusListener(prev.statusListener);
    }

    if (!kAnimateGraphTransforms) {
      controller.value = target;
      listeners.value = null;
      return;
    }

    final initialMatrix = Matrix4.copy(controller.value);
    final animation = Matrix4Tween(begin: initialMatrix, end: target).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );

    void valueListener() {
      if (!context.mounted) return;
      controller.value = animation.value;
    }

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController
          ..removeListener(valueListener)
          ..removeStatusListener(statusListener);
        controller.value = target;
      }
    }

    animationController
      ..stop()
      ..reset()
      ..addListener(valueListener)
      ..addStatusListener(statusListener);

    listeners.value = _CenterAnimListeners(
      valueListener: valueListener,
      statusListener: statusListener,
    );

    animationController.forward();
  }

  /// Computes an offset that centers the current graph content in the given [size].
  ///
  /// Uses a weighted center-of-mass so larger nodes influence the centering more.
  /// Computes the pan offset that centers the current graph contents within [size].
  ///
  /// Uses a weighted center-of-mass of all elements (weight proportional to
  /// area) so larger nodes influence the final center more. The resulting
  /// offset is applied to the InteractiveViewer's transformation matrix.
  Offset center(Size size) {
    final target = data.elements
        .map((element) => _PreRenderElement.fromElement(element, data.cellSize))
        .centerOffMass;

    final center = size.center(-target);
    return center;
  }

  /// Converts a directional intent to a grid delta (dx, dy) in cell units.
  (int, int) directionToDelta(TraversalDirection direction) {
    return switch (direction) {
      TraversalDirection.left => (-1, 0),
      TraversalDirection.right => (1, 0),
      TraversalDirection.up => (0, -1),
      TraversalDirection.down => (0, 1),
    };
  }

  void _centerFocusedChild({
    required BuildContext context,
    required TransformationController controller,
    required GlobalKey viewerKey,
    required AnimationController animationController,
    required ValueNotifier<_CenterAnimListeners?> listeners,
  }) {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return;

    final focusedRenderBox = focusedContext.findRenderObject() as RenderBox?;
    if (focusedRenderBox == null) return;

    final viewerBox =
        viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewerBox == null) return;
    if (!_isDescendant(focusedRenderBox, viewerBox)) return;

    final focusedLocalCenter = Offset(
      focusedRenderBox.size.width / 2,
      focusedRenderBox.size.height / 2,
    );
    final focusedCenterGlobal = focusedRenderBox.localToGlobal(
      focusedLocalCenter,
    );

    final viewportCenter = Offset(
      viewerBox.size.width / 2,
      viewerBox.size.height / 2,
    );

    final focusedInViewport = viewerBox.globalToLocal(focusedCenterGlobal);
    final sceneFocused = controller.toScene(focusedInViewport);
    final sceneCenter = controller.toScene(viewportCenter);
    final sceneDelta = sceneCenter - sceneFocused;

    final target = Matrix4.copy(controller.value)
      ..translateByDouble(sceneDelta.dx, sceneDelta.dy, 0, 1);

    _animateTransform(
      context: context,
      controller: controller,
      target: target,
      animationController: animationController,
      listeners: listeners,
    );
  }

  void _scheduleCenterFocused({
    required BuildContext context,
    required TransformationController controller,
    required GlobalKey viewerKey,
    required AnimationController animationController,
    required ValueNotifier<_CenterAnimListeners?> listeners,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerFocusedChild(
        context: context,
        controller: controller,
        viewerKey: viewerKey,
        animationController: animationController,
        listeners: listeners,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) => HookBuilder(
        builder: (context) {
          final offset = useMemoized(() => center(constraints.biggest), [
            data,
            constraints,
          ]);
          final controller = useTransformationController(
            initialValue: Matrix4.identity()
              ..translateByDouble(offset.dx, offset.dy, 0, 1),
            keys: [],
          );
          final graphGlobalKey = useGlobalKey();
          final viewerGlobalKey = useGlobalKey();

          final draggingIds = useState<List<GraphIdentifier>>([]);
          final dragStart = useState<Offset?>(null);
          final dragOffset = useState<Offset?>(null);
          final draggingInsideGraph = useState<bool>(false);

          final resizing = useState<(GraphIdentifier, int, int)?>(null);

          final ignoreCentering = useState<List<FocusNode>>([]);
          final animationController = useAnimationController(duration: 250.ms);
          final listeners = useState<_CenterAnimListeners?>(null);

          useEffect(() {
            void onFocusChange() {
              final primaryFocus = FocusManager.instance.primaryFocus;
              if (primaryFocus == null) return;
              if (ignoreCentering.value.remove(primaryFocus)) return;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _centerFocusedChild(
                  context: context,
                  controller: controller,
                  viewerKey: viewerGlobalKey,
                  animationController: animationController,
                  listeners: listeners,
                );
              });
            }

            FocusManager.instance.addListener(onFocusChange);
            return () {
              FocusManager.instance.removeListener(onFocusChange);
            };
          }, const []);

          return ManagedActionSet(
            shortcuts: [
              if (onElementsDragged != null &&
                  ref.watch(currentInteractionModeProvider) is! GraphMoveMode)
                ActionShortcut(
                  id: "graph_move_mode_activate",
                  label: "Move Mode",
                  description: "Go to Move Mode",
                  activators: [
                    SingleActivator(shift: true, LogicalKeyboardKey.keyM),
                  ],
                  icon: Icones(Ion.md_move),
                  onInvoke: (ref) {
                    ref
                        .read(currentInteractionModeProvider.notifier)
                        .setMode(GraphMoveMode());
                    _scheduleCenterFocused(
                      context: context,
                      controller: controller,
                      viewerKey: viewerGlobalKey,
                      animationController: animationController,
                      listeners: listeners,
                    );
                  },
                  priority: 10,
                ),
              if (onElementsResize != null &&
                  ref.watch(currentInteractionModeProvider) is! GraphResizeMode)
                ActionShortcut(
                  id: "graph_resize_mode_activate",
                  label: "Resize Mode",
                  description: "Go to Resize Mode",
                  activators: [
                    SingleActivator(shift: true, LogicalKeyboardKey.keyR),
                  ],
                  icon: Icones(Lucide.move_diagonal_2),
                  onInvoke: (ref) {
                    ref
                        .read(currentInteractionModeProvider.notifier)
                        .setMode(GraphResizeMode());
                    _scheduleCenterFocused(
                      context: context,
                      controller: controller,
                      viewerKey: viewerGlobalKey,
                      animationController: animationController,
                      listeners: listeners,
                    );
                  },
                  priority: 10,
                ),
              ActionShortcut(
                id: "graph_zoom_in",
                label: "Zoom In",
                description: "Zoom the graph in",
                activators: [
                  for (final key in [
                    LogicalKeyboardKey.equal,
                    LogicalKeyboardKey.add,
                    LogicalKeyboardKey.numpadEqual,
                    LogicalKeyboardKey.numpadAdd,
                  ]) ...[
                    SingleActivator(key),
                    SingleActivator(key, shift: true),
                    AdaptiveSingleActivator(key, control: true),
                    AdaptiveSingleActivator(key, control: true, shift: true),
                  ],
                  for (final ch in ["=", "+"]) ...[
                    CharacterActivator(ch),
                    CharacterActivator(ch, meta: true),
                    CharacterActivator(ch, control: true),
                  ],
                ],
                priority: -2,
                onInvoke: (_) {
                  final viewerBox =
                      viewerGlobalKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (viewerBox == null) return;
                  final focal = viewerBox.size.center(Offset.zero);
                  final sceneFocal = controller.toScene(focal);
                  final currentScale = controller.value.getMaxScaleOnAxis();
                  const minScale = kGraphMinScale;
                  const maxScale = kGraphMaxScale;
                  final targetScale = (currentScale * 1.1).clamp(
                    minScale,
                    maxScale,
                  );
                  final applied = targetScale / currentScale;
                  final m = Matrix4.copy(controller.value)
                    ..translateByDouble(sceneFocal.dx, sceneFocal.dy, 0, 1)
                    ..scaleByDouble(applied, applied, 1, 1)
                    ..translateByDouble(-sceneFocal.dx, -sceneFocal.dy, 0, 1);
                  _animateTransform(
                    context: context,
                    controller: controller,
                    target: m,
                    animationController: animationController,
                    listeners: listeners,
                  );
                },
              ),
              ActionShortcut(
                id: "graph_zoom_out",
                label: "Zoom Out",
                description: "Zoom the graph out",
                activators: [
                  for (final key in [
                    LogicalKeyboardKey.minus,
                    LogicalKeyboardKey.underscore,
                    LogicalKeyboardKey.numpadSubtract,
                  ]) ...[
                    SingleActivator(key),
                    SingleActivator(key, shift: true),
                    AdaptiveSingleActivator(key, control: true),
                    AdaptiveSingleActivator(key, control: true, shift: true),
                  ],
                  for (final ch in ["-", "_"]) ...[
                    CharacterActivator(ch),
                    CharacterActivator(ch, meta: true),
                    CharacterActivator(ch, control: true),
                  ],
                ],
                priority: -2,
                onInvoke: (_) {
                  final viewerBox =
                      viewerGlobalKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (viewerBox == null) return;
                  final focal = Offset(
                    viewerBox.size.width / 2,
                    viewerBox.size.height / 2,
                  );
                  final sceneFocal = controller.toScene(focal);
                  final currentScale = controller.value.getMaxScaleOnAxis();
                  const minScale = kGraphMinScale;
                  const maxScale = kGraphMaxScale;
                  final targetScale = (currentScale / 1.1).clamp(
                    minScale,
                    maxScale,
                  );
                  final applied = targetScale / currentScale;
                  final m = Matrix4.copy(controller.value)
                    ..translateByDouble(sceneFocal.dx, sceneFocal.dy, 0, 1)
                    ..scaleByDouble(applied, applied, 1, 1)
                    ..translateByDouble(-sceneFocal.dx, -sceneFocal.dy, 0, 1);
                  _animateTransform(
                    context: context,
                    controller: controller,
                    target: m,
                    animationController: animationController,
                    listeners: listeners,
                  );
                },
              ),
              ActionShortcut(
                id: "graph_zoom_reset",
                label: "Reset Zoom",
                description: "Reset zoom to 100% and center",
                activators: [
                  for (final key in [
                    LogicalKeyboardKey.digit0,
                    LogicalKeyboardKey.numpad0,
                  ]) ...[
                    SingleActivator(key),
                    AdaptiveSingleActivator(key, control: true),
                  ],
                ],
                priority: -2,
                onInvoke: (_) {
                  final m = Matrix4.identity()
                    ..translateByDouble(offset.dx, offset.dy, 0, 1);
                  _animateTransform(
                    context: context,
                    controller: controller,
                    target: m,
                    animationController: animationController,
                    listeners: listeners,
                  );
                },
              ),
            ],
            child: InteractiveViewer.builder(
              key: viewerGlobalKey,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              alignment: Alignment.center,
              minScale: kGraphMinScale,
              maxScale: kGraphMaxScale,
              transformationController: controller,
              builder: (context, viewport) {
                final rect = _quadToRect(viewport);
                return _GraphWithDragTarget(
                  viewport: rect,
                  enableDragTarget: onElementsDragged != null,
                  graph: GraphDrag(
                    draggingInsideGraph: draggingInsideGraph,
                    child: Actions(
                      actions: {
                        SelectedSelectorIntent: CallbackAction<SelectedSelectorIntent>(
                          onInvoke: (intent) {
                            // When we click on a node, it will auto focus on it, however we don't want to center the graph
                            // on it because it will cause the graph to jump around and all around feel terrible.
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
                              onElementsDragged != null,
                              "onElementsDragged must be provided",
                            );
                            final direction = intent.direction;
                            final (dx, dy) = directionToDelta(direction);

                            final primaryFocusedId =
                                SelectableScope.primaryFocusedId();
                            final selectedIds = ref.read(selectionProvider);
                            final ids = {
                              if (primaryFocusedId == null ||
                                  selectedIds.contains(primaryFocusedId))
                                ...selectedIds,

                              ?primaryFocusedId,
                            };

                            final updated = ids
                                .map(
                                  (id) =>
                                      data.keyedElements[GraphIdentifier(
                                        id.id,
                                      )],
                                )
                                .nonNulls
                                .map((element) {
                                  return (
                                    element.id,
                                    element.x + dx,
                                    element.y + dy,
                                  );
                                })
                                .toList();

                            if (updated.isEmpty) {
                              // TODO: Notify the user that no elements were dragged
                              return null;
                            }

                            onElementsDragged!(updated);
                            _scheduleCenterFocused(
                              context: context,
                              controller: controller,
                              viewerKey: viewerGlobalKey,
                              animationController: animationController,
                              listeners: listeners,
                            );

                            return null;
                          },
                        ),
                        GraphResizeIntent: CallbackAction<GraphResizeIntent>(
                          onInvoke: (intent) {
                            assert(
                              onElementsResize != null,
                              "onElementsResize must be provided",
                            );
                            final direction = intent.direction;
                            final (dx, dy) = directionToDelta(direction);
                            final primaryFocusedId =
                                SelectableScope.primaryFocusedId();
                            final selectedIds = ref.read(selectionProvider);
                            final ids = {
                              if (primaryFocusedId == null ||
                                  selectedIds.contains(primaryFocusedId))
                                ...selectedIds,

                              ?primaryFocusedId,
                            };

                            final changes = ids
                                .map(
                                  (id) =>
                                      data.keyedElements[GraphIdentifier(
                                        id.id,
                                      )],
                                )
                                .nonNulls
                                .map(
                                  (element) => (
                                    element.id,
                                    max(element.width + dx, 1),
                                    max(element.height + dy, 1),
                                  ),
                                )
                                .toList();
                            if (changes.isEmpty) {
                              // TODO: Notify user that no elements were resized
                              return null;
                            }
                            onElementsResize!(changes);
                            _scheduleCenterFocused(
                              context: context,
                              controller: controller,
                              viewerKey: viewerGlobalKey,
                              animationController: animationController,
                              listeners: listeners,
                            );

                            return null;
                          },
                        ),
                        GraphCenterFocusedIntent:
                            CallbackAction<GraphCenterFocusedIntent>(
                              onInvoke: (intent) {
                                _centerFocusedChild(
                                  context: context,
                                  controller: controller,
                                  viewerKey: viewerGlobalKey,
                                  animationController: animationController,
                                  listeners: listeners,
                                );
                                return null;
                              },
                            ),
                      },
                      child: _Graph(
                        key: graphGlobalKey,
                        viewport: rect,
                        data: data
                            .offsetChildren(
                              offset: dragOffset.value ?? Offset.zero,
                              ids: draggingIds.value,
                            )
                            .resizeChild(resize: resizing.value),
                        buildChild: (context, child, element) {
                          var widget = child;

                          if (onElementsResize != null) {
                            widget = ResizableElement(
                              element: element,
                              cellSize: data.cellSize,
                              onResizeStart: (id, width, height) {
                                assert(
                                  width > 0 && height > 0,
                                  "Width and height must be greater than 0",
                                );
                                resizing.value = (id, width, height);
                              },
                              onResizeUpdate: (id, width, height) {
                                assert(
                                  width > 0 && height > 0,
                                  "Width and height must be greater than 0",
                                );
                                resizing.value = (id, width, height);
                              },
                              onResizeEnd: (id, width, height) {
                                assert(
                                  width > 0 && height > 0,
                                  "Width and height must be greater than 0",
                                );
                                resizing.value = null;
                                onElementsResize!.call([(id, width, height)]);
                              },
                              child: widget,
                            );
                          }

                          final isDragging = draggingIds.value.contains(
                            element.id,
                          );

                          return IgnorePointer(
                            ignoring: isDragging,
                            child: widget,
                          );
                        },
                      ),
                    ),
                  ),
                  dragTarget: DragTarget<GraphDragData>(
                    onWillAcceptWithDetails: (details) {
                      final id = details.data.graphId;
                      final element = data.keyedElements[id];
                      if (element == null) {
                        return false;
                      }
                      final preRenderElement = _PreRenderElement.fromElement(
                        element,
                        data.cellSize,
                      );
                      dragStart.value = preRenderElement.position;

                      final renderBox =
                          graphGlobalKey.currentContext?.findRenderObject()
                              as RenderBox?;

                      assert(
                        renderBox != null,
                        "Interactive viewer render box not found",
                      );

                      final offset = renderBox!.globalToLocal(details.offset);
                      dragOffset.value = offset - dragStart.value!;

                      final selectedIds = ref
                          .read(selectionProvider)
                          .whereType<GraphIdentifier>()
                          .toSet();
                      final selectedElements = {
                        if (selectedIds.contains(element.id))
                          ...selectedIds
                              .map((id) => data.keyedElements[id])
                              .nonNulls,
                        element,
                      };

                      draggingIds.value = data.elements
                          .where(
                            (e) => selectedElements.any((s) => e.inside(s)),
                          )
                          .map((element) => element.id)
                          .toList();
                      draggingInsideGraph.value = true;
                      return true;
                    },
                    onMove: (details) {
                      if (draggingIds.value.isEmpty) return;
                      final renderBox =
                          graphGlobalKey.currentContext?.findRenderObject()
                              as RenderBox?;

                      assert(
                        renderBox != null,
                        "Interactive viewer render box not found",
                      );

                      final offset = renderBox!.globalToLocal(details.offset);
                      dragOffset.value = offset - dragStart.value!;
                    },
                    onLeave: (data) {
                      draggingIds.value = [];
                      dragStart.value = null;
                      dragOffset.value = null;
                      draggingInsideGraph.value = false;
                    },
                    onAcceptWithDetails: (details) {
                      if (dragOffset.value == null) return;
                      final offset = dragOffset.value!;
                      final dx = (offset.dx / data.cellSize).round();
                      final dy = (offset.dy / data.cellSize).round();

                      final updatedElements = draggingIds.value
                          .map((id) {
                            final element = data.keyedElements[id];
                            if (element == null) return null;
                            return (id, element.x + dx, element.y + dy);
                          })
                          .nonNulls
                          .toList();

                      draggingIds.value = [];
                      dragStart.value = null;
                      dragOffset.value = null;
                      draggingInsideGraph.value = false;

                      onElementsDragged!(updatedElements);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return const SizedBox.expand();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Rect _quadToRect(Quad quad) {
    final minX = quad.point0.x;
    final minY = quad.point0.y;
    final maxX = quad.point2.x;
    final maxY = quad.point2.y;

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);

    return rect;
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

class _GraphWithDragTarget
    extends SlottedMultiChildRenderObjectWidget<_GraphSlot, RenderBox> {
  const _GraphWithDragTarget({
    required this.viewport,
    required this.enableDragTarget,
    required this.graph,
    required this.dragTarget,
  });

  final Rect viewport;
  final bool enableDragTarget;
  final Widget graph;
  final Widget dragTarget;

  @override
  Iterable<_GraphSlot> get slots => _GraphSlot.values;

  @override
  Widget? childForSlot(_GraphSlot slot) {
    switch (slot) {
      case _GraphSlot.graph:
        return graph;
      case _GraphSlot.dragTarget:
        return enableDragTarget ? dragTarget : null;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_GraphSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderGraphWithDragTarget(
      viewport: viewport,
      enableDragTarget: enableDragTarget,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGraphWithDragTarget renderObject,
  ) {
    renderObject
      ..viewport = viewport
      ..enableDragTarget = enableDragTarget;
  }
}

class _RenderGraphWithDragTarget extends RenderBox
    with SlottedContainerRenderObjectMixin<_GraphSlot, RenderBox> {
  _RenderGraphWithDragTarget({
    required Rect viewport,
    required bool enableDragTarget,
  }) : _viewport = viewport,
       _enableDragTarget = enableDragTarget;

  Rect _viewport;
  Rect get viewport => _viewport;
  set viewport(Rect value) {
    if (_viewport == value) return;
    _viewport = value;
    markNeedsLayout();
  }

  bool _enableDragTarget;
  bool get enableDragTarget => _enableDragTarget;
  set enableDragTarget(bool value) {
    if (_enableDragTarget == value) return;
    _enableDragTarget = value;
    markNeedsLayout();
  }

  Iterable<_GraphSlot> get slots => _GraphSlot.values;

  @override
  void performLayout() {
    final graphChild = childForSlot(_GraphSlot.graph);
    final dragTargetChild = childForSlot(_GraphSlot.dragTarget);

    if (graphChild != null) {
      graphChild.layout(const BoxConstraints());
      (graphChild.parentData! as BoxParentData).offset = Offset.zero;
    }

    if (enableDragTarget && dragTargetChild != null) {
      dragTargetChild.layout(BoxConstraints.tight(viewport.size));
      (dragTargetChild.parentData! as BoxParentData).offset = viewport.topLeft;
    }

    size = const Size(1, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final graphChild = childForSlot(_GraphSlot.graph);
    final dragTargetChild = childForSlot(_GraphSlot.dragTarget);

    if (enableDragTarget && dragTargetChild != null) {
      final childParentData = dragTargetChild.parentData! as BoxParentData;
      context.paintChild(dragTargetChild, childParentData.offset + offset);
    }

    if (graphChild != null) {
      final childParentData = graphChild.parentData! as BoxParentData;
      context.paintChild(graphChild, childParentData.offset + offset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final dragTargetChild = childForSlot(_GraphSlot.dragTarget);
    final graphChild = childForSlot(_GraphSlot.graph);

    var anyHit = false;

    if (graphChild != null) {
      final childParentData = graphChild.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          assert(
            transformed == position - childParentData.offset,
            "The transformed position should be equal to the difference between the position and the child's offset.",
          );
          return graphChild.hitTest(result, position: transformed);
        },
      );
      anyHit = anyHit || isHit;
    }

    if (enableDragTarget && dragTargetChild != null) {
      final childParentData = dragTargetChild.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          assert(
            transformed == position - childParentData.offset,
            "The transformed position should be equal to the difference between the position and the child's offset.",
          );
          return dragTargetChild.hitTest(result, position: transformed);
        },
      );
      anyHit = anyHit || isHit;
    }

    return anyHit;
  }

  @override
  bool hitTestSelf(Offset position) => true;
}

class _Graph extends RenderObjectWidget {
  const _Graph({
    required this.viewport,
    required this.data,
    required this.buildChild,
    super.key,
  });

  final Rect viewport;
  final GraphData data;

  final Widget Function(BuildContext, Widget, GraphElement) buildChild;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderGraph(
      graph: data,
      viewport: viewport,
      cellSize: data.cellSize,
      dotColor: Colors.grey.withValues(alpha: 0.8),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderGraph renderObject) {
    renderObject
      ..graph = data
      ..viewport = viewport
      ..cellSize = data.cellSize
      ..dotColor = Colors.grey.withValues(alpha: 0.8);
  }

  @override
  RenderObjectElement createElement() {
    return _GraphElement(this);
  }
}

class _GraphElement extends RenderObjectElement {
  _GraphElement(super.widget);

  @override
  _RenderGraph get renderObject => super.renderObject as _RenderGraph;

  @protected
  @visibleForTesting
  Iterable<Element> get children => _children.values;

  Map<GraphIdentifier, Element> _children = {};
  Map<Key, Element> _keyedChildren = <Key, Element>{};

  @override
  void insertRenderObjectChild(RenderBox child, GraphIdentifier slot) {
    renderObject._setChild(child, slot);
    assert(
      renderObject._children[slot] == child,
      "Child did not get inserted into renderObject",
    );
  }

  @override
  void moveRenderObjectChild(
    RenderBox child,
    GraphIdentifier oldSlot,
    GraphIdentifier newSlot,
  ) {
    final renderObject = this.renderObject;
    assert(
      child.parent == renderObject,
      "Child $child is not a child of this element",
    );
    renderObject._moveChild(child, oldSlot, newSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, GraphIdentifier slot) {
    final renderObject = this.renderObject;
    assert(
      child.parent == renderObject,
      "Child $child is not a child of this element",
    );
    if (renderObject._children[slot] == child) {
      renderObject._setChild(null, slot);
      assert(
        renderObject._children[slot] == null,
        "Child did not get removed from renderObject",
      );
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _children.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(
      _children.containsValue(child),
      "Child $child is not a child of this element",
    );
    assert(
      child.slot is GraphElement,
      "Child $child does not have a valid slot of type GraphElement: ${child.slot}",
    );
    assert(
      _children.containsKey(child.slot),
      "Child $child associated with slot ${child.slot} is not a child of this element",
    );

    _children.remove(child.slot);
    super.forgetChild(child);
  }

  bool _debugCheckHasAssociatedRenderObject(Element newChild) {
    // ignore: prefer_asserts_with_message
    assert(() {
      if (newChild.renderObject == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                "The children of `MultiChildRenderObjectElement` must each has an associated render object.",
              ),
              ErrorHint(
                "This typically means that the `${newChild.widget}` or its children\n"
                "are not a subtype of `RenderObjectWidget`.",
              ),
              newChild.describeElement(
                "The following element does not have an associated render object",
              ),
              DiagnosticsDebugCreator(DebugCreator(newChild)),
            ]),
          ),
        );
      }
      return true;
    }());
    return true;
  }

  @override
  Element inflateWidget(Widget newWidget, Object? newSlot) {
    final newChild = super.inflateWidget(newWidget, newSlot);
    // ignore: prefer_asserts_with_message
    assert(_debugCheckHasAssociatedRenderObject(newChild));
    return newChild;
  }

  Widget _createWidgetForElement(GraphElement element) {
    final parent = widget as _Graph;
    final child = element.builder(this);
    return parent.buildChild(this, child, element);
  }

  Iterable<GraphElement> _viewableChildren() {
    final widget = this.widget as _Graph;

    return widget.data.elements.where((element) {
      final preRenderElement = _PreRenderElement.fromElement(
        element,
        widget.data.cellSize,
      );
      return preRenderElement.isOnScreen(widget.viewport);
    });
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _children = {
      for (final element in _viewableChildren())
        element.id: inflateWidget(_createWidgetForElement(element), element.id),
    };
  }

  @override
  void update(RenderObjectWidget newWidget) {
    super.update(newWidget);

    final oldKeyedElements = _keyedChildren;
    _keyedChildren = {};
    final oldChildren = _children;
    _children = {};

    Map<Key, List<Element>>? debugDuplicateKeys;

    for (final element in _viewableChildren()) {
      final slot = element.id;
      final widget = _createWidgetForElement(element);
      final newWidgetKey = widget.key;

      final oldSlotChild = oldChildren[slot];
      final oldKeyChild = oldKeyedElements[newWidgetKey];

      final Element? fromElement;
      if (oldKeyChild != null) {
        fromElement = oldChildren.remove(oldKeyChild.slot! as GraphIdentifier);
      } else if (oldSlotChild?.widget.key == null) {
        fromElement = oldChildren.remove(slot);
      } else {
        assert(
          oldSlotChild!.widget.key != newWidgetKey,
          "Invalid state where we coulnd't find the old keyed child. Something really went wrong.",
        );

        fromElement = null;
      }

      final newChild = updateChild(fromElement, widget, slot);
      if (newChild != null) {
        _children[slot] = newChild;
        if (newWidgetKey != null) {
          assert(() {
            final existingElement = _keyedChildren[newWidgetKey];
            if (existingElement != null) {
              (debugDuplicateKeys ??= <Key, List<Element>>{})
                  .putIfAbsent(newWidgetKey, () => <Element>[existingElement])
                  .add(newChild);
            }
            return true;
          }(), "Duplicate key found");
          _keyedChildren[newWidgetKey] = newChild;
        }
      }
    }
    oldChildren.values.forEach(deactivateChild);
    assert(_debugDuplicateKeys(debugDuplicateKeys), "Duplicate keys found");
    assert(
      _keyedChildren.values.every(_children.values.contains),
      "_keyedChildren ${_keyedChildren.values} should be a subset of ${_children.values}",
    );
  }

  bool _debugDuplicateKeys(Map<Key, List<Element>>? debugDuplicateKeys) {
    if (debugDuplicateKeys == null) {
      return true;
    }
    for (final duplicateKey in debugDuplicateKeys.entries) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          "Multiple widgets used the same key in ${widget.runtimeType}.",
        ),
        ErrorDescription(
          "The key ${duplicateKey.key} was used by multiple widgets. The offending widgets were:\n",
        ),
        for (final Element element in duplicateKey.value)
          ErrorDescription("  - $element\n"),
        ErrorDescription(
          "A key can only be specified on one widget at a time in the same parent widget.",
        ),
      ]);
    }
    return true;
  }
}

class _RenderGraph extends RenderBox {
  _RenderGraph({
    required GraphData graph,
    required Rect viewport,
    required double cellSize,
    required Color dotColor,
  }) : _graph = graph,
       _viewport = viewport,
       _cellSize = cellSize,
       _dotColor = dotColor;

  GraphData _graph;
  GraphData get graph => _graph;
  set graph(GraphData value) {
    if (_graph == value) return;
    _graph = value;
    markNeedsLayout();
  }

  Rect _viewport;
  Rect get viewport => _viewport;
  set viewport(Rect value) {
    if (_viewport == value) return;
    _viewport = value;
    markNeedsLayout();
  }

  double _cellSize;
  double get cellSize => _cellSize;
  set cellSize(double value) {
    if (_cellSize == value) return;
    _cellSize = value;
    markNeedsLayout();
  }

  Color _dotColor;
  Color get dotColor => _dotColor;
  set dotColor(Color value) {
    if (_dotColor == value) return;
    _dotColor = value;
    markNeedsPaint();
  }

  final Map<GraphIdentifier, RenderBox> _children = {};

  Iterable<RenderBox> get children => _children.values;

  final Map<String, GraphEdge> _edges = {};

  void _setChild(RenderBox? child, GraphIdentifier slot) {
    final oldChild = _children[slot];
    if (oldChild != null) {
      dropChild(oldChild);
      _children.remove(slot);
    }
    if (child != null) {
      _children[slot] = child;
      adoptChild(child);
      final edges = graph.elementsConnectedEdges[slot];
      if (edges != null) {
        final newEdges = edges.map((edge) => MapEntry(edge.id, edge)).toMap();
        _edges.addAll(newEdges);
      }
    } else {
      final element = graph.keyedElements[slot];
      assert(element != null, "Element for slot $slot is null");

      graph.elementsConnectedEdges[slot]
          ?.where(
            (edge) =>
                !_children.containsKey(edge.source) &&
                !_children.containsKey(edge.target),
          )
          .forEach((edge) {
            _edges.remove(edge.id);
          });
    }
  }

  void _moveChild(
    RenderBox child,
    GraphIdentifier oldSlot,
    GraphIdentifier newSlot,
  ) {
    assert(child != this, "A RenderObject cannot be inserted into itself.");
    assert(
      child.parent == this,
      "The child must be a child of this RenderObject.",
    );
    assert(oldSlot != newSlot, "The old slot and new slot cannot be the same.");
    final oldChild = _children[oldSlot];
    if (oldChild == child) {
      _setChild(null, oldSlot);
    }
    _setChild(child, newSlot);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final element in children) {
      element.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final element in children) {
      element.detach();
    }
  }

  @override
  void redepthChildren() {
    children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return _children.entries
        .map(
          (entry) => entry.value.toDiagnosticsNode(name: entry.key.toString()),
        )
        .toList();
  }

  @override
  void performLayout() {
    for (final MapEntry(key: id, value: child) in _children.entries) {
      final element = graph.keyedElements[id];
      assert(element != null, "Element with ID $id not found");
      final preRenderElement = _PreRenderElement.fromElement(
        element!,
        cellSize,
      );

      child.layout(
        BoxConstraints(
          minWidth: cellSize,
          minHeight: cellSize,
          maxWidth: preRenderElement.width,
          maxHeight: preRenderElement.height,
        ),
      );

      _positionChild(child, preRenderElement.position);
    }

    // The size has to be zero, otherwise the viewport will not be applied correctly and gets shifted when
    // the user zooms in or out.
    // We can still render anything we want, so it doesn't actually impact the layout or painting.
    size = Size(1, 1);
  }

  void _positionChild(RenderBox child, Offset offset) {
    (child.parentData! as BoxParentData).offset = offset;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintDots(context, offset);
    _paintEdges(context, offset);
    _paintElements(context, offset);
  }

  void _paintDots(PaintingContext context, Offset offset) {
    final paint = Paint()..color = dotColor;

    final canvas = context.canvas;

    final startX = (viewport.left / cellSize).ceil() * cellSize;
    final startY = (viewport.top / cellSize).ceil() * cellSize;

    for (var x = startX; x <= viewport.right; x += cellSize) {
      for (var y = startY; y <= viewport.bottom; y += cellSize) {
        canvas.drawCircle(offset + Offset(x, y), 2.0, paint);
      }
    }
  }

  void _paintEdges(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final paint = Paint()
      ..strokeWidth = min(graph.cellSize / 10, 2.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final edge in _edges.values) {
      final preRenderEdge = _PreRenderEdge.fromEdge(edge, graph);
      if (preRenderEdge == null) continue;
      final _PreRenderEdge(source: source, target: target) = preRenderEdge;
      final sourcePos = _getConnectionPoint(source.bounds, edge.sourceSide);
      final targetPos = _getConnectionPoint(target.bounds, edge.targetSide);

      canvas.drawLine(
        offset + sourcePos,
        offset + targetPos,
        paint..color = edge.color,
      );
    }
  }

  /// Returns the exact connection point on a node's rectangle for a given side.
  /// This ensures edges originate/terminate on the perimeter, not the center.
  Offset _getConnectionPoint(Rect bounds, EdgeSide side) {
    switch (side) {
      case EdgeSide.top:
        return Offset(bounds.center.dx, bounds.top);
      case EdgeSide.bottom:
        return Offset(bounds.center.dx, bounds.bottom);
      case EdgeSide.left:
        return Offset(bounds.left, bounds.center.dy);
      case EdgeSide.right:
        return Offset(bounds.right, bounds.center.dy);
    }
  }

  void _paintElements(PaintingContext context, Offset offset) {
    final elements = _children.entries.sortedBy((entry) {
      final element = graph.keyedElements[entry.key];
      assert(element != null, "Element with key ${entry.key} not found");
      return element!;
    });
    for (final MapEntry(value: child) in elements) {
      final childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // ignore: prefer_asserts_with_message
    assert(() {
      if (!hasSize) {
        if (debugNeedsLayout) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
              "Cannot hit test a render box that has never been laid out.",
            ),
            describeForError(
              "The hitTest() method was called on this RenderBox",
            ),
            ErrorDescription(
              "Unfortunately, this object's geometry is not known at this time, "
              "probably because it has never been laid out. "
              "This means it cannot be accurately hit-tested.",
            ),
            ErrorHint(
              "If you are trying "
              "to perform a hit test during the layout phase itself, make sure "
              "you only hit test nodes that have completed layout (e.g. the node's "
              "children, after their layout() method has been called).",
            ),
          ]);
        }
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary("Cannot hit test a render box with no size."),
          describeForError("The hitTest() method was called on this RenderBox"),
          ErrorDescription(
            "Although this node is not marked as needing layout, "
            "its size is not set.",
          ),
          ErrorHint(
            "A RenderBox object must have an "
            "explicit size before it can be hit-tested. Make sure "
            "that the RenderBox in question sets its size during layout.",
          ),
        ]);
      }
      return true;
    }());
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final children = _children.entries
        .sortedBy((entry) {
          final element = graph.keyedElements[entry.key];
          assert(element != null, "Element with key ${entry.key} not found");
          return element!;
        })
        .reversed
        .map((entry) => entry.value);

    for (final child in children) {
      final childParentData = child.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          assert(
            transformed == position - childParentData.offset,
            "The transformed position should be equal to the difference between the position and the child's offset.",
          );
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }
}

class _PreRenderElement {
  _PreRenderElement({required this.element, required this.bounds});

  factory _PreRenderElement.fromElement(GraphElement element, double cellSize) {
    final x = element.x * cellSize;
    final y = element.y * cellSize;
    final width = element.width * cellSize;
    final height = element.height * cellSize;
    return _PreRenderElement(
      element: element,
      bounds: Rect.fromLTWH(x, y, width, height),
    );
  }

  final GraphElement element;
  final Rect bounds;

  double get x => bounds.left;
  double get y => bounds.top;

  Offset get position => bounds.topLeft;

  Offset get center => bounds.center;

  double get width => bounds.width;
  double get height => bounds.height;

  bool isOnScreen(Rect viewport) {
    return !bounds.intersect(viewport).isEmpty;
  }

  @override
  String toString() {
    return "$_PreRenderElement{element: $element, bounds: $bounds}";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _PreRenderElement) return false;
    return element == other.element;
  }

  @override
  int get hashCode => element.hashCode;
}

extension _PreRenderElementList on Iterable<_PreRenderElement> {
  Offset get centerOffMass {
    if (isEmpty) return Offset.zero;

    double totalMass = 0;
    double weightedX = 0;
    double weightedY = 0;

    for (final element in this) {
      final area = element.bounds.area;
      final mass = 1.0 + (area * 0.001);

      final centerX = element.bounds.center.dx;
      final centerY = element.bounds.center.dy;

      totalMass += mass;
      weightedX += centerX * mass;
      weightedY += centerY * mass;
    }

    return Offset(weightedX / totalMass, weightedY / totalMass);
  }
}

class _PreRenderEdge {
  _PreRenderEdge({
    required this.edge,
    required this.source,
    required this.target,
  });

  static _PreRenderEdge? fromEdge(GraphEdge edge, GraphData graph) {
    final source = graph.keyedElements[edge.source];
    final target = graph.keyedElements[edge.target];

    if (source == null || target == null) {
      return null;
    }

    return _PreRenderEdge(
      edge: edge,
      source: _PreRenderElement.fromElement(source, graph.cellSize),
      target: _PreRenderElement.fromElement(target, graph.cellSize),
    );
  }

  final GraphEdge edge;
  final _PreRenderElement source;
  final _PreRenderElement target;

  bool connectsTo(GraphElement element) {
    return source.element == element || target.element == element;
  }
}
