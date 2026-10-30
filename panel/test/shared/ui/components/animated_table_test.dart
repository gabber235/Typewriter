import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "a removed row stays until its reverse completes and takes no input",
    (tester) async {
      final key = GlobalKey<AnimatedTableState>();
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          AnimatedTable(
            key: key,
            initialItemCount: 1,
            rowBuilder: (context, index, animation) =>
                TableRow(children: [Text("row-$index")]),
            transitionBuilder: fadeIn,
          ),
        ),
      );

      key.currentState!.insertItem(
        1,
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();
      expect(find.text("row-1"), findsOneWidget);

      var removedTaps = 0;
      key.currentState!.removeItem(
        0,
        (context, animation) => TableRow(
          children: [
            TextButton(
              onPressed: () => removedTaps++,
              child: const Text("removed"),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();
      expect(find.text("removed"), findsOneWidget);
      await tester.tap(find.text("removed"), warnIfMissed: false);
      expect(removedTaps, 0, reason: "a leaving row takes no input");
      await tester.pump(const Duration(milliseconds: 101));
      expect(find.text("removed"), findsNothing);
    },
  );

  testWidgets(
    "reverses an incoming row and avoids overlapping key collisions",
    (tester) async {
      final key = GlobalKey<AnimatedTableState>();
      const rowKey = ValueKey("row");
      const cellKey = ValueKey("cell");
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          AnimatedTable(
            key: key,
            initialItemCount: 0,
            rowBuilder: (context, index, animation) => const TableRow(
              key: rowKey,
              children: [TableCell(key: cellKey, child: Text("Incoming"))],
            ),
            transitionBuilder: fadeIn,
          ),
        ),
      );

      key.currentState!.insertItem(
        0,
        duration: const Duration(milliseconds: 200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      key.currentState!.removeItem(
        0,
        (context, animation) => const TableRow(
          key: rowKey,
          children: [TableCell(key: cellKey, child: Text("Outgoing"))],
        ),
        duration: const Duration(milliseconds: 200),
      );
      key.currentState!.insertItem(
        0,
        duration: const Duration(milliseconds: 200),
      );
      await tester.pump();

      expect(find.text("Outgoing"), findsOneWidget);
      expect(find.text("Incoming"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text("Outgoing"), findsNothing);
      expect(find.text("Incoming"), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("waits for the last outgoing row before showing empty", (
    tester,
  ) async {
    final key = GlobalKey<AnimatedTableState>();
    await tester.showComponent(
      AnimatedTable(
        key: key,
        initialItemCount: 1,
        emptyBuilder: (context) => const Text("Empty"),
        rowBuilder: (context, index, animation) =>
            const TableRow(children: [Text("Active")]),
        transitionBuilder: fadeIn,
      ),
    );

    key.currentState!.removeItem(
      0,
      (context, animation) => const TableRow(children: [Text("Outgoing")]),
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(find.text("Empty"), findsNothing);
    expect(find.text("Outgoing"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text("Empty"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets("keeps one table when data returns during empty transition", (
    tester,
  ) async {
    final key = GlobalKey<AnimatedTableState>();
    await tester.showComponent(
      AnimatedTable(
        key: key,
        initialItemCount: 1,
        emptyBuilder: (context) => const Text("Empty"),
        rowBuilder: (context, index, animation) =>
            const TableRow(children: [Text("Active")]),
        transitionBuilder: fadeIn,
      ),
    );

    key.currentState!.removeItem(
      0,
      (context, animation) => const TableRow(children: [Text("Outgoing")]),
      duration: const Duration(milliseconds: 1),
    );
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byType(Table), findsOneWidget);

    key.currentState!.insertItem(0);
    await tester.pump();
    expect(find.byType(Table), findsOneWidget);
    expect(find.text("Empty"), findsNothing);
    expect(find.text("Active"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
