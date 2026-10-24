/// The side of the anchor where an overlay is placed before overflow handling.
enum AnchoredOverlaySide { top, bottom, left, right }

/// Selects the rectangle that constrains overlay placement.
/// `nearestScope` uses the nearest `AnchoredOverlayScope`, with the full
/// overlay as a fallback. `overlay` always uses the full overlay.
enum BoundaryMode { nearestScope, overlay }

/// Controls whether the overlay shares the anchor's width or height.
enum SharedAxisConstraintMode { none, matchAnchor }

/// Defines placement, sizing, and overflow behavior for an anchored overlay.
class AnchoredOverlayConfig {
  const AnchoredOverlayConfig({
    this.preferredSide = AnchoredOverlaySide.bottom,
    this.spacing = 4,
    this.boundaryMode = BoundaryMode.nearestScope,
    this.sharedAxisConstraintMode = SharedAxisConstraintMode.matchAnchor,
    this.maxWidth,
    this.maxHeight,
  });

  /// The initial side before the placement engine tries overflow resolution.
  final AnchoredOverlaySide preferredSide;

  /// The gap, in logical pixels, between the anchor and overlay.
  final double spacing;

  /// The boundary within which the overlay is kept.
  final BoundaryMode boundaryMode;

  /// Whether the overlay width or height follows the anchor.
  final SharedAxisConstraintMode sharedAxisConstraintMode;

  /// An optional maximum overlay width, in logical pixels.
  final double? maxWidth;

  /// An optional maximum overlay height, in logical pixels.
  final double? maxHeight;
}
