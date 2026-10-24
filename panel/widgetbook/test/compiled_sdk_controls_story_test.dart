import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/compiled_sdk_controls.stories.dart";

Finder input(String placeholder) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == placeholder,
);

Finder coordinate(String axis) => find.descendant(
  of: find.ancestor(of: find.text(axis), matching: find.byType(TextField)),
  matching: find.byType(EditableText),
);

void main() {
  for (final width in [280.0, 400.0]) {
    testWidgets("compiled Book icon search fits a $width inspector", (
      tester,
    ) async {
      AuthoringDocument? document;
      await tester.pumpWidget(
        compiledBookStory(
          width: width,
          onDocument: (value) => document = value,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Iconify identifier"), findsNothing);
      expect(find.text("Iconify"), findsOneWidget);
      expect(find.text("SVG"), findsOneWidget);
      expect(tester.takeException(), isNull);

      final summary = find.byKey(const ValueKey("authored_search_summary"));
      await tester.ensureVisible(summary);
      await tester.tap(summary);
      await tester.pumpAndSettle();
      expect(find.byType(QueryBar), findsOneWidget);
      expect(find.byType(ActionRow), findsNothing);
      await tester.enterText(input("Search icons"), "");
      await tester.pumpAndSettle();
      final longResult = find.text("game-icons:broad-dagger");
      await tester.scrollUntilVisible(
        longResult,
        100,
        scrollable: find.descendant(
          of: find.byType(SearchTreeResults),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(longResult);
      await tester.pumpAndSettle();
      final selected = document
          ?.resource(compiledBookResource)
          ?.authoredField("icon")
          ?.authoredField("value");
      expect(selected?.authoredString, "game-icons:broad-dagger");
      expect(find.byType(QueryBar), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(summary);
      await tester.pumpAndSettle();
      expect(find.byType(QueryBar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        document
            ?.resource(compiledBookResource)
            ?.authoredField("icon")
            ?.authoredField("value")
            ?.authoredString,
        "game-icons:broad-dagger",
      );
      expect(tester.takeException(), isNull);

      Future<void> choose(String name) async {
        await tester.ensureVisible(summary);
        await tester.tap(summary);
        await tester.pumpAndSettle();
        expect(find.byType(QueryBar), findsOneWidget);
        await tester.enterText(input("Search icons"), "");
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(name).last);
        final pointer = await tester.startGesture(
          tester.getCenter(find.text(name).last),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(QueryBar), findsOneWidget);
        await pointer.up();
        await tester.pumpAndSettle();
        expect(find.byType(QueryBar), findsNothing);
        expect(
          document
              ?.resource(compiledBookResource)
              ?.authoredField("icon")
              ?.authoredField("value")
              ?.authoredString,
          name,
        );
        expect(tester.takeException(), isNull);
      }

      await choose("mdi:home");
      await choose("mdi:account");
      await tester.tap(find.text("SVG"));
      await tester.pumpAndSettle();
      const svg =
          '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/></svg>';
      await tester.tap(input("Enter text").last);
      await tester.pumpAndSettle();
      final svgInput = tester.widget<EditableText>(
        find.descendant(
          of: input("Enter text").last,
          matching: find.byType(EditableText),
        ),
      );
      expect(svgInput.focusNode.hasPrimaryFocus, isTrue);
      tester.testTextInput.enterText(svg);
      await tester.pumpAndSettle();
      expect(
        document
            ?.resource(compiledBookResource)
            ?.authoredField("icon")
            ?.authoredField("source")
            ?.authoredString,
        svg,
      );
      await tester.tap(find.text("Iconify"));
      await tester.pumpAndSettle();
      await choose("mdi:star");
      await choose("mdi:home");
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(QueryBar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(QueryBar), findsNothing);
      expect(
        document
            ?.resource(compiledBookResource)
            ?.authoredField("icon")
            ?.authoredField("value")
            ?.authoredString,
        "mdi:home",
      );
      await choose("mdi:account");
    });
  }

  testWidgets(
    "compiled Placement shares row width and preserves exact field writes",
    (tester) async {
      skir.DataValue? written;
      await tester.pumpWidget(
        compiledPlacementStory(width: 340, onValue: (value) => written = value),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(coordinate("X"), findsOneWidget);
      expect(coordinate("Y"), findsOneWidget);
      expect(
        tester.getSize(coordinate("X")).width,
        closeTo(tester.getSize(coordinate("Y")).width, 0.01),
      );
      expect(
        tester.getTopLeft(coordinate("Y")).dx,
        greaterThan(tester.getTopLeft(coordinate("X")).dx),
      );
      expect(find.byType(TextFormField), findsNWidgets(4));
      await tester.enterText(coordinate("X"), "42");
      await tester.pumpAndSettle();
      expect(written?.authoredField("x")?.authoredInteger, BigInt.from(42));
      expect(written?.authoredField("y")?.authoredInteger, BigInt.zero);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(written?.authoredField("x")?.authoredInteger, BigInt.from(42));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "compiled Tag nested Placement edits the owning resource without duplicate fields",
    (tester) async {
      AuthoringDocument? document;
      await tester.pumpWidget(
        compiledTagStory(width: 340, onDocument: (value) => document = value),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(coordinate("X"), findsOneWidget);
      expect(coordinate("Y"), findsOneWidget);
      await tester.enterText(coordinate("Y"), "13");
      await tester.pumpAndSettle();
      final placement = document
          ?.resource(compiledTagResource)
          ?.authoredField("placement");
      expect(placement?.authoredField("y")?.authoredInteger, BigInt.from(13));
      expect(placement?.authoredField("x")?.authoredInteger, BigInt.zero);
      expect(tester.takeException(), isNull);
    },
  );
}
