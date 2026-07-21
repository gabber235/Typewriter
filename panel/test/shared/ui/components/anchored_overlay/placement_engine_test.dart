import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("computeAnchoredPlacement", () {
    test("keeps preferred side when it fits", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(100, 100, 120, 40),
          childSize: const Size(100, 50),
          overlaySize: const Size(400, 400),
          boundaryRect: const Rect.fromLTWH(0, 0, 400, 400),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          ),
        ),
      );

      expect(result.side, AnchoredOverlaySide.bottom);
      expect(result.appliedSteps, isEmpty);
      expect(result.offset.dy, 144);
    });

    test("flips when preferred side overflows and opposite fits", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(80, 180, 120, 20),
          childSize: const Size(110, 90),
          overlaySize: const Size(300, 260),
          boundaryRect: const Rect.fromLTWH(0, 0, 300, 260),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          ),
        ),
      );

      expect(result.side, AnchoredOverlaySide.top);
      expect(result.appliedSteps, contains(OverflowResolutionStep.flip));
    });

    test("shifts before resize when flip cannot fit", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(260, 80, 30, 30),
          childSize: const Size(120, 80),
          overlaySize: const Size(300, 220),
          boundaryRect: const Rect.fromLTWH(0, 0, 300, 220),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          ),
        ),
      );

      expect(result.appliedSteps, contains(OverflowResolutionStep.shift));
      expect(
        result.appliedSteps,
        isNot(contains(OverflowResolutionStep.resize)),
      );
      expect(result.offset.dx + result.size.width, lessThanOrEqualTo(300));
    });

    test("resizes after shift when still overflowing", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(40, 130, 60, 20),
          childSize: const Size(500, 200),
          overlaySize: const Size(260, 180),
          boundaryRect: const Rect.fromLTWH(10, 10, 180, 120),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          ),
        ),
      );

      expect(result.appliedSteps, contains(OverflowResolutionStep.shift));
      expect(result.appliedSteps, contains(OverflowResolutionStep.resize));
      expect(result.size.width, lessThanOrEqualTo(180));
      expect(result.size.height, lessThanOrEqualTo(120));
    });

    test("match anchor width for vertical sides", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(10, 10, 170, 24),
          childSize: const Size(90, 50),
          overlaySize: const Size(320, 200),
          boundaryRect: const Rect.fromLTWH(0, 0, 320, 200),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.top,
            sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
          ),
        ),
      );

      expect(result.size.width, 170);
    });

    test("match anchor height for horizontal sides", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(40, 50, 80, 36),
          childSize: const Size(120, 90),
          overlaySize: const Size(360, 260),
          boundaryRect: const Rect.fromLTWH(0, 0, 360, 260),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.left,
            sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
          ),
        ),
      );

      expect(result.size.height, 36);
    });

    test("respects scoped boundary with shared axis sizing", () {
      final result = computeAnchoredPlacement(
        AnchoredOverlayPlacementInput(
          anchorRect: const Rect.fromLTWH(30, 90, 220, 24),
          childSize: const Size(140, 60),
          overlaySize: const Size(500, 500),
          boundaryRect: const Rect.fromLTWH(20, 80, 180, 100),
          config: const AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
          ),
        ),
      );

      expect(result.appliedSteps, contains(OverflowResolutionStep.shift));
      expect(result.appliedSteps, contains(OverflowResolutionStep.resize));
      expect(result.size.width, lessThanOrEqualTo(180));
      expect(result.offset.dx, greaterThanOrEqualTo(20));
      expect(result.offset.dx + result.size.width, lessThanOrEqualTo(200));
    });
  });
}
