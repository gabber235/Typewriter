import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders semantic chrome on content nodes", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("Body"),
        presentation: PresentationNode(
          id: "content",
          element: TextElement("Body".asStringLiteral),
          header: PresentationHeader(
            title: "Details".asStringLiteral,
            initiallyExpanded: false,
          ),
        ),
      ),
    );

    expect(find.text("Details"), findsOneWidget);
    expect(find.byType(ExpansionTile), findsOneWidget);
  });

  testWidgets("combines headers through a typed field binding", (tester) async {
    const list = ListType(element: StringType());
    final presentation = PresentationNode(
      id: "outer",
      header: PresentationHeader(
        binding: _root,
        title: "Combined".asStringLiteral,
      ),
      element: TypedFieldElement(
        binding: _root,
        expectedType: list,
        presentation: const PresentationNode(
          id: "inner",
          element: ListInputElement(control: BoundControl(binding: _root)),
        ),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: list,
        value: const ListValue([]),
        presentation: presentation,
      ),
    );

    expect(find.text("Combined"), findsOneWidget);
    expect(find.byTooltip("Add item"), findsOneWidget);
    expect(find.byType(ExpansionTile), findsOneWidget);
  });

  testWidgets("uses registered list actions and final reorder indexes", (
    tester,
  ) async {
    const type = ListType(element: StringType());
    await tester.pumpTestApp(
      child: _renderer(
        type: type,
        value: const ListValue([
          StringValue("first"),
          StringValue("second"),
          StringValue("third"),
        ]),
      ),
    );

    expect(find.byTooltip("Add item"), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icones && widget.iconify == "mdi:drag",
      ),
      findsNWidgets(3),
    );
    expect(find.text("Add item"), findsNothing);

    for (var index = 1; index <= 3; index++) {
      await tester.tap(find.text("Item $index"));
      await tester.pumpAndSettle();
    }

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(0, 2);
    await tester.pump();

    final values = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(values, ["second", "third", "first"]);
  });

  testWidgets("uses a declared value header for a read only map entry", (
    tester,
  ) async {
    const presentation = PresentationNode(
      id: "map",
      element: MapInputElement(
        control: BoundControl(binding: _root),
        allowAdd: false,
        allowRemove: false,
        valuePresentation: PresentationNode(
          id: "value",
          header: PresentationHeader(
            binding: BindingReference(bindingId: BindingId(2)),
            title: TypedExpression(
              resultType: StringType(),
              expression: LiteralExpression(StringValue("Value details")),
            ),
            initiallyExpanded: false,
          ),
          element: TextInputElement(
            control: BoundControl(
              binding: BindingReference(bindingId: BindingId(2)),
            ),
          ),
        ),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: MapValue(const [
          DataMapEntry(key: StringValue("key"), value: StringValue("value")),
        ]),
        presentation: presentation,
      ),
    );

    expect(find.text("Value details"), findsOneWidget);
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.byTooltip("Remove entry"), findsNothing);
  });

  testWidgets("localizes one invalid header action", (tester) async {
    final presentation = PresentationNode(
      id: "invalid.action",
      element: TextElement("Usable content".asStringLiteral),
      header: PresentationHeader(
        title: "Header".asStringLiteral,
        actions: [
          EditorHeaderAction(
            id: const HeaderActionId(namespace: "test", name: "invalid"),
            icon: "not an icon".asStringLiteral,
            label: "Action".asStringLiteral,
            activation: InvokeHeaderAction(
              LocalEditorAction(
                SetValueAction(target: _root, value: "next".asStringLiteral),
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("value"),
        presentation: presentation,
      ),
    );

    expect(find.text("Usable content"), findsOneWidget);
    final tooltip = find.byTooltip("Header icon must evaluate to Icon");
    final button = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.tooltip == "Header icon must evaluate to Icon",
    );
    expect(tooltip, findsOneWidget);
    expect(button, findsOneWidget);
    expect(tester.widget<IconButton>(button).onPressed, isNull);
  });
}

const _root = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
  PresentationNode? presentation,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "HeaderRoot"),
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
    presentation: presentation,
  );
}
