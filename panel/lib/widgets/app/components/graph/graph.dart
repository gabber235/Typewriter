import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/global_key.dart";
import "package:typewriter_panel/utils/rect.dart";
import "package:typewriter_panel/widgets/app/components/graph/resizable_element.dart";
import "package:vector_math/vector_math_64.dart" hide Colors;

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

class GraphData {
  GraphData({
    required this.cellSize,
    required this.elements,
    required this.edges,
  }) : keyedElements =
            Map.fromIterable(elements, key: (element) => element.id) {
    for (final edge in edges) {
      (elementsConnectedEdges[edge.source] ??= <GraphEdge>[]).add(edge);
      (elementsConnectedEdges[edge.target] ??= <GraphEdge>[]).add(edge);
    }
  }

  final double cellSize;
  final List<GraphElement> elements;
  final List<GraphEdge> edges;

  final Map<GraphIdentifier, GraphElement> keyedElements;
  final Map<GraphIdentifier, List<GraphEdge>> elementsConnectedEdges = {};

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
    return copyWith(
      elements: newElements,
    );
  }

  GraphData resizeChild({
    (GraphIdentifier, int, int)? resize,
  }) {
    if (resize == null) return this;
    final (id, width, height) = resize;
    final newElements = elements.map((element) {
      if (element.id != id) {
        return element;
      }
      return element.copyWith(width: width, height: height);
    }).toList();
    return copyWith(
      elements: newElements,
    );
  }

  GraphData copyWith({
    double? cellSize,
    List<GraphElement>? elements,
    List<GraphEdge>? edges,
  }) =>
      GraphData(
        cellSize: cellSize ?? this.cellSize,
        elements: elements ?? this.elements,
        edges: edges ?? this.edges,
      );

  @override
  String toString() => "GraphData(elements: $elements, edges: $edges)";
}

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
  final int priority;
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
  }) =>
      GraphElement(
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

class GraphIdentifier {
  const GraphIdentifier(this.id);
  final String id;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    return id == (other as GraphIdentifier).id;
  }

  @override
  int get hashCode => id.hashCode;
}

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

abstract class GraphDragData {
  const GraphDragData();

  GraphIdentifier get graphId;
}

enum _GraphSlot {
  graph,
  dragTarget,
}

class GraphDrag extends InheritedWidget {
  const GraphDrag({
    required this.draggingInsideGraph,
    required super.child,
    super.key,
  });

  final ValueNotifier<bool> draggingInsideGraph;

  @override
  bool updateShouldNotify(covariant GraphDrag oldWidget) {
    return draggingInsideGraph != oldWidget.draggingInsideGraph;
  }

  static GraphDrag? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GraphDrag>();
  }

  static GraphDrag of(BuildContext context) {
    final graphDrag = context.dependOnInheritedWidgetOfExactType<GraphDrag>();
    assert(graphDrag != null, "GraphDrag was not a parent in the widget tree");
    return graphDrag!;
  }

  static bool isDraggingInsideGraph(BuildContext context) {
    return of(context).draggingInsideGraph.value;
  }
}

typedef GraphResizeCallback = void Function(GraphIdentifier, int, int);

class Graph extends HookWidget {
  const Graph({
    required this.data,
    this.onElementsDragged,
    this.onElementResize,
    super.key,
  });

  final GraphData data;
  final void Function(List<(GraphElement, int, int)>)? onElementsDragged;
  final GraphResizeCallback? onElementResize;

  Offset center(Size size) {
    final target = data.elements
        .map(
          (element) => _PreRenderElement.fromElement(element, data.cellSize),
        )
        .centerOffMass;

    final center = size.center(-target);
    return center;
  }

  @override
  Widget build(BuildContext context) {
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
            keys: [offset],
          );
          final graphGlobalKey = useGlobalKey();

          final draggingIds = useState<List<GraphIdentifier>>([]);
          final dragStart = useState<Offset?>(null);
          final dragOffset = useState<Offset?>(null);
          final draggingInsideGraph = useState<bool>(false);

          final resizing = useState<(GraphIdentifier, int, int)?>(null);

