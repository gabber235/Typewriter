import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

void main() {
  for (final example in CollectionEditorExample.values) {
    testWidgets("collection gallery ${example.name} fits a narrow inspector", (
      tester,
    ) async {
      await _pump(tester, example: example);
      expect(find.byType(PortablePresentationRenderer), findsOneWidget);
      expect(find.text("Quest entries"), findsOneWidget);
      if (example != CollectionEditorExample.unfinishedSteps) {
        expect(
          find.text("The authored value is structurally invalid."),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("an empty collection keeps Add in its header", (tester) async {
    await tester.pumpWidget(
      const FakeApp(
        child: Scaffold(
          body: SizedBox(
            width: 320,
            child: CollectionPresentationGallery(empty: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byTooltip("Add item"), findsOneWidget);
    await tester.tap(find.byTooltip("Add item"));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "collection gallery keeps edited values across width and permission changes",
    (tester) async {
      await _pump(tester, width: 640);
      final field = find.byType(TextFormField).first;
      final original = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      await tester.enterText(field, "An edited arrival");
      await tester.pumpAndSettle();
      await _pump(tester, width: 320, readOnly: true);
      final retained = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(retained.controller, same(original.controller));
      expect(retained.controller.text, "An edited arrival");
      expect(retained.readOnly, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "collection gallery adds and removes through the authored draft",
    (tester) async {
      await _pump(tester);
      expect(find.byType(TextFormField), findsNWidgets(3));
      await tester.tap(find.byTooltip("Add item"));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(4));
      await tester.tap(find.byTooltip("Remove item").last);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  CollectionEditorExample example = CollectionEditorExample.textList,
  double width = 320,
  bool readOnly = false,
}) async {
  await tester.pumpWidget(
    FakeApp(
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: CollectionPresentationGallery(
              example: example,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
