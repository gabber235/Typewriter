import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets("returns nearest scope bounds in overlay coordinates", (
    tester,
  ) async {
    final scopeKey = GlobalKey();
    Rect? resolved;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: AnchoredOverlayScope(
            child: SizedBox(
              key: scopeKey,
              width: 140,
              height: 70,
              child: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final overlayBox = scopeKey.currentContext
                        ?.findRenderObject();
                    if (overlayBox is RenderBox) {
                      resolved = AnchoredOverlayScope.maybeScopeBoundsInOverlay(
                        context,
                        overlayBox: overlayBox,
                      );
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(resolved, isNotNull);
    expect(resolved!.width, 140);
    expect(resolved!.height, 70);
  });

  testWidgets("returns null without scope ancestor", (tester) async {
    final overlayKey = GlobalKey();
    Rect? resolved;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          key: overlayKey,
          width: 200,
          height: 120,
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final overlayBox = overlayKey.currentContext
                    ?.findRenderObject();
                if (overlayBox is RenderBox) {
                  resolved = AnchoredOverlayScope.maybeScopeBoundsInOverlay(
                    context,
                    overlayBox: overlayBox,
                  );
                }
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(resolved, isNull);
  });
}
