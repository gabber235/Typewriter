import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/ui/components/animated_table.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("builds one table and preserves table cell properties", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: AnimatedTable(
        initialItemCount: 1,
        headerRows: const [
          TableRow(children: [Text("Header")]),
        ],
        rowBuilder: (context, index, animation) => const TableRow(
          key: ValueKey("row"),
          decoration: BoxDecoration(color: Colors.red),
          children: [
            TableCell(
              key: ValueKey("cell"),
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Text("Alpha"),
            ),
          ],
        ),
        transitionBuilder: _transition,
      ),
    );

    expect(find.byType(Table), findsOneWidget);
    expect(find.text("Header"), findsOneWidget);
    final cell = tester.widget<TableCell>(find.byKey(const ValueKey("cell")));
    expect(cell.verticalAlignment, TableCellVerticalAlignment.middle);
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byKey(const ValueKey("cell")),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      1,
    );
  });

  testWidgets("inserts and keeps a removed row until its reverse completes", (
    tester,
  ) async {
    final key = GlobalKey<AnimatedTableState>();
    await tester.pumpTestApp(
      settle: false,
      child: AnimatedTable(
        key: key,
        initialItemCount: 1,
        rowBuilder: (context, index, animation) =>
            TableRow(children: [Text("row-$index")]),
        transitionBuilder: _transition,
      ),
    );

    key.currentState!.insertItem(
      1,
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(find.text("row-1"), findsOneWidget);

    key.currentState!.removeItem(
      0,
      (context, animation) => const TableRow(children: [Text("removed")]),
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(find.text("removed"), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 101));
    expect(find.text("removed"), findsNothing);
  });

  testWidgets(
    "reverses an incoming row and avoids overlapping key collisions",
    (tester) async {
      final key = GlobalKey<AnimatedTableState>();
      const rowKey = ValueKey("row");
      const cellKey = ValueKey("cell");
      await tester.pumpTestApp(
        settle: false,
        child: AnimatedTable(
          key: key,
          initialItemCount: 0,
          rowBuilder: (context, index, animation) => const TableRow(
            key: rowKey,
            children: [TableCell(key: cellKey, child: Text("Incoming"))],
          ),
          transitionBuilder: _transition,
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
    await tester.pumpTestApp(
      settle: false,
      child: AnimatedTable(
        key: key,
        initialItemCount: 1,
        emptyBuilder: (context) => const Text("Empty"),
        rowBuilder: (context, index, animation) =>
            const TableRow(children: [Text("Active")]),
        transitionBuilder: _transition,
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
    await tester.pumpTestApp(
      settle: false,
      child: AnimatedTable(
        key: key,
        initialItemCount: 1,
        emptyBuilder: (context) => const Text("Empty"),
        rowBuilder: (context, index, animation) =>
            const TableRow(children: [Text("Active")]),
        transitionBuilder: _transition,
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
    expect(tester.takeException(), isNull);
  });
}

Widget _transition(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
