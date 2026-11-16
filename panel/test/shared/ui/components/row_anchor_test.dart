import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final layout in AnimatedItemsLayout.values) {
    testWidgets(
      "rows another adds or removes above the viewport leave the visible rows where they are (${layout.name})",
      (tester) async {
        final source = await tester.showAnimatedItems(
          numberedItems(60),
          layout: layout,
        );
        await tester.scrollUntilVisible(find.text("Row 30"), 400);
        await tester.pumpAndSettle();
        final before = tester.paintedRectOf(find.text("Row 30"));

        source.update(
          numberedItems(60)
            ..removeAt(3)
            ..insert(1, const AnimatedItem(id: "new", label: "New row")),
        );
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.paintedRectOf(find.text("Row 30")), before);
        }
        await tester.pumpAndSettle();
        expect(tester.paintedRectOf(find.text("Row 30")), before);
      },
    );

    testWidgets(
      "a row added at the top of an unscrolled list is seen arriving (${layout.name})",
      (tester) async {
        final source = await tester.showAnimatedItems(
          numberedItems(3),
          layout: layout,
        );
        source.update([
          const AnimatedItem(id: "new", label: "New row"),
          ...numberedItems(3),
        ]);
        await tester.pumpAndSettle();
        expect(
          tester.paintedRectOf(find.text("New row")).top,
          tester.paintedRectOf(find.byType(Scrollable)).top,
        );
      },
    );
  }
}
