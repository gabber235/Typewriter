import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
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

    expect(find.byType(PresentationHeaderChrome), findsOneWidget);
    expect(find.text("Outer"), findsOneWidget);
    expect(find.text("Inner description"), findsOneWidget);
    final description = tester.widget<SizedBox>(
      find.byKey(const ValueKey(("presentationHeaderDescription", "outer"))),
    );
    expect(description.width, double.infinity);
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

    expect(find.byType(PresentationHeaderChrome), findsNWidgets(2));
  });

  testWidgets("applies visibility, enabled state, and stable priority", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "actions",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Actions".asStringLiteral,
        items: [
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

  testWidgets("places items before the title, after it, and at the end", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "placement",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Placement".asStringLiteral,
        items: [
          _action("before", 1, placement: HeaderActionPlacement.beforeTitle),
          _toggle(
            checked: _trueExpression,
            action: const RealmEditorAction(ReloadRealmAction()),
            label: "after",
            placement: HeaderActionPlacement.afterTitle,
          ),
          _action("end", 1),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: SizedBox(width: 700, child: _renderer(presentation: presentation)),
    );

    final before = tester.getCenter(find.byTooltip("before")).dx;
    final title = tester.getCenter(find.text("Placement")).dx;
    final after = tester.getCenter(find.byType(Checkbox)).dx;
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
        items: [
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

  testWidgets("uses checked as controlled state for a set action", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "toggle.set",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Toggle".asStringLiteral,
        items: [
          _toggle(
            checked: const TypedExpression(
              resultType: BooleanType(),
              expression: BindingExpression(_root),
            ),
            action: LocalEditorAction(
              SetValueAction(target: _root, value: _falseExpression),
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const BooleanType(),
        value: const BooleanValue(true),
        presentation: presentation,
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets("invokes a non set toggle action and preserves checked state", (
    tester,
  ) async {
    var calls = 0;
    final presentation = PresentationNode(
      id: "toggle.realm",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Toggle".asStringLiteral,
        items: [
          _toggle(
            checked: _trueExpression,
            action: const RealmEditorAction(ReloadRealmAction()),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        presentation: presentation,
        headerShortcuts: {
          const HeaderItemCommandId(
            itemId: HeaderItemId(namespace: "test", name: "toggle"),
            command: HeaderItemCommand.activate,
          ): const [
            SingleActivator(LogicalKeyboardKey.f6),
          ],
        },
        onRealmAction: (action) {
          calls++;
          return const MutationSuccess(
            revision: 1,
            value: StringValue("initial"),
          );
        },
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets("renders checked toggles consistently in overflow", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "toggle.overflow",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Toggle".asStringLiteral,
        items: [
          _toggle(
            checked: _trueExpression,
            action: const RealmEditorAction(ReloadRealmAction()),
            confirmation: HeaderActionConfirmation(
              title: "Confirm toggle".asStringLiteral,
              message: "Apply toggle".asStringLiteral,
              confirmationLabel: "Apply".asStringLiteral,
            ),
          ),
        ],
      ),
    );
    final shortcuts = {
      HeaderItemCommandId(
        itemId: HeaderItemId(namespace: "test", name: "toggle"),
        command: HeaderItemCommand.activate,
      ): [
        SingleActivator(LogicalKeyboardKey.f6),
      ],
    };

    await tester.pumpTestApp(
      child: SizedBox(
        width: 700,
        child: _renderer(
          presentation: presentation,
          headerShortcuts: shortcuts,
        ),
      ),
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text("Confirm toggle"), findsOneWidget);
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    await tester.pumpTestApp(
      child: SizedBox(
        width: 150,
        child: _renderer(
          presentation: presentation,
          headerShortcuts: shortcuts,
        ),
      ),
    );
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byTooltip("More actions"));
    await tester.pumpAndSettle();

    final menuItem = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, "Toggle value"),
    );
    expect(menuItem.onPressed, isNotNull);
    expect((menuItem.leadingIcon! as Icones).icon, Ic.baseline_check_box);
    expect(find.byType(RotatingShortcuts), findsOneWidget);
    await tester.tap(find.widgetWithText(MenuItemButton, "Toggle value"));
    await tester.pumpAndSettle();
    expect(find.text("Confirm toggle"), findsOneWidget);
  });

  testWidgets("keeps the built in Boolean toggle visible when narrow", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 150,
        child: _renderer(
          type: const BooleanType(),
          value: const BooleanValue(true),
          presentation: const BooleanType().generateDefaultPresentation(),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byTooltip("More actions"), findsNothing);
  });

  testWidgets("disables invalid and read only local toggles", (tester) async {
    PresentationNode presentation(TypedExpression checked) => PresentationNode(
      id: "toggle.disabled",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Toggle".asStringLiteral,
        items: [
          _toggle(
            checked: checked,
            action: LocalEditorAction(
              SetValueAction(target: _root, value: _falseExpression),
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(presentation: presentation("invalid".asStringLiteral)),
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);

    await tester.pumpTestApp(
      child: _renderer(
        presentation: presentation(_trueExpression),
        readOnly: true,
      ),
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
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
const _trueExpression = TypedExpression(
  resultType: BooleanType(),
  expression: LiteralExpression(BooleanValue(true)),
);
const _falseExpression = TypedExpression(
  resultType: BooleanType(),
  expression: LiteralExpression(BooleanValue(false)),
);

HeaderButtonItem _action(
  String label,
  int priority, {
  bool visible = true,
  bool enabled = true,
  HeaderActionPlacement placement = HeaderActionPlacement.end,
  HeaderActionConfirmation? confirmation,
}) => HeaderButtonItem(
  id: HeaderItemId(namespace: "test", name: label),
  icon: TypedExpression(
    resultType: NamedType(standardTypeRefs.icon),
    expression: LiteralExpression(
      const IconValue.svg(Fa6Solid.plus).typedValue,
    ),
  ),
  label: label.asStringLiteral,
  tooltip: label.asStringLiteral,
  action: LocalEditorAction(
    SetValueAction(target: _root, value: label.asStringLiteral),
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

HeaderBooleanToggleItem _toggle({
  required TypedExpression checked,
  required EditorAction action,
  String label = "Toggle value",
  HeaderActionPlacement placement = HeaderActionPlacement.end,
  HeaderActionConfirmation? confirmation,
}) => HeaderBooleanToggleItem(
  id: const HeaderItemId(namespace: "test", name: "toggle"),
  label: label.asStringLiteral,
  tooltip: label.asStringLiteral,
  checked: checked,
  action: action,
  placement: placement,
  confirmation: confirmation,
);

EditorProtocolRenderer _renderer({
  required PresentationNode presentation,
  TypeExpression type = const StringType(),
  DataValue value = const StringValue("initial"),
  RealmActionExecutor? onRealmAction,
  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts = const {},
  bool readOnly = false,
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
    onRealmAction: onRealmAction,
    headerShortcuts: headerShortcuts,
    readOnly: readOnly,
  );
}