          return InteractiveViewer.builder(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            alignment: Alignment.center,
            transformationController: controller,
            builder: (context, viewport) {
              final rect = _quadToRect(viewport);
              return _GraphWithDragTarget(
                viewport: rect,
                enableDragTarget: onElementsDragged != null,
                graph: GraphDrag(
                  draggingInsideGraph: draggingInsideGraph,
                  child: _Graph(
                    key: graphGlobalKey,
                    viewport: rect,
                    data: data
                        .offsetChildren(
                          offset: dragOffset.value ?? Offset.zero,
                          ids: draggingIds.value,
                        )
                        .resizeChild(resize: resizing.value),
                    onElementResizeStart: onElementResize == null
                        ? null
                        : (id, width, height) {
                            assert(
                              width > 0 && height > 0,
                              "Width and height must be greater than 0",
                            );
                            resizing.value = (id, width, height);
                          },
                    onElementResizeUpdate: onElementResize == null
                        ? null
                        : (id, width, height) {
                            assert(
                              width > 0 && height > 0,
                              "Width and height must be greater than 0",
                            );

                            resizing.value = (id, width, height);
                          },
                    onElementResizeEnd: onElementResize == null
                        ? null
                        : (id, width, height) {
                            assert(
                              width > 0 && height > 0,
                              "Width and height must be greater than 0",
                            );

                            resizing.value = null;
                            onElementResize!.call(id, width, height);
                          },
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

                    final renderBox = graphGlobalKey.currentContext
                        ?.findRenderObject() as RenderBox?;

                    assert(
                      renderBox != null,
                      "Interactive viewer render box not found",
                    );

                    final offset = renderBox!.globalToLocal(details.offset);

                    dragOffset.value = offset - dragStart.value!;

                    draggingIds.value = data.elements
                        .where(
                          (e) => e.inside(element),
                        )
                        .map((element) => element.id)
                        .toList();
                    draggingInsideGraph.value = true;
                    return true;
                  },
                  onMove: (details) {
                    final renderBox = graphGlobalKey.currentContext
                        ?.findRenderObject() as RenderBox?;

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
                    draggingIds.value = [];
                    dragStart.value = null;
                    dragOffset.value = null;
                    draggingInsideGraph.value = false;
                  },
                  builder: (context, candidateData, rejectedData) {
                    return const SizedBox.expand();
                  },
                ),
              );
            },
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
}

/// A custom slotted render object widget that solves the drag target hit testing problem
/// for the graph component.
///
/// **Problem**: The `_Graph` render object must have a size of 1 for the scaling and
/// rendering to work correctly with the InteractiveViewer's transformation matrix.
/// However, this tiny size means that a `DragTarget` wrapping the graph also gets
/// size 1, making it (nearly) impossible to hit-test drag operations over the actual
/// visible graph area.
///
/// **Solution**: This widget uses Flutter's slotted architecture to manage two
/// separate render objects in different slots:
/// - `graph` slot: Contains the `_Graph` with size 1 at offset zero
/// - `dragTarget` slot: Contains a `DragTarget` sized to cover the entire viewport
///
/// The corresponding `_RenderGraphWithDragTarget` render object:
/// - Maintains the required size of 1 for compatibility
/// - Positions the graph at offset zero with unlimited constraints
/// - Positions the drag target to fully cover the viewport area
/// - Overrides hit testing to always allow hits, circumventing the size restriction
///
/// This approach allows drag operations to work across the entire visible graph
/// while preserving the existing rendering and scaling behavior.
///
/// **Alternative approaches considered**:
/// - Wrapping with DragTarget: Fails due to size 1 constraint
/// - Changing graph size: Breaks existing scaling/rendering logic
/// - Using Stack: Also needs to be sized to cover the entire viewport, but therefore it breaks scaling and rendering logic
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

/// Render object that manages graph and drag target positioning with size constraints.
///
/// This render object is the implementation behind `_GraphWithDragTarget` and handles
/// the core challenge: maintaining a size of 1 (required for graph scaling) while
/// providing proper hit testing for drag operations across the entire viewport.
///
/// **Layout Strategy**:
/// - **Graph child**: Positioned at offset zero with unlimited constraints
///   - The graph will self-constrain to size 1 as required for proper scaling
/// - **Drag target child**: Sized and positioned to exactly cover the viewport
///   - Ensures drag operations work across the entire visible graph area
/// - **This render object**: Always maintains size 1 for compatibility
///
/// **Hit Testing Override**:
/// The default `RenderBox.hitTest` method would reject all hits because our size
/// is 1×1 pixels. We override this to:
/// 1. Always call `hitTestChildren` and `hitTestSelf` regardless of position
/// 2. Allow hits anywhere, letting child widgets handle the actual hit logic
/// 3. The drag target child will handle drag-related hits over the viewport
/// 4. The graph child will handle element-specific hits
///
/// **Why This Architecture Works**:
/// - Graph rendering: Unaffected, still gets size 1 and renders correctly
/// - InteractiveViewer: Still applies transformations correctly to size 1 object
/// - Drag operations: Now work because drag target covers full viewport
/// - Performance: No extra overhead, just different positioning logic
class _RenderGraphWithDragTarget extends RenderBox
    with SlottedContainerRenderObjectMixin<_GraphSlot, RenderBox> {
  _RenderGraphWithDragTarget({
    required Rect viewport,
    required bool enableDragTarget,
  })  : _viewport = viewport,
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
      if (isHit) return true;
    }

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
      if (isHit) return true;
    }

    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;
}

