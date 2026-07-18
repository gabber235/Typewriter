import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/ui/components/anchored_overlay/anchored_overlay_config.dart";
import "package:typewriter_panel/shared/ui/components/anchored_overlay/anchored_overlay_positioned.dart";

void main() {
  testWidgets("positions child using computed offset", (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            height: 220,
            child: AnchoredOverlayPositioned(
              anchorRect: const Rect.fromLTWH(40, 60, 120, 30),
              overlaySize: const Size(300, 220),
              boundaryRect: const Rect.fromLTWH(0, 0, 300, 220),
              config: const AnchoredOverlayConfig(
                preferredSide: AnchoredOverlaySide.bottom,
                sharedAxisConstraintMode: SharedAxisConstraintMode.none,
              ),
              child: const SizedBox(
                key: ValueKey("positioned_child"),
                width: 100,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );

    final rootRect = tester.getRect(find.byType(AnchoredOverlayPositioned));
    final childRect = tester.getRect(
      find.byKey(const ValueKey("positioned_child")),
    );

    expect(childRect.left - rootRect.left, 40);
    expect(childRect.top - rootRect.top, 94);
  });

  testWidgets("match anchor constrains width for vertical sides", (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 240,
          child: AnchoredOverlayPositioned(
            anchorRect: const Rect.fromLTWH(20, 30, 180, 24),
            overlaySize: const Size(320, 240),
            boundaryRect: const Rect.fromLTWH(0, 0, 320, 240),
            config: const AnchoredOverlayConfig(
              preferredSide: AnchoredOverlaySide.bottom,
              sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
            ),
            child: const SizedBox(
              key: ValueKey("positioned_child"),
              width: 90,
              height: 40,
            ),
          ),
        ),
      ),
    );

    final childSize = tester.getSize(
      find.byKey(const ValueKey("positioned_child")),
    );
    expect(childSize.width, 180);
  });

  testWidgets("match anchor constrains height for horizontal sides", (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 240,
          child: AnchoredOverlayPositioned(
            anchorRect: const Rect.fromLTWH(20, 30, 180, 28),
            overlaySize: const Size(320, 240),
            boundaryRect: const Rect.fromLTWH(0, 0, 320, 240),
            config: const AnchoredOverlayConfig(
              preferredSide: AnchoredOverlaySide.left,
              sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
            ),
            child: const SizedBox(
              key: ValueKey("positioned_child"),
              width: 90,
              height: 70,
            ),
          ),
        ),
      ),
    );

    final childSize = tester.getSize(
      find.byKey(const ValueKey("positioned_child")),
    );
    expect(childSize.height, 28);
  });
}
