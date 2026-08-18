import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "search_input_test_harness.dart";
import "support/editor_utils.dart";

void main() {
  testWidgets("text focus loss and Escape both commit the typed value", (
    tester,
  ) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Before"),
    );
    final field = find.byType(TextFormField);

    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, "Committed");
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();

    expect(source.beginCount, 1);
    expect(source.commitCount, 1);
    expect(source.rootValue, const StringValue("Committed"));

    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, "Dismissed");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(source.cancelCount, 0);
    expect(source.commitCount, 2);
    expect(source.rootValue, const StringValue("Dismissed"));
  });

  testWidgets("Ctrl+Escape cancels back to the focus session origin", (
    tester,
  ) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Before"),
    );
    final field = find.byType(TextFormField);

    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, "Cancelled");
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(source.cancelCount, 1);
    expect(source.commitCount, 0);
    expect(source.rootValue, const StringValue("Before"));
  });

  testWidgets("numeric focus loss commits once", (tester) async {
    final source = await tester.pumpTypedEditor(
      type: const IntegerType(width: IntegerWidth.signed32),
      value: IntegerValue(BigInt.one),
    );
    final field = find.byType(TextFormField);

    await tester.tap(field);
    await tester.enterText(field, "42");
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();

    expect(source.beginCount, 1);
    expect(source.commitCount, 1);
    expect(source.rootValue, IntegerValue(BigInt.from(42)));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets("nested controls preserve their exact mutation path", (
    tester,
  ) async {
    final title = DataPath.root.field("title");
    final source = await tester.pumpTypedEditor(
      type: const RecordType(
        fields: {"title": TypeField(name: "title", type: StringType())},
      ),
      value: RecordValue(const {"title": StringValue("Before")}),
      presentation: PresentationNode(
        id: "title",
        element: TextInputElement(
          control: BoundControl(
            binding: BindingReference(
              bindingId: const BindingId(0),
              path: title,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), "After");
    await tester.pump();

    expect(source.lastUpdatedPath, title);
  });

  testWidgets("multiple search selection waits for Done", (tester) async {
    final source = await tester.pumpTypedEditor(
      type: const ListType(element: StringType()),
      value: const ListValue([StringValue("Alpha")]),
      presentation: searchTestPresentation(multiple: true),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: find.text("Beta"), matching: find.byType(InkWell))
          .first,
    );
    await tester.pump();

    expect(
      source.rootValue,
      const ListValue([StringValue("Alpha"), StringValue("Beta")]),
    );
    expect(source.commitCount, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(source.commitCount, 1);
  });

  testWidgets("search Escape commits the current preview", (tester) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Alpha"),
      presentation: searchTestPresentation(),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(source.cancelCount, 0);
    expect(source.commitCount, 1);
    expect(source.rootValue, const StringValue("Beta"));
  });

  testWidgets("search Ctrl+Escape restores the interaction origin", (
    tester,
  ) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Alpha"),
      presentation: searchTestPresentation(),
    );

    await tester.tap(find.bySemanticsLabel("Activate search input"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(source.cancelCount, 1);
    expect(source.commitCount, 0);
    expect(source.rootValue, const StringValue("Alpha"));
  });

  testWidgets("color picker Escape commits and Ctrl+Escape cancels", (
    tester,
  ) async {
    final source = await tester.pumpTypedEditor(
      type: NamedType(standardTypeRefs.color),
      value: IntegerValue(BigInt.from(0xFF112233)),
      registry: TypeRegistry(const TypeCatalog([])),
      presentation: const PresentationNode(
        id: "color",
        element: ColorInputElement(
          control: BoundControl(
            binding: BindingReference(bindingId: BindingId(0)),
          ),
        ),
      ),
    );

    final swatch = find
        .ancestor(
          of: find.byType(Checkerboard),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(swatch);
    await tester.pumpAndSettle();
    expect(source.beginCount, 1);
    expect(find.byType(ColorPickerSurface), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(source.commitCount, 1);

    await tester.tap(swatch);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(source.cancelCount, 0);
    expect(source.commitCount, 2);

    await tester.tap(swatch);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(source.cancelCount, 1);
    expect(source.commitCount, 2);
  });
}
