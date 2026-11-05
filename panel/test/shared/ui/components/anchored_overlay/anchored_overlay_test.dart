import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a hidden portal shows no overlay", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        AnchoredOverlayPortal(
          visible: false,

          child: const SizedBox(width: 180, height: 40, child: Text("Anchor")),
          overlayBuilder: (context, _) =>
              const SizedBox(height: 60, child: Text("Overlay")),
        ),
      ),
    );

    expect(panel.shows("Anchor"), isTrue);
    expect(panel.shows("Overlay"), isFalse);
  });

  testWidgets("the overlay follows the portal's visibility", (tester) async {
    final visible = ValueNotifier(false);
    addTearDown(visible.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: visible,
          builder: (context, value, _) => AnchoredOverlayPortal(
            visible: value,

            child: const SizedBox(
              width: 180,
              height: 40,
              child: Text("Anchor"),
            ),
            overlayBuilder: (context, _) =>
                const SizedBox(height: 60, child: Text("Overlay")),
          ),
        ),
      ),
    );
    expect(panel.shows("Overlay"), isFalse);

    visible.value = true;
    await panel.settle();
    expect(panel.shows("Overlay"), isTrue);

    visible.value = false;
    await panel.settle();
    expect(panel.shows("Overlay"), isFalse);
  });

  testWidgets("an overlay below its anchor matches the anchor's width", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Align(
          alignment: Alignment.topLeft,
          child: AnchoredOverlayPortal(
            visible: true,
            config: const AnchoredOverlayConfig(
              preferredSide: AnchoredOverlaySide.bottom,
              sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
            ),
            child: const SizedBox(
              width: 180,
              height: 40,
              child: Text("Anchor"),
            ),
            overlayBuilder: (context, _) =>
                const SizedBox(height: 60, child: Text("Overlay")),
          ),
        ),
      ),
    );

    final anchor = tester.getRect(find.text("Anchor"));
    final overlay = tester.getRect(find.text("Overlay"));
    expect(overlay.width, anchor.width);
    expect(overlay.top, greaterThanOrEqualTo(anchor.bottom));
  });
}
