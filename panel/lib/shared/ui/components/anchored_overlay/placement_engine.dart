import "package:typewriter_panel/typewriter_panel.dart";

/// A placement adjustment applied after the preferred side overflows.
enum OverflowResolutionStep { flip, shift, resize }

/// Geometry and configuration consumed by [computeAnchoredPlacement].
///
/// All rectangles and offsets use the overlay's coordinate space. The child
/// size is its unconstrained measured size before overflow resizing.
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

/// The resolved overlay geometry and the adjustments used to obtain it.
///
/// [side] is the side ultimately used for attachment. [appliedSteps] records
/// overflow corrections, which is useful for diagnostics without changing the
/// placement contract.
///
/// [offset] and [size] are expressed in the coordinate space of
/// [AnchoredOverlayPlacementInput.overlaySize].
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

/// Resolves an overlay position without touching the render tree.
///
/// The engine tries the preferred side first. If it does not fit, it tries the
/// opposite side, then shifts the result into the boundary, and finally
/// resizes it when the boundary is smaller than the child.
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

  Offset candidateOffsetFor(
    AnchoredOverlaySide candidateSide,
    Size candidateSize,
  ) {
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

/// Applies the anchor width or height before maximum size constraints.
Size _applySharedAxisSizing({
  required Size childSize,
  required Rect anchorRect,
  required AnchoredOverlaySide side,
  required SharedAxisConstraintMode mode,
}) {
  if (mode != SharedAxisConstraintMode.matchAnchor) {
    return childSize;
  }

  final isVerticalAttach =
      side == AnchoredOverlaySide.top || side == AnchoredOverlaySide.bottom;
  return isVerticalAttach
      ? Size(anchorRect.width, childSize.height)
      : Size(childSize.width, anchorRect.height);
}

Size _applyInitialSizeConstraints(Size size, AnchoredOverlayConfig config) {
  final constrainedWidth = config.maxWidth == null
      ? size.width
      : min(size.width, config.maxWidth!);
  final constrainedHeight = config.maxHeight == null
      ? size.height
      : min(size.height, config.maxHeight!);
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
  final maxLeft = rawMaxLeft < boundaryRect.left
      ? boundaryRect.left
      : rawMaxLeft;
  final maxTop = rawMaxTop < boundaryRect.top ? boundaryRect.top : rawMaxTop;

  final clampedLeft = offset.dx.clamp(boundaryRect.left, maxLeft);
  final clampedTop = offset.dy.clamp(boundaryRect.top, maxTop);
  return Offset(clampedLeft, clampedTop);
}

Size _clampSizeToBoundary(Rect boundaryRect, Size size) {
  return Size(
    min(size.width, boundaryRect.width),
    min(size.height, boundaryRect.height),
  );
}
