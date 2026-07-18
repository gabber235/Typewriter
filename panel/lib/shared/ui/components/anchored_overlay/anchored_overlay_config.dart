enum AnchoredOverlaySide {
  top,
  bottom,
  left,
  right,
}

enum BoundaryMode {
  nearestScope,
  overlay,
}

enum SharedAxisConstraintMode {
  none,
  matchAnchor,
}

class AnchoredOverlayConfig {
  const AnchoredOverlayConfig({
    this.preferredSide = AnchoredOverlaySide.bottom,
    this.spacing = 4,
    this.boundaryMode = BoundaryMode.nearestScope,
    this.sharedAxisConstraintMode = SharedAxisConstraintMode.matchAnchor,
    this.maxWidth,
    this.maxHeight,
  });

  final AnchoredOverlaySide preferredSide;
  final double spacing;
  final BoundaryMode boundaryMode;
  final SharedAxisConstraintMode sharedAxisConstraintMode;
  final double? maxWidth;
  final double? maxHeight;
}
