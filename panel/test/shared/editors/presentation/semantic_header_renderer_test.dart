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
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.expand_more),
        matching: find.byType(IconButton),
      ),
      findsNothing,
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.expand_more)).size, 18);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text("Body"), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.text("Details"));
    await tester.pumpAndSettle();

    expect(find.text("Body"), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
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
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNWidgets(3));
    expect(
      find.ancestor(
        of: find.byIcon(Icons.expand_more),
        matching: find.byType(IconButton),
      ),
      findsNothing,
    );

    final reorderIcons = tester.widgetList<Icones>(
      find.byWidgetPredicate(
        (widget) => widget is Icones && widget.icon == Fa6Solid.bars_staggered,
      ),
    );
    expect(reorderIcons.every((icon) => icon.size == 18), isTrue);

    for (var index = 1; index <= 3; index++) {
      await tester.tap(find.text("Item $index"));
      await tester.pumpAndSettle();
    }

    final handles = find.byType(ReorderableDragStartListener);
    expect(tester.getSize(handles.first), const Size.square(40));
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

  testWidgets("moves expansion with a reordered list item", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("first"), StringValue("second")]),
      ),
    );

    await tester.tap(find.text("Item 1"));
    await tester.pumpAndSettle();
    expect(_expandedItemHeader("Item 1"), findsOneWidget);
    expect(_expandedItemHeader("Item 2"), findsNothing);

    await _dragFirstItemAfterSecond(tester);

    expect(_expandedItemHeader("Item 1"), findsNothing);
    expect(_expandedItemHeader("Item 2"), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      "first",
    );
  });

  testWidgets("does not label default list editors with their index", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("first"), StringValue("second")]),
      ),
    );

    await tester.tap(find.text("Item 1"));
    await tester.tap(find.text("Item 2"));
    await tester.pumpAndSettle();

    expect(find.text("0"), findsNothing);
    expect(find.text("1"), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets("moves expansion between equal list values", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("same"), StringValue("same")]),
      ),
    );

    await tester.tap(find.text("Item 1"));
    await tester.pumpAndSettle();

    await _dragFirstItemAfterSecond(tester);

    expect(_expandedItemHeader("Item 1"), findsNothing);
    expect(_expandedItemHeader("Item 2"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("keeps edited item expansion through reorder", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("first"), StringValue("second")]),
      ),
    );

    await tester.tap(find.text("Item 1"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "updated");
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await _dragFirstItemAfterSecond(tester);

    expect(_expandedItemHeader("Item 1"), findsNothing);
    expect(_expandedItemHeader("Item 2"), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      "updated",
    );
  });

  testWidgets("supports default reorder shortcuts and disables boundaries", (
    tester,
  ) async {
    const type = ListType(element: StringType());
    final shortcuts = {
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

    List<String> values() => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();

    final secondHeaderFocus = await _focusHeaderContainingValue(
      tester,
      "second",
    );
    await _sendAltKey(tester, LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    await _sendAltKey(tester, LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(values(), ["first", "second", "third"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    await _sendAltKey(tester, LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    await _sendAltKey(tester, LogicalKeyboardKey.keyJ);
    await tester.pumpAndSettle();
    expect(values(), ["first", "second", "third"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pumpAndSettle();
    expect(values(), ["first", "third", "second"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    await _sendAltKey(tester, LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);
    expect(secondHeaderFocus.hasPrimaryFocus, isTrue);

    final thirdHeaderFocus = await _focusHeaderContainingValue(tester, "third");
    await _sendAltKey(tester, LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pumpAndSettle();
    expect(values(), ["second", "first", "third"]);
    expect(thirdHeaderFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets("does not reorder a list item from input focus", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("first"), StringValue("second")]),
      ),
    );

    await tester.tap(find.text("Item 2"));
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    field.focusNode.requestFocus();
    await tester.pump();
    await _sendAltKey(tester, LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((field) => field.controller.text),
      ["second"],
    );
    expect(_expandedItemHeader("Item 1"), findsNothing);
    expect(_expandedItemHeader("Item 2"), findsOneWidget);
    expect(field.focusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("centers the focused list header after moving", (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    const viewportKey = ValueKey("list reorder viewport");
    await tester.pumpTestApp(
      child: SizedBox(
        height: 140,
        child: SingleChildScrollView(
          key: viewportKey,
          controller: scrollController,
          child: _renderer(
            type: const ListType(element: StringType()),
            value: const ListValue([
              StringValue("first"),
              StringValue("second"),
              StringValue("third"),
              StringValue("fourth"),
              StringValue("fifth"),
              StringValue("sixth"),
            ]),
          ),
        ),
      ),
    );

    final focusNode = await _focusHeaderWithTitle(tester, "Item 2");
    await _sendAltKey(tester, LogicalKeyboardKey.keyJ);
    await tester.pumpAndSettle();
    await _sendAltKey(tester, LogicalKeyboardKey.keyJ);
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(0));
    _expectHeaderCentered(tester, focusNode, viewportKey);

    await _sendAltKey(tester, LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();

    _expectHeaderCentered(tester, focusNode, viewportKey);
  });

  testWidgets("reorders the innermost focused list item header", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: ListType(element: StringType())),
        value: const ListValue([
          ListValue([StringValue("first"), StringValue("second")]),
          ListValue([StringValue("third")]),
        ]),
      ),
    );

    await tester.tap(find.text("Item 1").first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Item 1").last);
    await tester.tap(find.text("Item 2").first);
    await tester.pumpAndSettle();

    final firstHeaderFocus = await _focusHeaderContainingValue(tester, "first");
    await _sendAltKey(tester, LogicalKeyboardKey.keyJ);
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((field) => field.controller.text),
      ["second", "first"],
    );
    expect(firstHeaderFocus.hasPrimaryFocus, isTrue);
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

  testWidgets("places remove last in a list item header", (tester) async {
    const type = ListType(element: StringType());
    await tester.pumpTestApp(
      child: _renderer(
        type: type,
        value: const ListValue([StringValue("first")]),
      ),
    );

    await tester.tap(find.text("Item 1"));
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.byTooltip("Duplicate item")).dx,
      lessThan(tester.getCenter(find.byTooltip("Remove item")).dx),
    );
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
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.expand_more),
        matching: find.byType(IconButton),
      ),
      findsNothing,
    );
  });

  testWidgets("keeps space below the final map value surface", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: const MapValue([
          DataMapEntry(key: StringValue("key"), value: StringValue("value")),
        ]),
      ),
    );

    await tester.tap(find.text("key"));
    await tester.pumpAndSettle();

    final valueField = find.byWidgetPredicate(
      (widget) => widget is EditableText && widget.controller.text == "value",
    );
    final valueSurface = _smallestAncestorRect<DepthBox>(tester, valueField);
    final entry = _smallestAncestorRect<PresentationHeaderChrome>(
      tester,
      valueField,
    );

    expect(entry.bottom - valueSurface.bottom, 8);
  });

  testWidgets("places remove last in a map entry header", (tester) async {
    final presentation = PresentationNode(
      id: "map",
      element: MapInputElement(
        control: const BoundControl(binding: _root),
        allowAdd: false,
        valuePresentation: PresentationNode(
          id: "value",
          header: PresentationHeader(
            binding: const BindingReference(bindingId: BindingId(2)),
            title: "Value details".asStringLiteral,
            initiallyExpanded: false,
            items: [
              HeaderButtonItem(
                id: const HeaderItemId(namespace: "test", name: "edit"),
                icon: const IconValue.svg(Fa6Solid.pen).asIconLiteral,
                label: "Edit entry".asStringLiteral,
                action: LocalEditorAction(
                  SetValueAction(
                    target: const BindingReference(bindingId: BindingId(2)),
                    value: "updated".asStringLiteral,
                  ),
                ),
              ),
            ],
          ),
          element: const TextInputElement(
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

    await tester.tap(find.text("Value details"));
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.byTooltip("Edit entry")).dx,
      lessThan(tester.getCenter(find.byTooltip("Remove entry")).dx),
    );
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

Finder _expandedItemHeader(String title) {
  final header = find.ancestor(
    of: find.text(title),
    matching: find.byType(InkWell),
  );
  return find.descendant(of: header, matching: find.byIcon(Icons.expand_less));
}

Rect _smallestAncestorRect<T extends Widget>(
  WidgetTester tester,
  Finder descendant,
) {
  final ancestors = find.ancestor(of: descendant, matching: find.byType(T));
  return ancestors
      .evaluate()
      .map((element) => tester.getRect(find.byWidget(element.widget)))
      .reduce(
        (smallest, rect) => rect.height < smallest.height ? rect : smallest,
      );
}

Future<FocusNode> _focusHeaderContainingValue(
  WidgetTester tester,
  String value,
) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
  );
  PresentationHeaderChrome? header;
  tester.element(field).visitAncestorElements((element) {
    if (element.widget case final PresentationHeaderChrome chrome) {
      header = chrome;
      return false;
    }
    return true;
  });
  expect(header, isNotNull);
  final inkWell = tester.widget<InkWell>(
    find
        .descendant(of: find.byWidget(header!), matching: find.byType(InkWell))
        .first,
  );
  final focusNode = inkWell.focusNode!..requestFocus();
  await tester.pumpAndSettle();
  return focusNode;
}

Future<FocusNode> _focusHeaderWithTitle(
  WidgetTester tester,
  String title,
) async {
  final header = find.ancestor(
    of: find.text(title),
    matching: find.byType(PresentationHeaderChrome),
  );
  final inkWell = tester.widget<InkWell>(
    find.descendant(of: header, matching: find.byType(InkWell)).first,
  );
  final focusNode = inkWell.focusNode!..requestFocus();
  await tester.pumpAndSettle();
  return focusNode;
}

void _expectHeaderCentered(
  WidgetTester tester,
  FocusNode focusNode,
  Key viewportKey,
) {
  final focusedHeader = find.byWidgetPredicate(
    (widget) => widget is InkWell && widget.focusNode == focusNode,
  );
  final headerRect = tester.getRect(focusedHeader);
  final viewportRect = tester.getRect(find.byKey(viewportKey));
  expect(headerRect.center.dy, closeTo(viewportRect.center.dy, 0.5));
}

Future<void> _sendAltKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
}

Future<void> _dragFirstItemAfterSecond(WidgetTester tester) async {
  final handles = find.byType(ReorderableDragStartListener);
  final gesture = await tester.startGesture(tester.getCenter(handles.first));
  await tester.pump();
  final secondHandle = tester.getRect(handles.last);
  await gesture.moveTo(
    Offset(secondHandle.center.dx, secondHandle.bottom + 48),
  );
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
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
