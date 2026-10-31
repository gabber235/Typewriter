import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a scope bounds overlays to its own area", (tester) async {
    Rect? bounds;
    final overlay = GlobalKey();
    await tester.showComponent(
      KeyedSubtree(
        key: overlay,
        child: AnchoredOverlayScope(
          child: SizedBox(
            width: 140,
            height: 70,
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  bounds = AnchoredOverlayScope.maybeScopeBoundsInOverlay(
                    context,
                    overlayBox:
                        overlay.currentContext!.findRenderObject()!
                            as RenderBox,
                  );
                });
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(bounds?.size, const Size(140, 70));
  });

  testWidgets("without a scope overlays are not bounded", (tester) async {
    Rect? bounds = Rect.zero;
    final overlay = GlobalKey();
    await tester.showComponent(
      KeyedSubtree(
        key: overlay,
        child: SizedBox(
          width: 200,
          height: 120,
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                bounds = AnchoredOverlayScope.maybeScopeBoundsInOverlay(
                  context,
                  overlayBox:
                      overlay.currentContext!.findRenderObject()! as RenderBox,
                );
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(bounds, isNull);
  });
}
