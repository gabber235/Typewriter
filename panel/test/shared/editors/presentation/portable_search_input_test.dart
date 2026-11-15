import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("resource results show the resource's appearance", (
    tester,
  ) async {
    final fixture = SearchInputScenario(resources: true);
    final panel = await fixture.show(tester);
    await panel.searchInput.open();

    for (final name in ["Book", "Map", "Star"]) {
      expect(find.text("Resource $name"), findsOneWidget);
    }
    // Resource icons carry no semantics of their own.
    expect(find.byType(ResourceIcon), findsNWidgets(3));
  });

  testWidgets("result navigation does not depend on platform focus shortcuts", (
    tester,
  ) async {
    final originalShortcuts = Map<ShortcutActivator, Intent>.of(
      typewriterShortcuts,
    );
    addTearDown(() {
      typewriterShortcuts
        ..clear()
        ..addAll(originalShortcuts);
    });
    typewriterShortcuts[const SingleActivator(LogicalKeyboardKey.arrowDown)] =
        const ScrollIntent(direction: AxisDirection.down);
    typewriterShortcuts[const SingleActivator(LogicalKeyboardKey.arrowUp)] =
        const ScrollIntent(direction: AxisDirection.up);
    typewriterShortcuts[const SingleActivator(LogicalKeyboardKey.enter)] =
        const ButtonActivateIntent();
    final fixture = SearchInputScenario();
    final panel = await fixture.show(tester);
    await panel.searchInput.open();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.arrowDown);
    expect(fixture.writes, isEmpty);
    await panel.press(LogicalKeyboardKey.enter);
    expect(fixture.value.authoredString, "Map");
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.searchInput.query.isFocused, isTrue);
  });

  testWidgets("moving focus from the query into the results keeps the search "
      "open", (tester) async {
    final fixture = SearchInputScenario();
    final panel = await fixture.show(tester);
    await panel.searchInput.open();

    await panel.press(LogicalKeyboardKey.arrowDown);
    expect(panel.search.result("Book").isFocused, isTrue);
    await panel.press(LogicalKeyboardKey.arrowDown);

    expect(panel.search.result("Map").isFocused, isTrue);
    expect(panel.searchInput.query.exists, isTrue);
    expect(fixture.writes, isEmpty);
  });

  testWidgets("focused summary survives a host refresh and reopens", (
    tester,
  ) async {
    final fixture = SearchInputScenario();
    final panel = await fixture.show(tester);
    await panel.press(LogicalKeyboardKey.tab);
    expect(panel.searchInput.summary.isFocused, isTrue);
    fixture.owner.value++;
    await panel.settle();
    expect(panel.searchInput.summary.isFocused, isTrue);
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.searchInput.query.isFocused, isTrue);
  });

  testWidgets("selection completion survives a host rebuild during writing", (
    tester,
  ) async {
    final fixture = SearchInputScenario(rebuildDuringWrite: true);
    final panel = await fixture.show(tester);
    await panel.searchInput.open();
    await tester.tapAt(tester.getCenter(find.text("Map")));
    // The write takes 40 milliseconds; wait it out before the panel settles.
    await tester.pump(const Duration(milliseconds: 40));
    await panel.settle();
    expect(fixture.value.authoredString, "Map");
    expect(panel.searchInput.query.exists, isFalse);
    expect(panel.searchInput.summary.isFocused, isTrue);
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.searchInput.query.exists, isTrue);
  });

  testWidgets("opening a focused summary transfers focus into inline search", (
    tester,
  ) async {
    final fixture = SearchInputScenario();
    final panel = await fixture.show(tester);
    await panel.press(LogicalKeyboardKey.tab);
    expect(panel.searchInput.summary.isFocused, isTrue);
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.searchInput.query.isFocused, isTrue);
    expect(fixture.writes, isEmpty);
  });

  testWidgets(
    "search expands inside the field and applies one explicit choice",
    (tester) async {
      final fixture = SearchInputScenario();
      final panel = await fixture.show(tester);
      final closed = tester.getTopLeft(find.text("Following field"));

      await panel.searchInput.open();
      final following = tester.getTopLeft(find.text("Following field"));
      expect(following.dy, greaterThan(closed.dy));
      // The results open inline, between the field and what follows it.
      expect(
        tester.getBottomLeft(find.text("Star")).dy,
        lessThan(following.dy),
      );
      expect(fixture.writes, isEmpty);
      await tester.tapAt(tester.getCenter(find.text("Map")));
      await panel.settle();

      expect(fixture.writes, [skir.DataValue.wrapStringValue("Map")]);
      expect(panel.searchInput.query.exists, isFalse);
      expect(tester.getTopLeft(find.text("Following field")), closed);
      expect(find.text("Map"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "keyboard browsing and cancel leave the authored value unchanged",
    (tester) async {
      final fixture = SearchInputScenario();
      final panel = await fixture.show(tester);
      await panel.searchInput.open();
      await panel.press(LogicalKeyboardKey.arrowDown);
      expect(fixture.writes, isEmpty);
      expect(panel.search.result("Book").isFocused, isTrue);

      await panel.press(LogicalKeyboardKey.escape);
      expect(panel.searchInput.query.isFocused, isTrue);
      await panel.press(LogicalKeyboardKey.escape);
      expect(panel.searchInput.query.exists, isFalse);
      expect(fixture.value, skir.DataValue.wrapStringValue("Book"));
      expect(fixture.writes, isEmpty);

      await panel.searchInput.open();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await panel.press(LogicalKeyboardKey.arrowDown);
      await panel.press(LogicalKeyboardKey.enter);
      expect(fixture.writes, [skir.DataValue.wrapStringValue("Map")]);
      expect(panel.searchInput.query.exists, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("query and focus survive a host refresh", (tester) async {
    final fixture = SearchInputScenario();
    final panel = await fixture.show(tester);
    await panel.searchInput.open();
    await panel.searchInput.query.type("Ma");
    fixture.owner.value++;
    await panel.settle();
    expect(panel.searchInput.query.value, "Ma");
    expect(panel.searchInput.query.isFocused, isTrue);
    expect(fixture.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "outside click closes search without applying a highlighted result",
    (tester) async {
      final fixture = SearchInputScenario();
      final panel = await fixture.show(tester);
      await panel.searchInput.open();
      await panel.press(LogicalKeyboardKey.arrowDown);
      await tester.tapAt(tester.getCenter(find.text("Following field")));
      await panel.settle();
      expect(panel.searchInput.query.exists, isFalse);
      expect(fixture.writes, isEmpty);
    },
  );

  group("a list picker's results are a selection of its values", () {
    testWidgets("by pointer alone, a click toggles one value, a toggle click "
        "adds another and a Shift click adds the range in one edit", (
      tester,
    ) async {
      final picker = ListPickerScenario();
      final panel = await picker.show(tester);
      await panel.searchInput.open();

      await panel.search.result("Map").tap();
      expect(picker.entries, ["Map"]);
      expect(panel.search.result("Map").isChecked, isTrue);
      await panel.search.result("Book").toggle();
      expect(picker.entries, ["Map", "Book"]);

      final changes = picker.changes;
      await panel.search.result("Wolf").selectRangeTo();
      expect(picker.entries, ["Map", "Book", "Star", "Wolf"]);
      expect(picker.changes, changes + 1);

      await panel.search.result("Map").tap();
      expect(picker.entries, ["Book", "Star", "Wolf"]);
      expect(panel.search.result("Map").isChecked, isFalse);
      expect(panel.searchInput.query.exists, isTrue);
    });

    testWidgets("by keys alone, Enter and Space toggle the focused value, "
        "Shift with an arrow adds the range and select all adds every value, "
        "then removes them", (tester) async {
      final picker = ListPickerScenario();
      final panel = await picker.show(tester);
      await panel.press(LogicalKeyboardKey.tab);
      await panel.press(LogicalKeyboardKey.enter);
      await panel.press(LogicalKeyboardKey.arrowDown);

      await panel.press(LogicalKeyboardKey.enter);
      expect(picker.entries, ["Book"]);
      await panel.press(LogicalKeyboardKey.space);
      expect(picker.entries, isEmpty);
      await panel.press(LogicalKeyboardKey.space);

      final changes = picker.changes;
      await panel.pressShifted(LogicalKeyboardKey.arrowDown);
      expect(picker.entries, ["Book", "Map"]);
      expect(picker.changes, changes + 1);
      expect(panel.search.result("Map").isFocused, isTrue);

      await panel.pressPrimary(LogicalKeyboardKey.keyA);
      expect(picker.entries, ["Book", "Map", "Star", "Wolf"]);
      await panel.pressPrimary(LogicalKeyboardKey.keyA);
      expect(picker.entries, isEmpty);
      expect(panel.searchInput.query.exists, isTrue);
    });
  });

  testWidgets("rejected selections remain open with feedback", (tester) async {
    final fixture = SearchInputScenario(reject: true);
    final panel = await fixture.show(tester);
    await panel.searchInput.open();
    await tester.tapAt(tester.getCenter(find.text("Map")));
    await panel.settle();
    expect(panel.shows("Selection is unavailable"), isTrue);
    expect(panel.searchInput.query.exists, isTrue);
    expect(fixture.writes, isEmpty);
    expect(fixture.value, skir.DataValue.wrapStringValue("Book"));
  });

  testWidgets("custom values remain explicit choices", (tester) async {
    final fixture = SearchInputScenario();
    fixture.control =
        (fixture.control.toMutable()
              ..customValue = skir.ExpressionNode.createInput(
                binding: _queryBinding,
                path: editorRootPath,
              ))
            .toFrozen();
    final panel = await fixture.show(tester);
    await panel.searchInput.open();
    await panel.searchInput.query.type("Lantern");
    expect(fixture.writes, isEmpty);
    await tester.ensureVisible(find.text("Use this custom value"));
    await panel.settle();
    await tester.tapAt(tester.getCenter(find.text("Use this custom value")));
    await panel.settle();
    expect(fixture.value, skir.DataValue.wrapStringValue("Lantern"));
    expect(panel.searchInput.query.exists, isFalse);
  });

  testWidgets("read only search keeps its summary without opening", (
    tester,
  ) async {
    final fixture = SearchInputScenario(readOnly: true);
    final panel = await fixture.show(tester);
    await panel.tapOn(panel.searchInput.summaryButton);
    expect(panel.searchInput.query.exists, isFalse);
    expect(fixture.writes, isEmpty);
  });

  testWidgets(
    "configured results fit a narrow inspector and retain appearance",
    (tester) async {
      final fixture = SearchInputScenario();
      fixture.control =
          (fixture.control.toMutable()
                ..popup =
                    (skir.PopupAppearance.mutable()
                          ..minimumWidth = numberLiteral(420)
                          ..maximumWidth = numberLiteral(480)
                          ..maximumExtent = numberLiteral(160)
                          ..padding = skir.PresentationInsets.wrapAll(6)
                          ..fill = skir.PresentationColor.wrapValue(
                            literalExpression(
                              skir.DataValue.wrapInteger("4278255360"),
                            ),
                          ))
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(tester, width: 240);
      await panel.searchInput.open();
      // The result surface has no semantics of its own; its size and fill
      // are only reachable through the widget.
      expect(
        tester.getSize(find.byType(SearchTreeResults)).width,
        lessThanOrEqualTo(240),
      );
      expect(
        tester.getSize(find.byType(SearchTreeResults)).height,
        lessThanOrEqualTo(160),
      );
      expect(
        tester
            .widgetList<Material>(find.byType(Material))
            .any((m) => m.color == const Color(0xff00ff00)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

final _queryBinding = skir.ExpressionBindingId(value: "query");
