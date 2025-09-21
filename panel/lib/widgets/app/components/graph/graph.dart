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
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/graph_modes.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/rect.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/graph/resizable_element.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:vector_math/vector_math_64.dart" hide Colors;

/// The side of a node where an edge connects.
///
/// Used by routing logic to compute where a connection leaves or enters a node
/// and to derive an initial axis and outward unit vector for drawing edges.
enum EdgeSide {
  /// Edge connects on the top border of a node.
  top,

  /// Edge connects on the bottom border of a node.
  bottom,

  /// Edge connects on the left border of a node.
  left,

  /// Edge connects on the right border of a node.
  right;

  /// Axis along which an edge should initially travel when leaving/entering
  /// via this side. This keeps connectors predictable and visually detached
  /// from node borders during orthogonal routing.
  Axis get axis {
    switch (this) {
      case EdgeSide.left:
      case EdgeSide.right:
        return Axis.horizontal;
      case EdgeSide.top:
      case EdgeSide.bottom:
        return Axis.vertical;
    }
  }

  /// Outward unit vector pointing away from the node for this side.
  /// Used to create the initial and terminal “stub” segments from/to a node
  /// before the polyline bends.
  Offset get unitVector {
    switch (this) {
      case EdgeSide.top:
        return const Offset(0, -1);
      case EdgeSide.bottom:
        return const Offset(0, 1);
      case EdgeSide.left:
        return const Offset(-1, 0);
      case EdgeSide.right:
        return const Offset(1, 0);
    }
  }
}

/// Immutable snapshot of a graph.
///
/// Holds the grid cell size, the list of nodes (`GraphElement`) and edges
/// (`GraphEdge`). It also provides indexed access to elements by `GraphIdentifier`
/// and a precomputed adjacency map for efficient edge lookup during rendering.
///
/// Use this as the single source of truth for the visual graph. To reflect user
/// interactions (drag/resize), prefer the provided helper methods which return
/// a new instance via copy semantics.
class GraphData {
  GraphData({
    required this.cellSize,
    required this.elements,
    required this.edges,
  }) : keyedElements = Map.fromIterable(
         elements,
         key: (element) => element.id,
       ) {
    for (final edge in edges) {
      (elementsConnectedEdges[edge.source] ??= <GraphEdge>[]).add(edge);
      (elementsConnectedEdges[edge.target] ??= <GraphEdge>[]).add(edge);
    }
  }

  /// Size of a single grid cell in logical pixels. All nodes are positioned and
  /// sized in cell units and converted to pixels using this value.
  final double cellSize;

  /// All nodes in the graph. Coordinates are specified in grid cell units.
  final List<GraphElement> elements;

  /// All edges between nodes. Only edges with both endpoints present will be
  /// painted; off-screen handling is managed internally.
  final List<GraphEdge> edges;

  /// Fast lookup for elements by identifier. Populated from [elements].
  final Map<GraphIdentifier, GraphElement> keyedElements;

  /// Adjacency mapping of element → edges touching it. Used by painter/layout
  /// to efficiently add/remove edges as children enter/leave the viewport.
  final Map<GraphIdentifier, List<GraphEdge>> elementsConnectedEdges = {};

  /// Returns a new GraphData with the provided [ids] translated by [offset].
  ///
  /// - [offset] is in logical pixels; it will be snapped to the grid based on
  ///   [cellSize].
  /// - [ids] is the set of element identifiers to move.
  GraphData offsetChildren({
    required Offset offset,
    required List<GraphIdentifier> ids,
  }) {
    if (offset == Offset.zero) return this;
    if (ids.isEmpty) return this;

    final dx = (offset.dx / cellSize).round();
    final dy = (offset.dy / cellSize).round();

    final newElements = elements.map((element) {
      if (!ids.contains(element.id)) {
        return element;
      }
      return element.copyWith(x: element.x + dx, y: element.y + dy);
    }).toList();
    return copyWith(elements: newElements);
  }

  /// Returns a new GraphData where a single element is resized.
  ///
  /// Supply a tuple of (id, width, height) in cell units. If [resize] is null,
  /// the instance is returned unchanged.
  GraphData resizeChild({(GraphIdentifier, int, int)? resize}) {
    if (resize == null) return this;
    final (id, width, height) = resize;
    final newElements = elements.map((element) {
      if (element.id != id) {
        return element;
      }
      return element.copyWith(width: width, height: height);
    }).toList();
    return copyWith(elements: newElements);
  }

  /// Creates a modified copy of this GraphData.
  GraphData copyWith({
    double? cellSize,
    List<GraphElement>? elements,
    List<GraphEdge>? edges,
  }) => GraphData(
    cellSize: cellSize ?? this.cellSize,
    elements: elements ?? this.elements,
    edges: edges ?? this.edges,
  );

