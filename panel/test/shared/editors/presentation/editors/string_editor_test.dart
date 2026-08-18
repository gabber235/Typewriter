import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/editor_utils.dart";

void main() {
  testWidgets("updates a StringValue", (tester) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Alice"),
    );

    await tester.enterText(find.byType(TextFormField), "Bob");
    await tester.pump();

    expect(source.rootValue, const StringValue("Bob"));
  });

  testWidgets("honors string length constraints", (tester) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(minimumLength: 3),
      value: const StringValue("valid"),
    );

    await tester.enterText(find.byType(TextFormField), "no");
    await tester.pump();

    expect(source.rootValue, const StringValue("valid"));
  });

  testWidgets("supports multiline string input", (tester) async {
    final source = await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Line one"),
    );

    await tester.enterText(find.byType(TextFormField), "Line one\nLine two");
    await tester.pump();

    expect(source.rootValue, const StringValue("Line one\nLine two"));
    expect(find.textContaining("Line two"), findsOneWidget);
  });

  testWidgets("applies declared text input formatters before validation", (
    tester,
  ) async {
    final source = await tester.pumpTypedEditor(
      type: identifierStringType,
      value: const StringValue("before"),
      presentation: const PresentationNode(
        id: "identifier",
        element: TextInputElement(
          control: BoundControl(
            binding: BindingReference(bindingId: BindingId(0)),
          ),
          multiline: false,
          inputFormatters: identifierInputFormats,
        ),
      ),
    );

    final field = find.byType(TextFormField);
    await tester.enterText(field, "My Book!");
    await tester.pump();

    expect(source.rootValue, const StringValue("my_book"));

    await tester.enterText(field, "a_");
    await tester.pump();

    expect(tester.widget<TextFormField>(field).controller?.text, "a_");
    expect(source.rootValue, const StringValue("my_book"));
  });

  testWidgets("renders a literal without an editable field", (tester) async {
    await tester.pumpTypedEditor(
      type: EnumType(
        valueType: const StringType(),
        values: const [StringValue("fixed")],
      ),
      value: const StringValue("fixed"),
    );

    expect(find.text("fixed"), findsWidgets);
    expect(find.byType(Dropdown<DataValue>), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
