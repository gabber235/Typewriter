import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";
import "package:typewriter_panel/shared/ui/components/anchored_overlay/anchored_overlay_config.dart";
import "package:typewriter_panel/shared/ui/components/anchored_overlay/placement_engine.dart";

class AnchoredOverlayPositioned extends SingleChildRenderObjectWidget {
  const AnchoredOverlayPositioned({
    required this.anchorRect,
    required this.overlaySize,
    required this.boundaryRect,
    required this.config,
    required super.child,
    super.key,
  });

  final Rect anchorRect;
  final Size overlaySize;
  final Rect boundaryRect;
  final AnchoredOverlayConfig config;

  @override
  RenderAnchoredOverlayPositioned createRenderObject(BuildContext context) {
    return RenderAnchoredOverlayPositioned(
      anchorRect: anchorRect,
      overlaySize: overlaySize,
      boundaryRect: boundaryRect,
      config: config,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderAnchoredOverlayPositioned renderObject,
  ) {
    renderObject
      ..anchorRect = anchorRect
      ..overlaySize = overlaySize
      ..boundaryRect = boundaryRect
      ..config = config;
  }
}

class RenderAnchoredOverlayPositioned extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderAnchoredOverlayPositioned({
    required Rect anchorRect,
    required Size overlaySize,
    required Rect boundaryRect,
    required AnchoredOverlayConfig config,
  }) : _anchorRect = anchorRect,
       _overlaySize = overlaySize,
       _boundaryRect = boundaryRect,
       _config = config;

  Rect get anchorRect => _anchorRect;
  Rect _anchorRect;
  set anchorRect(Rect value) {
    if (_anchorRect == value) {
      return;
    }
    _anchorRect = value;
    markNeedsLayout();
  }

  Size get overlaySize => _overlaySize;
  Size _overlaySize;
  set overlaySize(Size value) {
    if (_overlaySize == value) {
      return;
    }
    _overlaySize = value;
    markNeedsLayout();
  }

  Rect get boundaryRect => _boundaryRect;
  Rect _boundaryRect;
  set boundaryRect(Rect value) {
    if (_boundaryRect == value) {
      return;
    }
    _boundaryRect = value;
    markNeedsLayout();
  }

  AnchoredOverlayConfig get config => _config;
  AnchoredOverlayConfig _config;
  set config(AnchoredOverlayConfig value) {
    if (_config == value) {
      return;
    }
    _config = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final resolvedSize = constraints.biggest;
    final width = resolvedSize.width.isFinite ? resolvedSize.width : overlaySize.width;
    final height = resolvedSize.height.isFinite ? resolvedSize.height : overlaySize.height;
    size = Size(width, height);

    final currentChild = child;
    if (currentChild == null) {
      return;
    }

    currentChild.layout(BoxConstraints.loose(size), parentUsesSize: true);

    var result = computeAnchoredPlacement(
      AnchoredOverlayPlacementInput(
        anchorRect: anchorRect,
        childSize: currentChild.size,
        overlaySize: overlaySize,
        boundaryRect: boundaryRect,
        config: config,
      ),
    );

    if (currentChild.size != result.size) {
      currentChild.layout(BoxConstraints.tight(result.size), parentUsesSize: true);
      result = AnchoredOverlayPlacementResult(
        offset: result.offset,
        size: currentChild.size,
        side: result.side,
        appliedSteps: result.appliedSteps,
      );
    }

    (currentChild.parentData! as BoxParentData).offset = result.offset;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final currentChild = child;
    if (currentChild == null) {
      return;
    }

    final childParentData = currentChild.parentData! as BoxParentData;
    context.paintChild(currentChild, childParentData.offset + offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final currentChild = child;
    if (currentChild == null) {
      return false;
    }

    final childParentData = currentChild.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (result, transformed) {
        return currentChild.hitTest(result, position: transformed);
      },
    );
  }
}