  @override
  String toString() => "GraphData(elements: $elements, edges: $edges)";
}

/// A node in the graph laid out on a fixed grid.
///
/// Coordinates and size are expressed in grid cells. The [builder] produces the
/// widget subtree for this node. The [priority] defines the paint order: lower
/// values are painted first (appear below).
class GraphElement implements Comparable<GraphElement> {
  const GraphElement({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.builder,
    this.priority = 0,
  });
  final GraphIdentifier id;
  final int x;
  final int y;
  final int width;
  final int height;

  /// Relative z-order for painting; higher values are painted later (on top).
  final int priority;

  /// Factory that builds this element's widget. Receives the current context.
  final WidgetBuilder builder;

  /// Checks if this element is fully contained within another element.
  bool inside(GraphElement other) {
    return x >= other.x &&
        x + width <= other.x + other.width &&
        y >= other.y &&
        y + height <= other.y + other.height;
  }

  GraphElement copyWith({
    GraphIdentifier? id,
    int? x,
    int? y,
    int? width,
    int? height,
    int? priority,
    WidgetBuilder? builder,
  }) => GraphElement(
    id: id ?? this.id,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    priority: priority ?? this.priority,
    builder: builder ?? this.builder,
  );

  @override
  String toString() =>
      "GraphElement(id: $id, x: $x, y: $y, width: $width, height: $height, priority: $priority)";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return id == (other as GraphElement).id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(GraphElement other) {
    return priority.compareTo(other.priority);
  }
}

/// Stable identifier for nodes in the graph.
///
/// Wraps a string id to avoid accidental collisions and to type-safely key
/// render/element maps.
class GraphIdentifier {
  const GraphIdentifier(this.id);
  final String id;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return id == (other as GraphIdentifier).id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Connection between two graph elements.
///
/// Edges reference their [source] and [target] identifiers and the side on
/// which they connect to the node rectangle. The painter uses [sourceSide]
/// and [targetSide] to place endpoints on the node perimeter.
class GraphEdge {
  const GraphEdge({
    required this.id,
    required this.source,
    required this.target,
    required this.color,
    this.sourceSide = EdgeSide.right,
    this.targetSide = EdgeSide.left,
  });
  final String id;
  final GraphIdentifier source;
  final GraphIdentifier target;
  final Color color;
  final EdgeSide sourceSide;
  final EdgeSide targetSide;

  bool connectsTo(GraphElement element) {
    return source == element.id || target == element.id;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GraphEdge &&
        other.id == id &&
        other.source == source &&
        other.target == target &&
        other.color == color &&
        other.sourceSide == sourceSide &&
        other.targetSide == targetSide;
  }

  @override
  int get hashCode =>
      Object.hash(id, source, target, color, sourceSide, targetSide);
}

/// Data carried during external drag-and-drop into the graph.
///
/// Implementations should provide a [graphId] that matches an element in the
/// current [GraphData] to allow hit testing and snapping behavior.
abstract class GraphDragData {
  const GraphDragData();

  GraphIdentifier get graphId;
}

enum _GraphSlot { graph, dragTarget }

/// Inherited scope for graph drag state.
///
/// Exposes whether a drag gesture is currently inside the graph, allowing
/// children to adapt visuals or behavior during drag-and-drop operations.
class GraphDrag extends InheritedWidget {
  const GraphDrag({
    required this.draggingInsideGraph,
    required super.child,
    super.key,
  });

  /// Notifier indicating if a drag is currently over the graph viewport.
  final ValueNotifier<bool> draggingInsideGraph;

  @override
  bool updateShouldNotify(covariant GraphDrag oldWidget) {
    return draggingInsideGraph != oldWidget.draggingInsideGraph;
  }

  /// Returns the nearest [GraphDrag] in the widget tree, or null if none found.
  static GraphDrag? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GraphDrag>();
  }

  /// Returns the nearest [GraphDrag] and asserts it exists.
  static GraphDrag of(BuildContext context) {
    final graphDrag = context.dependOnInheritedWidgetOfExactType<GraphDrag>();
    assert(graphDrag != null, "GraphDrag was not a parent in the widget tree");
    return graphDrag!;
  }

  /// Convenience to read the current drag-over state from the nearest scope.
  static bool isDraggingInsideGraph(BuildContext context) {
    return of(context).draggingInsideGraph.value;
  }
}

/// Signature for element resize notifications.
///
/// Provides the element id and the new width/height in cell units.
typedef GraphResizeCallback = void Function(GraphIdentifier, int, int);

