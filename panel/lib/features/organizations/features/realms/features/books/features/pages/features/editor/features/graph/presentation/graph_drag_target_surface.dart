import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

enum GraphDragTargetSlot { graph, dragTarget }

class GraphDragTargetSurface
    extends
        SlottedMultiChildRenderObjectWidget<GraphDragTargetSlot, RenderBox> {
  const GraphDragTargetSurface({
    required this.viewport,
    required this.enabled,
    required this.graph,
    required this.dragTarget,
    super.key,
  });

  final Rect viewport;
  final bool enabled;
  final Widget graph;
  final Widget dragTarget;

  @override
  Iterable<GraphDragTargetSlot> get slots => GraphDragTargetSlot.values;

  @override
  Widget? childForSlot(GraphDragTargetSlot slot) {
    return switch (slot) {
      GraphDragTargetSlot.graph => graph,
      GraphDragTargetSlot.dragTarget => enabled ? dragTarget : null,
    };
  }

  @override
  RenderGraphDragTargetSurface createRenderObject(BuildContext context) {
    return RenderGraphDragTargetSurface(viewport: viewport, enabled: enabled);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphDragTargetSurface renderObject,
  ) {
    renderObject
      ..viewport = viewport
      ..enabled = enabled;
  }
}

class RenderGraphDragTargetSurface extends RenderBox
    with SlottedContainerRenderObjectMixin<GraphDragTargetSlot, RenderBox> {
  RenderGraphDragTargetSurface({required Rect viewport, required bool enabled})
    : _viewport = viewport,
      _enabled = enabled;

  Rect _viewport;
  Rect get viewport => _viewport;
  set viewport(Rect value) {
    if (_viewport == value) return;
    _viewport = value;
    markNeedsLayout();
  }

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final graph = childForSlot(GraphDragTargetSlot.graph);
    final dragTarget = childForSlot(GraphDragTargetSlot.dragTarget);
    if (graph != null) {
      graph.layout(const BoxConstraints());
      (graph.parentData! as BoxParentData).offset = Offset.zero;
    }
    if (enabled && dragTarget != null) {
      dragTarget.layout(BoxConstraints.tight(viewport.size));
      (dragTarget.parentData! as BoxParentData).offset = viewport.topLeft;
    }
    size = const Size(1, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final graph = childForSlot(GraphDragTargetSlot.graph);
    final dragTarget = childForSlot(GraphDragTargetSlot.dragTarget);
    if (enabled && dragTarget != null) {
      final parentData = dragTarget.parentData! as BoxParentData;
      context.paintChild(dragTarget, parentData.offset + offset);
    }
    if (graph != null) {
      final parentData = graph.parentData! as BoxParentData;
      context.paintChild(graph, parentData.offset + offset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hitTestChildren(result, position: position) &&
        !hitTestSelf(position)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final graph = childForSlot(GraphDragTargetSlot.graph);
    final dragTarget = childForSlot(GraphDragTargetSlot.dragTarget);
    var anyHit = false;
    if (graph != null) {
      anyHit = _hitChild(result, position, graph);
    }
    if (enabled && dragTarget != null) {
      anyHit = _hitChild(result, position, dragTarget) || anyHit;
    }
    return anyHit;
  }

  bool _hitChild(BoxHitTestResult result, Offset position, RenderBox child) {
    final parentData = child.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  bool hitTestSelf(Offset position) => true;
}
