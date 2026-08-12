import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/editor_utils.dart";

void main() {
  testWidgets("edits a typed record field through a structured path", (
    tester,
  ) async {
    final type = RecordType(
      fields: {"name": const TypeField(name: "name", type: StringType())},
    );
    final source = await tester.pumpTypedEditor(
      type: type,
      value: RecordValue({"name": const StringValue("Before")}),
      path: DataPath.root.field("name"),
    );

    await tester.enterText(find.byType(TextFormField), "After");
    await tester.pump();

    expect(
      DataPath.root.field("name").read(source.rootValue).valueOrNull,
      const StringValue("After"),
    );
  });

  testWidgets("renders every record field", (tester) async {
    final type = RecordType(
      fields: {
        "title": const TypeField(name: "title", type: StringType()),
        "enabled": const TypeField(name: "enabled", type: BooleanType()),
      },
    );

    final source = await tester.pumpTypedEditor(
      type: type,
      value: RecordValue({
        "title": const StringValue("Example"),
        "enabled": const BooleanValue(true),
      }),
    );

    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Enabled"), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byType(Switch), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(
      DataPath.root.field("enabled").read(source.rootValue).valueOrNull,
      const BooleanValue(false),
    );
  });

  testWidgets("renders list controls from a ListValue", (tester) async {
    await tester.pumpTypedEditor(
      type: const ListType(element: StringType()),
      value: ListValue([
        const StringValue("First"),
        const StringValue("Second"),
      ]),
    );

    expect(find.text("Item 1"), findsOneWidget);
    expect(find.text("Item 2"), findsOneWidget);
    expect(find.byTooltip("Add item"), findsOneWidget);
  });

  testWidgets("renders generated collection empty states", (tester) async {
    await tester.pumpTypedEditor(
      type: const ListType(element: StringType()),
      value: const ListValue([]),
    );

    expect(find.text("No items found"), findsOneWidget);
  });

  testWidgets("renders map entries with typed keys", (tester) async {
    await tester.pumpTypedEditor(
      type: const MapType(
        key: IntegerType(width: IntegerWidth.signed32),
        value: StringType(),
      ),
      value: MapValue([
        DataMapEntry(
          key: IntegerValue(BigInt.one),
          value: const StringValue("One"),
        ),
      ]),
    );

    expect(find.text("1"), findsWidgets);
    expect(find.byTooltip("Add entry"), findsOneWidget);
  });

  testWidgets("localizes an invalid value diagnostic", (tester) async {
    await tester.pumpTypedEditor(
      type: const BooleanType(),
      value: const StringValue("wrong"),
    );

    expect(find.textContaining("requires a boolean binding"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets("disables mutation in read only mode", (tester) async {
    await tester.pumpTypedEditor(
      type: const StringType(),
      value: const StringValue("Locked"),
      readOnly: true,
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });

  testWidgets("disables boolean header actions in read only mode", (
    tester,
  ) async {
    await tester.pumpTypedEditor(
      type: const BooleanType(),
      value: const BooleanValue(true),
      readOnly: true,
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
  });
}