class _CenterAnimListeners {
  const _CenterAnimListeners({
    required this.valueListener,
    required this.statusListener,
  });

  final VoidCallback valueListener;
  final void Function(AnimationStatus) statusListener;
}

/// Interactive, zoomable graph canvas with grid, nodes, and edges.
///
/// This widget renders a grid-aligned node graph with optional edges. It
/// supports panning/zooming, keyboard-driven move/resize actions, focus-based
/// centering, and drag-and-drop integration.
///
/// Typical usage:
/// - Provide immutable [GraphData] describing nodes/edges and grid size
/// - Optionally handle [onElementsDragged] to commit drag translations
/// - Optionally handle [onElementsResize] to commit resize changes
///
/// The widget is optimized to only build children visible in the viewport and
/// keeps edges in sync as nodes enter/leave view.
/// Zoomable, pannable grid-aligned graph widget.
///
/// Renders [GraphData] as nodes and edges on a grid. Supports keyboard move
/// and resize intents, focus-based centering, and drag-and-drop.
/// DragTarget integration is achieved by composing with a slotted render
/// object (_GraphWithDragTarget), allowing a full-viewport DragTarget to
/// participate in hit-testing while the graph render box remains size 1 for
/// stable InteractiveViewer transforms. This keeps panning/zooming precise and
/// enables efficient virtualization of children to the visible viewport.
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

  /// Controls whether center focus operations are animated.
  /// When true, centering will smoothly animate to the target position.
  /// When false, centering will jump instantly to the target position.
  ///
  /// Note: Animation is automatically disabled for complex transformations
  /// (e.g., when zoomed in/out) to avoid interpolation artifacts.
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
  /// Build lifecycle
  /// - Registers keyboard shortcuts (move, resize, center) via ManagedActionSet
  /// - Uses InteractiveViewer.builder to provide an infinite, zoomable canvas
  ///   and exposes the current viewport to child widgets
  /// - Composes `_GraphWithDragTarget` so a full-viewport DragTarget can
  ///   receive drag events while the graph render box stays at size 1
  /// - Inflates only viewport-visible children for efficiency inside `_Graph`
  /// - Translates keyboard and drag gestures into grid-aligned deltas and
  ///   forwards them via [onElementsDragged] and [onElementsResize]
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
                    SingleActivator(key, meta: true),
                    SingleActivator(key, meta: true, shift: true),
                    SingleActivator(key, control: true),
                    SingleActivator(key, control: true, shift: true),
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
                  final focal = Offset(
                    viewerBox.size.width / 2,
                    viewerBox.size.height / 2,
                  );
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
                    SingleActivator(key, meta: true),
                    SingleActivator(key, meta: true, shift: true),
                    SingleActivator(key, control: true),
                    SingleActivator(key, control: true, shift: true),
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
                    SingleActivator(key, meta: true),
                    SingleActivator(key, control: true),
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

/// Slotted wrapper that enables full-viewport DragTarget hit testing for the graph.
///
/// What it is:
/// - A small composition helper that co-locates two children in distinct slots:
///   - `graph`: the `_Graph` render object that must remain size 1 for stable
///     InteractiveViewer transforms and painting
///   - `dragTarget`: a widget (typically `DragTarget`) laid out to cover the full
///     visible viewport so drag-and-drop gestures can be hit-tested anywhere
///
/// Why/when you would use it:
/// - The `_Graph` render box intentionally reports a size of 1 to keep scaling and
///   panning exact with InteractiveViewer
/// - Wrapping `_Graph` directly with a `DragTarget` would inherit the 1×1 size and
///   make it effectively impossible to hit-test drags over the visible canvas
/// - Use this widget whenever you need drag-and-drop across the entire viewport
///   without altering the `_Graph` sizing and transform model
///
/// How it works:
/// - Uses Flutter’s slotted multi-child pattern to host two independently laid out
///   children
/// - The associated `_RenderGraphWithDragTarget`:
///   - Keeps its own size at 1×1 to preserve InteractiveViewer behavior
///   - Lays out the `graph` child with unconstrained constraints at offset zero
///   - Lays out the `dragTarget` child to exactly match the current viewport rect
///   - Overrides hit testing to allow hits anywhere and delegate to children
///
/// Responsibilities:
/// - Ensures correct geometry for both the graph and drag layer without disturbing
///   transforms
/// - Makes drag gestures work across the entire visible area
/// - Keeps rendering predictable by not changing `_Graph`’s size or offsets
///
/// Usage:
/// - Provide the current `viewport` in scene coordinates
/// - Toggle `enableDragTarget` to mount/unmount the drag layer as needed
/// - Pass the `_Graph` subtree to `graph` and the `DragTarget` subtree to `dragTarget`
///
/// Notes:
/// - The `viewport` must be derived from InteractiveViewer (e.g., via quad-to-rect)
/// - Avoid wrapping this widget in additional layout that constrains its size;
///   it intentionally remains 1×1
/// - Put all drag-related gesture logic in the `dragTarget` subtree; element-specific
///   interactions still occur in the `_Graph` subtree
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