class _Graph extends RenderObjectWidget {
  const _Graph({
    required this.viewport,
    required this.data,
    this.onElementResizeStart,
    this.onElementResizeUpdate,
    this.onElementResizeEnd,
    super.key,
  }) : assert(
          (onElementResizeStart != null &&
                  onElementResizeUpdate != null &&
                  onElementResizeEnd != null) ||
              (onElementResizeStart == null &&
                  onElementResizeUpdate == null &&
                  onElementResizeEnd == null),
          "All resize callbacks must be provided or none at all.",
        );

  final Rect viewport;
  final GraphData data;

  final GraphResizeCallback? onElementResizeStart;
  final GraphResizeCallback? onElementResizeUpdate;
  final GraphResizeCallback? onElementResizeEnd;

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

  /// The current list of children of this element.
  @protected
  @visibleForTesting
  Iterable<Element> get children => _children.values;

  Map<GraphIdentifier, Element> _children = {};
  Map<Key, Element> _keyedChildren = <Key, Element>{};

  @override
  void insertRenderObjectChild(
    RenderBox child,
    GraphIdentifier slot,
  ) {
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
    if (parent.onElementResizeStart != null &&
        parent.onElementResizeUpdate != null &&
        parent.onElementResizeEnd != null) {
      return ResizableElement(
        element: element,
        onResizeStart: parent.onElementResizeStart,
        onResizeUpdate: parent.onElementResizeUpdate,
        onResizeEnd: parent.onElementResizeEnd,
        cellSize: parent.data.cellSize,
        child: child,
      );
    }
    return child;
  }

  Iterable<GraphElement> _viewableChildren() {
    final widget = this.widget as _Graph;

    return widget.data.elements.where((element) {
      final preRenderElement =
          _PreRenderElement.fromElement(element, widget.data.cellSize);
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
          assert(
            () {
              final existingElement = _keyedChildren[newWidgetKey];
              if (existingElement != null) {
                (debugDuplicateKeys ??= <Key, List<Element>>{})
                    .putIfAbsent(newWidgetKey, () => <Element>[existingElement])
                    .add(newChild);
              }
              return true;
            }(),
            "Duplicate key found",
          );
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
  })  : _graph = graph,
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
      final preRenderElement =
          _PreRenderElement.fromElement(element!, cellSize);

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
        canvas.drawCircle(
          offset + Offset(x, y),
          2.0,
          paint,
        );
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

  void _paintElements(
    PaintingContext context,
    Offset offset,
  ) {
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
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
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

  /// We are always inside the bounds of the graph, because otherwise this wouldn't be called.
  @override
  bool hitTestSelf(Offset position) => true;
}

class _PreRenderElement {
  _PreRenderElement({
    required this.element,
    required this.bounds,
  });

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
