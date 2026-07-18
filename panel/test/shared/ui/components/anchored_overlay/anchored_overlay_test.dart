import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/ui/components/anchored_overlay/anchored_overlay.dart";
import "package:typewriter_panel/shared/ui/components/anchored_overlay/anchored_overlay_config.dart";
import "../../../../support/test_utils.dart";

void main() {
  group("AnchoredOverlayPortal", () {
    testWidgets("hidden when visible is false", (tester) async {
      await tester.pumpTestApp(
        child: AnchoredOverlayPortal(
          visible: false,
          child: const SizedBox(width: 120, height: 40),
          overlayBuilder: (context, _) {
            return Container(
              key: const ValueKey("overlay_content"),
              height: 60,
              color: Theme.of(context).colorScheme.surface,
            );
          },
        ),
      );

      await tester.pump();
      expect(find.byKey(const ValueKey("overlay_content")), findsNothing);
    });

    testWidgets("shows and hides when visible changes", (tester) async {
      var visible = false;
      late StateSetter setState;

      await tester.pumpTestApp(
        child: StatefulBuilder(
          builder: (context, stateSetter) {
            setState = stateSetter;
            return AnchoredOverlayPortal(
              visible: visible,
              child: const SizedBox(width: 120, height: 40),
              overlayBuilder: (context, _) {
                return Container(
                  key: const ValueKey("overlay_content"),
                  height: 60,
                  color: Theme.of(context).colorScheme.surface,
                );
              },
            );
          },
        ),
      );

      await tester.pump();
      expect(find.byKey(const ValueKey("overlay_content")), findsNothing);

      setState(() {
        visible = true;
      });
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey("overlay_content")), findsOneWidget);

      setState(() {
        visible = false;
      });
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey("overlay_content")), findsNothing);
    });

    testWidgets("match anchor constrains width for bottom side", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: Align(
          alignment: Alignment.topLeft,
          child: AnchoredOverlayPortal(
            visible: true,
            config: const AnchoredOverlayConfig(
              preferredSide: AnchoredOverlaySide.bottom,
              sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
            ),
            child: const SizedBox(width: 180, height: 40),
            overlayBuilder: (context, _) {
              return Container(
                key: const ValueKey("overlay_content"),
                height: 60,
                color: Theme.of(context).colorScheme.surface,
              );
            },
          ),
        ),
      );

      await tester.pump();

      final anchorRect = tester.getRect(find.byType(SizedBox).first);
      final overlayRect = tester.getRect(
        find.byKey(const ValueKey("overlay_content")),
      );
      expect(overlayRect.width, anchorRect.width);
    });
  });
}