/// Render object for slotted graph + drag target composition.
///
/// Purpose:
/// - Maintain a 1×1 render box to keep InteractiveViewer transforms stable
/// - Provide a full-viewport drag layer for reliable drag-and-drop hit testing
///   over the visible graph area
///
/// When/why to use:
/// - Use when you need DragTarget coverage across the viewport without changing
///   the graph’s sizing/transform model. Wrapping the graph directly with a
///   DragTarget would inherit its 1×1 size and break hit testing.
///
/// Children and slots:
/// - `_GraphSlot.graph`:
///   - The graph render object
///   - Laid out with unconstrained `BoxConstraints()`
///   - Positioned at `Offset.zero`
/// - `_GraphSlot.dragTarget`:
///   - The drag layer (typically a `DragTarget`)
///   - Laid out with `BoxConstraints.tight(viewport.size)`
///   - Positioned at `viewport.topLeft`
///   - Mounted only when `enableDragTarget` is true
///
/// Layout:
/// - Layouts the graph child first with unconstrained constraints and places it
///   at the origin. The graph’s own rendering logic handles its internal sizing
///   while the parent remains 1×1.
/// - If enabled, layouts the drag target to exactly match the current viewport
///   rectangle so it can receive drags anywhere on screen.
/// - Sets this render object’s size to `Size(1, 1)` to preserve transform math.
///
/// Painting:
/// - Paints the drag target first (so it participates in hit testing above the
///   canvas), then paints the graph child. This does not alter the graph’s
///   coordinate system.
///
/// Hit testing:
/// - Overrides `hitTest` to be permissive despite the 1×1 size and delegates to
///   children via `hitTestChildren`.
/// - Uses `addWithPaintOffset` so each child receives appropriately transformed
///   positions for its own hit logic.
/// - Ensures drag gestures are discoverable across the whole viewport, while
///   element-specific interactions still work within the graph child.
///
/// Responsibilities and guarantees:
/// - Does not change the graph’s transform or logical coordinates
/// - Enables drag operations over the entire viewport without affecting layout
/// - Keeps performance comparable to a simple two-child paint pass
///
/// Notes:
/// - `enableDragTarget` toggles the drag layer; when false, only the graph is
///   laid out/painted.
/// - `viewport` must be kept in sync with the InteractiveViewer’s visible area.
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

/// RenderObjectWidget that binds [GraphData] to the custom render layer.
///
/// Responsibilities:
/// - Provides [viewport] and grid [data.cellSize] to [_RenderGraph].
/// - Keeps the render object updated when [data] or [viewport] change.
/// - Supplies a specialized element ([_GraphElement]) that virtualizes children
///   to the visible viewport and wires resize affordances when enabled.
///
/// Lifecycle:
/// - [createRenderObject] constructs [_RenderGraph] with initial parameters.
/// - [updateRenderObject] diffs inputs and updates the render object.
/// - [createElement] returns [_GraphElement] to manage child widgets and slots.
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

/// Element that virtualizes graph children and manages keyed slots.
///
/// Responsibilities:
/// - Inflates only children whose bounds intersect the current viewport.
/// - Wraps nodes with [ResizableElement] when resize callbacks are provided
///   by the parent [_Graph].
/// - Maintains stable identity via [GraphIdentifier] slots and optional keys.
/// - Coordinates with [_RenderGraph] by inserting/moving/removing render
///   children using the element's slot as the key.
///
/// Update strategy:
/// - Reuses elements by matching on key first, then on slot to minimize churn.
/// - Deactivates children that scrolled out of view; re-inflates when returning.
/// - Ensures edge bookkeeping in the render object stays consistent as nodes
///   enter/leave view.
class _GraphElement extends RenderObjectElement {
  _GraphElement(super.widget);

  @override
  _RenderGraph get renderObject => super.renderObject as _RenderGraph;

  /// The current list of children of this element.
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

      /// Reference is the [SlottedRenderObjectElement.update] method.
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

