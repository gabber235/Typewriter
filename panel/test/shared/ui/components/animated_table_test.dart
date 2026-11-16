import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("every cell of a loading row arrives together", (tester) async {
    await tester.showAnimatedItems(
      numberedItems(4),
      layout: AnimatedItemsLayout.table,
      columns: 3,
      inPane: true,
      settle: false,
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      for (var row = 0; row < 4; row++) {
        final cells = [
          for (var column = 0; column < 3; column++)
            tester.paintedOpacityOf(find.text("Row $row cell $column")),
        ];
        expect(cells.toSet(), hasLength(1), reason: "row $row moves as one");
      }
    }
    await tester.pumpAndSettle();
  });

  testWidgets(
    "a leaving row stays until it has squashed shut and takes no input",
    (tester) async {
      final source = await tester.showActiveRowTable(
        items: const [
          AnimatedItem(id: "a", label: "Leaving"),
          AnimatedItem(id: "b", label: "Staying"),
        ],
      );

      source.update(const [AnimatedItem(id: "b", label: "Staying")]);
      await tester.pump();
      expect(find.text("Leaving"), findsOneWidget);
      await tester.tap(find.text("Leaving"), warnIfMissed: false);
      expect(source.tapped, isEmpty, reason: "a leaving row takes no input");

      await tester.pumpAndSettle();
      expect(find.text("Leaving"), findsNothing);
    },
  );

  testWidgets("waits for the last leaving row before showing empty", (
    tester,
  ) async {
    final source = await tester.showActiveRowTable();

    source.update(const []);
    await tester.pump();
    expect(find.text("Empty"), findsNothing);
    expect(find.text("Active"), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text("Empty"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("keeps one table when data returns while the last row leaves", (
    tester,
  ) async {
    final source = await tester.showActiveRowTable();

    source.update(const []);
    await tester.pump(const Duration(milliseconds: 16));
    source.update(const [AnimatedItem(id: "a", label: "Active")]);
    await tester.pumpAndSettle();

    expect(find.byType(Table), findsOneWidget);
    expect(find.text("Empty"), findsNothing);
    expect(tester.paintedOpacityOf(find.text("Active")), 1);
    expect(tester.takeException(), isNull);
  });
}
