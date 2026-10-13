import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/compiled_sdk_controls.stories.dart";

Finder input(String placeholder) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == placeholder,
);

void main() {
  testWidgets(
    "compiled Placement shares row width and preserves exact field writes",
    (tester) async {
      skir.DataValue? written;
      await tester.pumpWidget(
        compiledPlacementStory(width: 340, onValue: (value) => written = value),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(input("X"), findsOneWidget);
      expect(input("Y"), findsOneWidget);
      expect(
        tester.getSize(input("X")).width,
        closeTo(tester.getSize(input("Y")).width, 0.01),
      );
      expect(
        tester.getTopLeft(input("Y")).dx,
        greaterThan(tester.getTopLeft(input("X")).dx),
      );
      expect(find.byType(TextFormField), findsNWidgets(4));
      await tester.enterText(input("X"), "42");
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
      expect(input("X"), findsOneWidget);
      expect(input("Y"), findsOneWidget);
      await tester.enterText(input("Y"), "13");
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
