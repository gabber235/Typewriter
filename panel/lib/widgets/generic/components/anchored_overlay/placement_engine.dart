import "dart:math" as math;

import "package:flutter/widgets.dart";
import "package:typewriter_panel/widgets/generic/components/anchored_overlay/anchored_overlay_config.dart";

enum OverflowResolutionStep {
  flip,
  shift,
  resize,
}

class AnchoredOverlayPlacementInput {
  const AnchoredOverlayPlacementInput({
    required this.anchorRect,
    required this.childSize,
    required this.overlaySize,
    required this.boundaryRect,
    required this.config,
  });

  final Rect anchorRect;
  final Size childSize;
  final Size overlaySize;
  final Rect boundaryRect;
  final AnchoredOverlayConfig config;
}

class AnchoredOverlayPlacementResult {
  const AnchoredOverlayPlacementResult({
    required this.offset,
    required this.size,
    required this.side,
    required this.appliedSteps,
  });

  final Offset offset;
  final Size size;
  final AnchoredOverlaySide side;
  final Set<OverflowResolutionStep> appliedSteps;
}

AnchoredOverlayPlacementResult computeAnchoredPlacement(
  AnchoredOverlayPlacementInput input,
) {
  var side = input.config.preferredSide;
  var size = _applyInitialSizeConstraints(
    _applySharedAxisSizing(
      childSize: input.childSize,
      anchorRect: input.anchorRect,
      side: side,
      mode: input.config.sharedAxisConstraintMode,
    ),
    input.config,
  );

  Offset candidateOffsetFor(AnchoredOverlaySide candidateSide, Size candidateSize) {
    return switch (candidateSide) {
      AnchoredOverlaySide.top => Offset(
        input.anchorRect.left,
        input.anchorRect.top - input.config.spacing - candidateSize.height,
      ),
      AnchoredOverlaySide.bottom => Offset(
        input.anchorRect.left,
        input.anchorRect.bottom + input.config.spacing,
      ),
      AnchoredOverlaySide.left => Offset(
        input.anchorRect.left - input.config.spacing - candidateSize.width,
        input.anchorRect.top,
      ),
      AnchoredOverlaySide.right => Offset(
        input.anchorRect.right + input.config.spacing,
        input.anchorRect.top,
      ),
    };
  }

  var offset = candidateOffsetFor(side, size);
  final steps = <OverflowResolutionStep>{};

  if (!_fits(input.boundaryRect, offset, size)) {
    final flippedSide = _flipSide(side);
    final flippedSize = _applyInitialSizeConstraints(
      _applySharedAxisSizing(
        childSize: input.childSize,
        anchorRect: input.anchorRect,
        side: flippedSide,
        mode: input.config.sharedAxisConstraintMode,
      ),
      input.config,
    );
    final flippedOffset = candidateOffsetFor(flippedSide, flippedSize);

    if (_fits(input.boundaryRect, flippedOffset, flippedSize)) {
      side = flippedSide;
      size = flippedSize;
      offset = flippedOffset;
      steps.add(OverflowResolutionStep.flip);
    }
  }

  if (!_fits(input.boundaryRect, offset, size)) {
    offset = _clampOffset(input.boundaryRect, offset, size);
    steps.add(OverflowResolutionStep.shift);
  }

  if (!_fits(input.boundaryRect, offset, size)) {
    size = _clampSizeToBoundary(input.boundaryRect, size);
    offset = _clampOffset(input.boundaryRect, offset, size);
    steps.add(OverflowResolutionStep.resize);
  }

  return AnchoredOverlayPlacementResult(
    offset: offset,
    size: size,
    side: side,
    appliedSteps: steps,
  );
}

Size _applySharedAxisSizing({
  required Size childSize,
  required Rect anchorRect,
  required AnchoredOverlaySide side,
  required SharedAxisConstraintMode mode,
}) {
  if (mode != SharedAxisConstraintMode.matchAnchor) {
    return childSize;
  }

  final isVerticalAttach = side == AnchoredOverlaySide.top || side == AnchoredOverlaySide.bottom;
  return isVerticalAttach
      ? Size(anchorRect.width, childSize.height)
      : Size(childSize.width, anchorRect.height);
}

Size _applyInitialSizeConstraints(
  Size size,
  AnchoredOverlayConfig config,
) {
  final constrainedWidth = config.maxWidth == null ? size.width : math.min(size.width, config.maxWidth!);
  final constrainedHeight = config.maxHeight == null ? size.height : math.min(size.height, config.maxHeight!);
  return Size(constrainedWidth, constrainedHeight);
}

AnchoredOverlaySide _flipSide(AnchoredOverlaySide side) {
  return switch (side) {
    AnchoredOverlaySide.top => AnchoredOverlaySide.bottom,
    AnchoredOverlaySide.bottom => AnchoredOverlaySide.top,
    AnchoredOverlaySide.left => AnchoredOverlaySide.right,
    AnchoredOverlaySide.right => AnchoredOverlaySide.left,
  };
}

bool _fits(Rect boundaryRect, Offset offset, Size size) {
  final rect = offset & size;
  return boundaryRect.left <= rect.left &&
      boundaryRect.top <= rect.top &&
      boundaryRect.right >= rect.right &&
      boundaryRect.bottom >= rect.bottom;
}

Offset _clampOffset(Rect boundaryRect, Offset offset, Size size) {
  final rawMaxLeft = boundaryRect.right - size.width;
  final rawMaxTop = boundaryRect.bottom - size.height;
  final maxLeft = rawMaxLeft < boundaryRect.left ? boundaryRect.left : rawMaxLeft;
  final maxTop = rawMaxTop < boundaryRect.top ? boundaryRect.top : rawMaxTop;

  final clampedLeft = offset.dx.clamp(boundaryRect.left, maxLeft);
  final clampedTop = offset.dy.clamp(boundaryRect.top, maxTop);
  return Offset(clampedLeft, clampedTop);
}

Size _clampSizeToBoundary(Rect boundaryRect, Size size) {
  return Size(
    math.min(size.width, boundaryRect.width),
    math.min(size.height, boundaryRect.height),
  );
}