        // The only case we can't use `oldSlotChild` is when its widget has a key.
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

/// Custom RenderBox that renders the grid-aligned graph canvas.
///
/// Purpose:
/// - Maintains a 1×1 parent size so InteractiveViewer transformations remain stable
/// - Renders background grid dots, edges between nodes, and node widgets
///
/// Layout:
/// - Lays out each mounted child to its pixel size derived from cell units
/// - Positions children at their top-left offset based on grid coordinates
/// - Keeps edge bookkeeping in sync; prunes forgotten edges in performLayout
///
/// Painting order:
/// - _paintDots (grid) → _paintEdges (connections) → _paintElements (widgets)
///   Elements are painted respecting their priority/z-order.
///
/// Hit testing:
/// - Overrides hitTest to be permissive despite the 1×1 size and delegates to children
/// - hitTestChildren uses addWithPaintOffset so children receive transformed positions
/// - hitTestSelf always returns true to allow gesture routing within the scene
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

  final List<GraphEdge> _edges = [];

  /// To prevent O(n^2) when removing edges during the building phase, we store which ones need to be forgotten.
  /// Then when we start layout, we can remove them all at once from the [_edges].
  final List<GraphEdge> _forgottenEdges = [];

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
      final newEdges = edges?.where((edge) => _edges.none((e) => e == edge));
      if (newEdges != null) {
        _edges.addAll(newEdges);
      }
    } else {
      final element = graph.keyedElements[slot];
      assert(element != null, "Element for slot $slot is null");
      // We forget the edge if neither the source nor the target element is in the graph.
      // If one of them is still visible, we want to keep the edge to show it connected but going offscreen.
      _forgottenEdges.addAll(
        _edges.where(
          (edge) =>
              edge.connectsTo(element!) &&
              !_children.containsKey(edge.source) &&
              !_children.containsKey(edge.target),
        ),
      );
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

    if (_forgottenEdges.isNotEmpty) {
      _edges.retainWhere((edge) => !_forgottenEdges.contains(edge));
      _forgottenEdges.clear();
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

    for (final edge in _edges) {
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

  /// As our size is 1, the default implementation will never allow
  /// any hits because it thinks its always outside of the bounds.
  /// We override this to remove the size check and always hit test.
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

/// Precomputed pixel-space geometry for a graph element.
///
/// Converts a grid-based [GraphElement] (expressed in cell units) into a pixel
/// rectangle using the provided `cellSize`. Provides convenience accessors for
/// position, size, center, and a quick on-screen test against a viewport.
///
/// Why/when to use:
/// - During layout/painting to avoid repeated unit conversions
/// - To determine visibility within the current viewport
/// - To compute edge endpoints based on element bounds
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

/// Utilities for collections of pre-rendered elements.
///
/// Currently exposes a weighted center-of-mass calculation used by the graph
/// to compute an initial centering offset. Larger elements influence the final
/// center more than smaller ones.
extension _PreRenderElementList on Iterable<_PreRenderElement> {
  /// Returns the weighted center-of-mass of all elements in this iterable.
  ///
  /// - Returns `Offset.zero` when empty.
  /// - Weight is proportional to element area (with a baseline of 1.0) so
  ///   larger nodes contribute more to the final center.
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

/// Pre-rendered edge endpoints in pixel space.
///
/// Holds the source and target [_PreRenderElement] for a [GraphEdge] so
/// painters can place connection endpoints on node perimeters without
/// recomputing conversions from grid coordinates for each frame.
///
/// Why/when to use:
/// - During edge painting to obtain pixel-space bounds and centers
/// - To quickly skip edges when either endpoint is missing (off-screen or absent)
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

/// Intent to move selected graph nodes by one grid cell along a direction.
///
/// Consumed by the Graph widget's Actions/Shortcuts (via ManagedActionSet)
/// to translate the current selection on the grid. External code can dispatch
/// this intent to drive keyboard-style nudging in orthogonal directions.
class GraphMoveIntent extends Intent {
  const GraphMoveIntent({required this.direction});

  /// The direction in which to move the nodes.
  final TraversalDirection direction;
}

/// Intent to resize selected graph nodes by one grid cell along a direction.
///
/// Consumed by the Graph widget's Actions/Shortcuts to commit size changes
/// when resize handlers are provided. External code can dispatch this intent
/// to grow or shrink nodes in orthogonal directions, minimum size enforced.
class GraphResizeIntent extends Intent {
  const GraphResizeIntent({required this.direction});

  /// The direction in which to resize the nodes.
  final TraversalDirection direction;
}

/// Intent to pan the viewport so the currently focused graph child is centered.
///
/// Consumed by the Graph widget's Actions handler. Useful for keyboard
/// shortcuts that re-center the canvas on the active/focused element.
class GraphCenterFocusedIntent extends Intent {
  const GraphCenterFocusedIntent();
}
