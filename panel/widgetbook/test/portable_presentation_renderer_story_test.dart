import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

void main() {
  for (final variant in InheritedInspectorLayoutVariant.values) {
    testWidgets(
      "inherited inspector gallery ${variant.name} preserves order and writes",
      (tester) async {
        await tester.pumpWidget(
          FakeApp(
            child: Scaffold(
              body: InheritedInspectorLayoutGallery(variant: variant),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final replaced =
            variant == InheritedInspectorLayoutVariant.replacedDetails;
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .map((editor) => editor.controller.text),
          ["Welcome", "Hello player", "Cooldown", if (!replaced) "10, 20"],
        );
        expect(
          find.text("Entry heading"),
          variant == InheritedInspectorLayoutVariant.excludedHeading
              ? findsNothing
              : findsOneWidget,
        );
        expect(
          find.text("Details replaced"),
          replaced ? findsOneWidget : findsNothing,
        );
        await tester.enterText(find.byType(TextFormField).first, "  Next  ");
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          "Next",
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final variant in InheritedFieldVariant.values) {
    testWidgets(
      "inherited field gallery ${variant.name} preserves control ownership",
      (tester) async {
        await tester.pumpWidget(
          FakeApp(
            child: Scaffold(
              body: InheritedFieldPresentationGallery(variant: variant),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(
          find.text(switch (variant) {
            InheritedFieldVariant.localLabel => "Action name",
            InheritedFieldVariant.explicitControl => "Exact name",
            _ => "Name",
          }),
          findsOneWidget,
        );
        final editor = tester.widget<EditableText>(
          find.byType(EditableText).first,
        );
        if (variant == InheritedFieldVariant.disabled) {
          expect(editor.readOnly, isTrue);
        } else {
          await tester.enterText(
            find.byType(TextFormField).first,
            "  Next quest  ",
          );
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText).first)
                .controller
                .text,
            variant == InheritedFieldVariant.explicitControl
                ? "  Next quest  "
                : "Next quest",
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets("the portable host gallery writes through the shared renderer", (
    tester,
  ) async {
    await tester.pumpWidget(
      const FakeApp(child: Scaffold(body: PortablePresentationGallery())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PortablePresentationRenderer), findsOneWidget);
    expect(find.text("Portable presentation host"), findsOneWidget);
    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Count"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), "Next");
    await tester.enterText(find.byType(TextFormField).at(1), "7");
    await tester.pumpAndSettle();

    expect(find.text("Next"), findsOneWidget);
    expect(find.text("7"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
