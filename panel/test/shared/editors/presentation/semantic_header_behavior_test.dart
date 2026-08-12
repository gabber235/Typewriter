import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("combines a scoped alias header with its outer binding", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "outer",
      header: PresentationHeader(
        binding: _root,
        title: "Outer".asStringLiteral,
        initiallyExpanded: true,
      ),
      element: ScopedBindingElement(
        binding: _root,
        scopeBindingId: const BindingId(1),
        child: PresentationNode(
          id: "inner",
          header: PresentationHeader(
            binding: const BindingReference(bindingId: BindingId(1)),
            description: "Inner description".asStringLiteral,
          ),
          element: const DividerElement(),
        ),
      ),
    );

    await tester.pumpTestApp(child: _renderer(presentation: presentation));

    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text("Outer"), findsOneWidget);
    expect(find.text("Inner description"), findsOneWidget);
  });

  testWidgets("keeps headers for distinct bindings nested", (tester) async {
    final field = _root.at(DataPath.root.field("value"));
    final presentation = PresentationNode(
      id: "outer",
      header: PresentationHeader(
        binding: _root,
        title: "Record".asStringLiteral,
        initiallyExpanded: true,
      ),
      element: TypedFieldElement(
        binding: field,
        expectedType: const StringType(),
        presentation: PresentationNode(
          id: "field",
          header: PresentationHeader(
            binding: field,
            title: "Field".asStringLiteral,
            initiallyExpanded: false,
          ),
          element: const DividerElement(),
        ),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: RecordType(
          fields: {"value": const TypeField(name: "value", type: StringType())},
        ),
        value: RecordValue({"value": const StringValue("value")}),
        presentation: presentation,
      ),
    );

    expect(find.byType(ExpansionTile), findsNWidgets(2));
  });

  testWidgets("applies visibility, enabled state, and stable priority", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "actions",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Actions".asStringLiteral,
        actions: [
          _action("hidden", 100, visible: false),
          _action("first", 10),
          _action("second", 10),
          _action("disabled", 1, enabled: false),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: SizedBox(width: 230, child: _renderer(presentation: presentation)),
    );

    expect(find.byTooltip("hidden"), findsNothing);
    expect(find.byTooltip("first"), findsOneWidget);
    expect(find.byTooltip("second"), findsNothing);
    expect(find.byTooltip("More actions"), findsOneWidget);
    await tester.tap(find.byTooltip("More actions"));
    await tester.pumpAndSettle();
    expect(find.text("second"), findsOneWidget);
    final disabled = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, "disabled"),
    );
    expect(disabled.onPressed, isNull);
  });

  testWidgets("places actions before the title, after it, and at the end", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "placement",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Placement".asStringLiteral,
        actions: [
          _action("before", 1, placement: HeaderActionPlacement.beforeTitle),
          _action("after", 1, placement: HeaderActionPlacement.afterTitle),
          _action("end", 1),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: SizedBox(width: 700, child: _renderer(presentation: presentation)),
    );

    final before = tester.getCenter(find.byTooltip("before")).dx;
    final title = tester.getCenter(find.text("Placement")).dx;
    final after = tester.getCenter(find.byTooltip("after")).dx;
    final end = tester.getCenter(find.byTooltip("end")).dx;
    expect(before, lessThan(title));
    expect(after, greaterThan(title));
    expect(end, greaterThan(after));
  });

  testWidgets("applies confirmation before invoking an action", (tester) async {
    final presentation = PresentationNode(
      id: "confirmation",
      element: const TextInputElement(
        control: BoundControl(binding: _root),
        multiline: false,
      ),
      header: PresentationHeader(
        title: "Value".asStringLiteral,
        actions: [
          _action(
            "change",
            1,
            confirmation: HeaderActionConfirmation(
              title: "Confirm".asStringLiteral,
              message: "Apply change".asStringLiteral,
              confirmationLabel: "Apply".asStringLiteral,
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(child: _renderer(presentation: presentation));
    await tester.tap(find.byTooltip("change"));
    await tester.pumpAndSettle();
    expect(find.text("Confirm"), findsOneWidget);
    await tester.tap(find.text("Apply"));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
      "change",
    );
  });

  testWidgets("preserves expansion across value updates", (tester) async {
    final presentation = PresentationNode(
      id: "persistent",
      element: const TextInputElement(
        control: BoundControl(binding: _root),
        multiline: false,
      ),
      header: PresentationHeader(
        title: "Persistent".asStringLiteral,
        initiallyExpanded: false,
      ),
    );

    await tester.pumpTestApp(child: _renderer(presentation: presentation));
    await tester.tap(find.text("Persistent"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "updated");
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets("contributes map actions to collection and entry headers", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: const MapValue([
          DataMapEntry(key: StringValue("key"), value: StringValue("value")),
        ]),
        presentation: const MapType(
          key: StringType(),
          value: StringType(),
        ).generateDefaultPresentation(),
      ),
    );

    expect(find.byTooltip("Add entry"), findsOneWidget);
    expect(find.text("key"), findsOneWidget);
    await tester.tap(find.text("key"));
    await tester.pumpAndSettle();
    expect(find.byTooltip("Remove entry"), findsOneWidget);
  });
}

const _root = BindingReference(bindingId: BindingId(0));

EditorHeaderAction _action(
  String label,
  int priority, {
  bool visible = true,
  bool enabled = true,
  HeaderActionPlacement placement = HeaderActionPlacement.end,
  HeaderActionConfirmation? confirmation,
}) => EditorHeaderAction(
  id: HeaderActionId(namespace: "test", name: label),
  icon: TypedExpression(
    resultType: NamedType(standardTypeRefs.icon),
    expression: LiteralExpression(
      const IconValue.iconify("mdi:plus").typedValue,
    ),
  ),
  label: label.asStringLiteral,
  tooltip: label.asStringLiteral,
  activation: InvokeHeaderAction(
    LocalEditorAction(
      SetValueAction(target: _root, value: label.asStringLiteral),
    ),
  ),
  priority: TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: LiteralExpression(IntegerValue(BigInt.from(priority))),
  ),
  visibleIf: TypedExpression(
    resultType: const BooleanType(),
    expression: LiteralExpression(BooleanValue(visible)),
  ),
  enabledIf: TypedExpression(
    resultType: const BooleanType(),
    expression: LiteralExpression(BooleanValue(enabled)),
  ),
  placement: placement,
  confirmation: confirmation,
);

EditorProtocolRenderer _renderer({
  required PresentationNode presentation,
  TypeExpression type = const StringType(),
  DataValue value = const StringValue("initial"),
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "BehaviorRoot"),
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
