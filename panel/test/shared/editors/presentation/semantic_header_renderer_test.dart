import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
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
    expect(find.byType(PresentationHeaderChrome), findsOneWidget);
    expect(find.byType(Expansible), findsOneWidget);
    expect(find.text("Body"), findsNothing);

    await tester.tap(find.text("Details"));
    await tester.pumpAndSettle();

    expect(find.text("Body"), findsOneWidget);
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
    expect(find.byType(PresentationHeaderChrome), findsOneWidget);
  });

  testWidgets("starts pointer dragging from the rendered reorder handle", (
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
        (widget) => widget is Icones && widget.icon == Fa6Solid.bars_staggered,
      ),
      findsNWidgets(3),
    );
    expect(find.text("Add item"), findsNothing);

    for (var index = 1; index <= 3; index++) {
      await tester.tap(find.text("Item $index"));
      await tester.pumpAndSettle();
    }

    final handles = find.byType(ReorderableDragStartListener);
    final gesture = await tester.startGesture(tester.getCenter(handles.first));
    await tester.pump();
    final lastHandle = tester.getRect(handles.last);
    await gesture.moveTo(Offset(lastHandle.center.dx, lastHandle.bottom + 48));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final values = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(values, ["second", "first", "third"]);
  });

  testWidgets("supports every reorder command and disables boundaries", (
    tester,
  ) async {
    const type = ListType(element: StringType());
    final shortcuts = {
      HeaderItemCommandId(
        itemId: listItemReorderHeaderItemId,
        command: HeaderItemCommand.moveBefore,
      ): [
        SingleActivator(LogicalKeyboardKey.f1),
      ],
      HeaderItemCommandId(
        itemId: listItemReorderHeaderItemId,
        command: HeaderItemCommand.moveAfter,
      ): [
        SingleActivator(LogicalKeyboardKey.f2),
      ],
      HeaderItemCommandId(
        itemId: listItemReorderHeaderItemId,
        command: HeaderItemCommand.moveToStart,
      ): [
        SingleActivator(LogicalKeyboardKey.f3),
      ],
      HeaderItemCommandId(
        itemId: listItemReorderHeaderItemId,
        command: HeaderItemCommand.moveToEnd,
      ): [
        SingleActivator(LogicalKeyboardKey.f4),
      ],
    };
    await tester.pumpTestApp(
      child: _renderer(
        type: type,
        value: const ListValue([
          StringValue("first"),
          StringValue("second"),
          StringValue("third"),
        ]),
        headerShortcuts: shortcuts,
      ),
    );

    for (var index = 1; index <= 3; index++) {
      await tester.tap(find.text("Item $index"));
      await tester.pumpAndSettle();
    }

    Future<void> focusValue(String value) async {
      final field = find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.controller.text == value,
      );
      await tester.tap(field);
      await tester.pump();
    }

    List<String> values() => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();

    await focusValue("second");
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);

    await focusValue("second");
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    expect(values(), ["first", "second", "third"]);

    await focusValue("second");
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pumpAndSettle();
    expect(values(), ["first", "third", "second"]);

    await focusValue("second");
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);

    await focusValue("second");
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);

    await focusValue("third");
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);
  });

  testWidgets("confirms before removing a list item", (tester) async {
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

    await tester.tap(find.byTooltip("Remove item").first);
    await tester.pumpAndSettle();

    expect(find.text("Remove item?"), findsOneWidget);
    expect(
      find.text("Are you sure you want to remove this item?"),
      findsOneWidget,
    );
    expect(find.text("Item 3"), findsOneWidget);

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    expect(find.text("Remove item?"), findsNothing);
    expect(find.text("Item 3"), findsOneWidget);

    await tester.tap(find.byTooltip("Remove item").first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Remove"));
    await tester.pumpAndSettle();

    expect(find.text("Item 3"), findsNothing);
    expect(find.text("Item 2"), findsOneWidget);
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
    expect(find.byType(PresentationHeaderChrome), findsOneWidget);
    expect(find.byTooltip("Remove entry"), findsNothing);
  });

  testWidgets("localizes one invalid header item", (tester) async {
    final presentation = PresentationNode(
      id: "invalid.action",
      element: TextElement("Usable content".asStringLiteral),
      header: PresentationHeader(
        title: "Header".asStringLiteral,
        items: [
          HeaderButtonItem(
            id: const HeaderItemId(namespace: "test", name: "invalid"),
            icon: "not an icon".asStringLiteral,
            label: "Action".asStringLiteral,
            action: LocalEditorAction(
              SetValueAction(target: _root, value: "next".asStringLiteral),
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

  testWidgets("disables a reorder handle without a list item source", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "invalid.reorder",
      element: const DividerElement(),
      header: PresentationHeader(
        title: "Header".asStringLiteral,
        items: [
          HeaderReorderHandleItem(
            id: listItemReorderHeaderItemId,
            label: "Reorder".asStringLiteral,
            source: _root,
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

    final handle = tester.widget<ReorderableDragStartListener>(
      find.byType(ReorderableDragStartListener),
    );
    expect(handle.enabled, isFalse);
    expect(
      find.byTooltip("Reorder source must be a list item binding"),
      findsOneWidget,
    );
  });
}

const _root = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
  PresentationNode? presentation,
  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts = const {},
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
    headerShortcuts: headerShortcuts,
  );
}
