import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("places the overlay below its anchor", (tester) async {
    await tester.showComponent(
      const SizedBox(
        width: 300,
        height: 220,
        child: AnchoredOverlayPositioned(
          anchorRect: Rect.fromLTWH(40, 60, 120, 30),
          overlaySize: Size(300, 220),
          boundaryRect: Rect.fromLTWH(0, 0, 300, 220),
          config: AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          ),
          child: SizedBox(width: 100, height: 40, child: Text("Overlay")),
        ),
      ),
    );

    final overlay = tester.getRect(find.text("Overlay"));
    final area = tester.getTopLeft(find.byType(AnchoredOverlayPositioned));
    expect(overlay.left - area.dx, 40);
    expect(overlay.top - area.dy, 94);
  });

  testWidgets("an overlay below its anchor matches the anchor's width", (
    tester,
  ) async {
    await tester.showComponent(
      const SizedBox(
        width: 320,
        height: 240,
        child: AnchoredOverlayPositioned(
          anchorRect: Rect.fromLTWH(20, 30, 180, 24),
          overlaySize: Size(320, 240),
          boundaryRect: Rect.fromLTWH(0, 0, 320, 240),
          config: AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.bottom,
            sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
          ),
          child: SizedBox(width: 90, height: 40, child: Text("Overlay")),
        ),
      ),
    );

    expect(tester.getSize(find.text("Overlay")).width, 180);
  });

  testWidgets("an overlay beside its anchor matches the anchor's height", (
    tester,
  ) async {
    await tester.showComponent(
      const SizedBox(
        width: 320,
        height: 240,
        child: AnchoredOverlayPositioned(
          anchorRect: Rect.fromLTWH(20, 30, 180, 28),
          overlaySize: Size(320, 240),
          boundaryRect: Rect.fromLTWH(0, 0, 320, 240),
          config: AnchoredOverlayConfig(
            preferredSide: AnchoredOverlaySide.left,
            sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
          ),
          child: SizedBox(width: 90, height: 70, child: Text("Overlay")),
        ),
      ),
    );

    expect(tester.getSize(find.text("Overlay")).height, 28);
  });
}
