import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("groups a map key above its value at narrow widths", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 280,
        child: _renderer(
          type: const MapType(
            key: IntegerType(width: IntegerWidth.signed64),
            value: StringType(),
          ),
          value: MapValue([
            DataMapEntry(
              key: IntegerValue(BigInt.zero),
              value: const StringValue("Welcome"),
            ),
          ]),
        ),
      ),
    );

    expect(find.text("Map entry"), findsOneWidget);
    expect(find.text("0"), findsNothing);

    await tester.tap(find.text("Map entry"));
    await tester.pumpAndSettle();

    final keyLabel = find.text("Key");
    final valueLabel = find.text("Value");
    expect(keyLabel, findsOneWidget);
    expect(valueLabel, findsOneWidget);
    expect(
      tester.getTopLeft(keyLabel).dy,
      lessThan(tester.getTopLeft(valueLabel).dy),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip("Remove entry"));
    await tester.pumpAndSettle();

    expect(find.text("No entries found"), findsOneWidget);
  });

  testWidgets("keeps a string key editor focused through every update", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: const MapValue([
          DataMapEntry(
            key: StringValue("intro"),
            value: StringValue("Welcome"),
          ),
        ]),
      ),
    );

    await tester.tap(find.text("intro"));
    await tester.pumpAndSettle();

    var fields = find.byType(EditableText);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.last, "Hello there");
    await tester.pumpAndSettle();
    await tester.tap(fields.first);
    await tester.pump();

    for (final text in ["o", "op", "ope", "open", "opening"]) {
      tester.testTextInput.enterText(text);
      await tester.pumpAndSettle();

      fields = find.byType(EditableText);
      expect(fields, findsNWidgets(2));
      expect(
        tester.widget<EditableText>(fields.first).focusNode.hasFocus,
        isTrue,
      );
      expect(find.text("Key"), findsOneWidget);
      expect(find.text("Value"), findsOneWidget);
    }

    final values = tester
        .widgetList<EditableText>(fields)
        .map((field) => field.controller.text)
        .toList();
    expect(values, ["opening", "Hello there"]);
  });

  testWidgets("preserves nested editing for a composite key", (tester) async {
    const keyType = RecordType(
      fields: {"name": TypeField(name: "name", type: StringType())},
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: keyType, value: StringType()),
        value: const MapValue([
          DataMapEntry(
            key: DataValue.record({"name": StringValue("before")}),
            value: StringValue("value"),
          ),
        ]),
      ),
    );

    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Key"));
    await tester.pumpAndSettle();

    var fields = find.byType(EditableText);
    expect(fields, findsNWidgets(2));
    await tester.tap(fields.first);
    await tester.pump();

    for (final text in ["a", "arbitrary"]) {
      tester.testTextInput.enterText(text);
      await tester.pumpAndSettle();

      fields = find.byType(EditableText);
      expect(fields, findsNWidgets(2));
      expect(
        tester.widget<EditableText>(fields.first).focusNode.hasFocus,
        isTrue,
      );
      expect(find.text("Value"), findsOneWidget);
    }

    expect(
      tester
          .widgetList<EditableText>(fields)
          .map((field) => field.controller.text),
      ["arbitrary", "value"],
    );
  });

  testWidgets("preserves action based editing for a boolean key", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: BooleanType(), value: StringType()),
        value: const MapValue([
          DataMapEntry(key: BooleanValue(false), value: StringValue("value")),
        ]),
      ),
    );

    await tester.tap(find.text("false"));
    await tester.pumpAndSettle();

    expect(find.byTooltip("Enable"), findsOneWidget);
    await tester.tap(find.byTooltip("Enable"));
    await tester.pumpAndSettle();

    expect(find.text("true"), findsOneWidget);
    expect(find.byTooltip("Disable"), findsOneWidget);
    expect(find.text("Value"), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      "value",
    );
  });

  testWidgets("keeps surviving entry state after removing a sibling", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: const MapValue([
          DataMapEntry(key: StringValue("first"), value: StringValue("one")),
          DataMapEntry(key: StringValue("second"), value: StringValue("two")),
        ]),
      ),
    );

    await tester.tap(find.text("first"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("second"));
    await tester.pumpAndSettle();
    expect(find.text("Key"), findsNWidgets(2));

    await tester.tap(find.byTooltip("Remove entry").first);
    await tester.pumpAndSettle();

    expect(find.text("first"), findsNothing);
    expect(find.text("second"), findsWidgets);
    expect(find.text("Key"), findsOneWidget);
    expect(find.text("Value"), findsOneWidget);
  });
}

const _root = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "MapRoot"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: PresentationNode(
      id: "map",
      element: const MapInputElement(
        control: BoundControl(binding: _root),
        allowAdd: false,
      ),
    ),
  );
}
