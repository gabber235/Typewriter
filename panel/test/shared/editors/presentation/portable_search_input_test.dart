import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "mapped rows take the compact chrome of the dropdown and share activation",
    (tester) async {
      final fixture = _SearchFixture();
      await fixture.pump(tester, width: 300);
      await fixture.open(tester);
      expect(find.byType(SearchResultCard), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SearchResultRow),
          matching: find.byType(ListTile),
        ),
        findsNWidgets(3),
      );
      await tester.tapAt(tester.getCenter(find.text("Map")));
      await tester.pumpAndSettle();
      expect(fixture.writes, [skir.DataValue.wrapStringValue("Map")]);
      expect(find.byType(SearchResultRow), findsNothing);
      expect(find.text("Map"), findsOneWidget);
      expect(
        find.byKey(const ValueKey("authored_search_summary")),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("result navigation does not depend on platform focus shortcuts", (
    tester,
  ) async {
    final originalShortcuts = Map<ShortcutActivator, Intent>.of(
      typewriterShortcuts,
    );
    addTearDown(() {
      typewriterShortcuts
        ..clear()
        ..addAll(originalShortcuts);
    });
    typewriterShortcuts[const SingleActivator(LogicalKeyboardKey.arrowDown)] =
        const ScrollIntent(direction: AxisDirection.down);
    typewriterShortcuts[const SingleActivator(LogicalKeyboardKey.arrowUp)] =
        const ScrollIntent(direction: AxisDirection.up);
    typewriterShortcuts[const SingleActivator(LogicalKeyboardKey.enter)] =
        const ButtonActivateIntent();
    final fixture = _SearchFixture();
    await fixture.pump(tester);
    await fixture.open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(fixture.writes, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(fixture.value.authoredString, "Map");
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets("focused summary survives a host refresh and reopens", (
    tester,
  ) async {
    final fixture = _SearchFixture();
    await fixture.pump(tester);
    final summary = tester.widget<InkWell>(
      find.byKey(const ValueKey("authored_search_summary")),
    );
    summary.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    fixture.owner.value++;
    await tester.pumpAndSettle();
    expect(summary.focusNode!.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets("selection completion survives a host rebuild during writing", (
    tester,
  ) async {
    final fixture = _SearchFixture(rebuildDuringWrite: true);
    await fixture.pump(tester);
    await fixture.open(tester);
    await tester.tapAt(tester.getCenter(find.text("Map")));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(fixture.value.authoredString, "Map");
    expect(find.byType(QueryBar), findsNothing);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey("authored_search_summary")),
          )
          .focusNode!
          .hasPrimaryFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
  });

  testWidgets("opening a focused summary transfers focus into inline search", (
    tester,
  ) async {
    final fixture = _SearchFixture();
    await fixture.pump(tester);
    final summary = tester.widget<InkWell>(
      find.byKey(const ValueKey("authored_search_summary")),
    );
    summary.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    final decoration = tester
        .widget<InputDecorator>(
          find.descendant(
            of: find.byKey(const ValueKey("authored_search_summary")),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;
    final context = tester.element(find.byType(PortableSearchInput));
    expect(
      decoration.focusedBorder?.borderSide,
      FocusHighlight.focusBorder(context, FocusType.focus),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(fixture.writes, isEmpty);
  });

  testWidgets(
    "search expands inside the field and applies one explicit choice",
    (tester) async {
      final fixture = _SearchFixture();
      await fixture.pump(tester);
      final closed = tester.getTopLeft(find.text("Following field"));

      await fixture.open(tester);
      expect(
        tester.getTopLeft(find.text("Following field")).dy,
        greaterThan(closed.dy),
      );
      expect(find.byType(SearchFrame), findsNothing);
      expect(fixture.writes, isEmpty);
      await tester.tapAt(tester.getCenter(find.text("Map")));
      await tester.pumpAndSettle();

      expect(fixture.writes, [skir.DataValue.wrapStringValue("Map")]);
      expect(find.byType(QueryBar), findsNothing);
      expect(tester.getTopLeft(find.text("Following field")), closed);
      expect(find.text("Map"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "keyboard browsing and cancel leave the authored value unchanged",
    (tester) async {
      final fixture = _SearchFixture();
      await fixture.pump(tester);
      await fixture.open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(fixture.writes, isEmpty);
      expect(
        tester
            .widgetList<ListTile>(find.byType(ListTile))
            .any((row) => row.selected),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(QueryBar), findsNothing);
      expect(fixture.value, skir.DataValue.wrapStringValue("Book"));
      expect(fixture.writes, isEmpty);

      await fixture.open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fixture.writes, [skir.DataValue.wrapStringValue("Map")]);
      expect(find.byType(QueryBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("query and focus survive a host refresh", (tester) async {
    final fixture = _SearchFixture();
    await fixture.pump(tester);
    await fixture.open(tester);
    await tester.enterText(find.byType(TextField), "Ma");
    await tester.pumpAndSettle();
    final focus = FocusManager.instance.primaryFocus;
    fixture.owner.value++;
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      "Ma",
    );
    expect(FocusManager.instance.primaryFocus, same(focus));
    expect(fixture.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "outside click closes search without applying a highlighted result",
    (tester) async {
      final fixture = _SearchFixture();
      await fixture.pump(tester);
      await fixture.open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.text("Following field")));
      await tester.pumpAndSettle();
      expect(find.byType(QueryBar), findsNothing);
      expect(fixture.writes, isEmpty);
    },
  );

  testWidgets(
    "multiple choices apply individually while the field stays open",
    (tester) async {
      final fixture = _SearchFixture(multiple: true);
      await fixture.pump(tester);
      await fixture.open(tester);
      await tester.tapAt(tester.getCenter(find.text("Map")));
      await tester.pumpAndSettle();
      expect(
        fixture.value.authoredItems!.map((item) => item.value.authoredString),
        ["Map"],
      );
      expect(find.byType(QueryBar), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.text("Star")));
      await tester.pumpAndSettle();
      expect(
        fixture.value.authoredItems!.map((item) => item.value.authoredString),
        ["Map", "Star"],
      );
      await tester.tapAt(tester.getCenter(find.text("Map")));
      await tester.pumpAndSettle();
      expect(
        fixture.value.authoredItems!.map((item) => item.value.authoredString),
        ["Star"],
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("rejected selections remain open with feedback", (tester) async {
    final fixture = _SearchFixture(reject: true);
    await fixture.pump(tester);
    await fixture.open(tester);
    await tester.tapAt(tester.getCenter(find.text("Map")));
    await tester.pumpAndSettle();
    expect(find.text("Selection is unavailable"), findsOneWidget);
    expect(find.byType(QueryBar), findsOneWidget);
    expect(fixture.writes, isEmpty);
    expect(fixture.value, skir.DataValue.wrapStringValue("Book"));
  });

  testWidgets("custom values remain explicit choices", (tester) async {
    final fixture = _SearchFixture();
    fixture.control =
        (fixture.control.toMutable()
              ..customValue = skir.ExpressionNode.createInput(
                binding: _SearchFixture.query,
                path: editorRootPath,
              ))
            .toFrozen();
    await fixture.pump(tester);
    await fixture.open(tester);
    await tester.enterText(find.byType(TextField), "Lantern");
    await tester.pumpAndSettle();
    expect(fixture.writes, isEmpty);
    await tester.ensureVisible(find.text("Use this custom value"));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text("Use this custom value")));
    await tester.pumpAndSettle();
    expect(fixture.value, skir.DataValue.wrapStringValue("Lantern"));
    expect(find.byType(QueryBar), findsNothing);
  });

  testWidgets("read only search keeps its summary without opening", (
    tester,
  ) async {
    final fixture = _SearchFixture(readOnly: true);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsNothing);
    expect(fixture.writes, isEmpty);
  });

  testWidgets(
    "configured results fit a narrow inspector and retain appearance",
    (tester) async {
      final fixture = _SearchFixture();
      fixture.control =
          (fixture.control.toMutable()
                ..popup =
                    (skir.PopupAppearance.mutable()
                          ..minimumWidth = numberLiteral(420)
                          ..maximumWidth = numberLiteral(480)
                          ..maximumExtent = numberLiteral(160)
                          ..padding = skir.PresentationInsets.wrapAll(6)
                          ..fill = skir.PresentationColor.wrapValue(
                            literalExpression(
                              skir.DataValue.wrapInteger("4278255360"),
                            ),
                          ))
                        .toFrozen())
              .toFrozen();
      await fixture.pump(tester, width: 240);
      await fixture.open(tester);
      expect(
        tester.getSize(find.byType(SearchTreeResults)).width,
        lessThanOrEqualTo(240),
      );
      expect(
        tester.getSize(find.byType(SearchTreeResults)).height,
        lessThanOrEqualTo(160),
      );
      expect(
        tester
            .widgetList<Material>(find.byType(Material))
            .any((m) => m.color == const Color(0xff00ff00)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

final class _SearchFixture {
  _SearchFixture({
    this.readOnly = false,
    this.multiple = false,
    this.reject = false,
    this.rebuildDuringWrite = false,
  });
  final bool multiple;
  final bool reject;
  final bool rebuildDuringWrite;
  final bool readOnly;
  final owner = ValueNotifier(0);
  late skir.DataValue value = multiple
      ? skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(
            definition: _listDefinition,
            arguments: const [],
          ),
          payload: skir.DataValue.createListValue(items: const []),
        )
      : skir.DataValue.wrapStringValue("Book");
  final writes = <skir.DataValue>[];
  static final target = skir.ExpressionBindingId(value: "target");
  static final row = skir.ExpressionBindingId(value: "row");
  static final query = skir.ExpressionBindingId(value: "query");
  static final rowRead = skir.ExpressionNode.createInput(
    binding: row,
    path: editorRootPath,
  );
  late skir.SearchControl control =
      (skir.SearchControl.mutable()
            ..control =
                (skir.BoundControl.mutable()
                      ..binding = skir.BindingRef(
                        bindingId: target,
                        path: editorRootPath,
                      )
                      ..label = textLiteral("Icon identifier"))
                    .toFrozen()
            ..selectionMode = multiple
                ? skir.SearchSelectionMode.multiple
                : skir.SearchSelectionMode.single
            ..queryBindingId = query
            ..summaryBindingId = skir.ExpressionBindingId(value: "summary")
            ..maximumExtent = numberLiteral(220)
            ..placeholder = textLiteral("Search icons")
            ..provider = skir.SearchProvider.createStaticValues(
              values: literalExpression(
                skir.DataValue.createListValue(
                  items: [
                    for (final name in ["Book", "Map", "Star"])
                      skir.ListItem(
                        id: skir.ItemId(value: name),
                        value: skir.DataValue.wrapStringValue(name),
                      ),
                  ],
                ),
              ),
              result: skir.SearchResultMapping(
                bindingId: row,
                key: rowRead,
                selectedValue: rowRead,
                label: rowRead,
                presentation:
                    (skir.PresentationNode.mutable()
                          ..nodeId = "result"
                          ..element = skir.PresentationElement.wrapText(
                            (skir.TextContent.mutable()..value = rowRead)
                                .toFrozen(),
                          ))
                        .toFrozen(),
              ),
              selectors: const [],
            ))
          .toFrozen();

  Future<void> pump(WidgetTester tester, {double width = 360}) async {
    final host = BoundPresentationHost(
      readOnly: readOnly,
      catalog: CheckedEditorCatalog(
        (skir.EditorCatalogWireSnapshot.mutable()
              ..types = [
                (skir.PublishedType.mutable()
                      ..status = skir.DeclarationStatus.ready
                      ..definition =
                          (skir.TypeDefinition.mutable()
                                ..id = _listDefinition
                                ..representation =
                                    skir.RepresentationTemplate.createSequence(
                                      item: skir.TypeTemplate.wrapScalar(
                                        skir.ScalarKind.text,
                                      ),
                                      kind: skir.CollectionKind.list,
                                    ))
                              .toFrozen())
                    .toFrozen(),
              ])
            .toFrozen(),
      ),
      root: () =>
          (skir.PresentationNode.mutable()
                ..nodeId = "search"
                ..element = skir.PresentationElement.wrapSearchInput(control))
              .toFrozen(),
      bindings: [
        BoundPresentationBinding(
          id: target,
          use: multiple
              ? skir.TypeUse.createNamed(
                  definition: _listDefinition,
                  arguments: const [],
                )
              : skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          owner: owner,
          read: (_) => value,
          write: (_, next) async {
            if (reject) {
              return PortablePresentationWriteResult.rejected([
                const PortablePresentationDiagnostic(
                  code: "unavailable",
                  message: "Selection is unavailable",
                  severity: skir.DiagnosticSeverity.error,
                ),
              ]);
            }
            writes.add(next);
            value = next;
            if (rebuildDuringWrite) {
              owner.value++;
              await Future<void>.delayed(const Duration(milliseconds: 40));
            }
            return const PortablePresentationWriteApplied();
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    );
    addTearDown(host.dispose);
    addTearDown(owner.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortablePresentationRenderer(
                  host: multiple ? _CollectionSearchHost(host) : host,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("Following field"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
  }
}

final _listDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "IconList"),
  revision: 1,
);

final class _CollectionSearchHost implements PortablePresentationHost {
  _CollectionSearchHost(this.delegate);
  final BoundPresentationHost delegate;
  int nextId = 0;
  @override
  void dispose() => delegate.dispose();
  @override
  PortablePresentationDocument get document => delegate.document;
  @override
  bool get enabled => delegate.enabled;
  @override
  bool get readOnly => delegate.readOnly;
  @override
  PortablePresentationCapabilities get capabilities => delegate.capabilities;
  @override
  void addListener(VoidCallback listener) => delegate.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      delegate.removeListener(listener);
  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.commitControl(reference, context: context);
  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.read(reference, context: context);
  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.location(reference, context: context);
  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => delegate.expectedType(reference, context: context);
  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) => delegate.write(reference, value, context: context);
  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction action, {
    required PortableInvocationContext context,
  }) async {
    final local = (action as skir.EditorAction_localWrapper).value;
    switch (local) {
      case skir.LocalEditorAction_insertListItemWrapper(:final value):
        final current = read(value.target, context: context)!;
        return write(
          value.target,
          current.withAuthoredPayload(
            skir.DataValue.createListValue(
              items: [
                ...current.authoredItems!,
                skir.ListItem(
                  id: skir.ItemId(value: "selected.${nextId++}"),
                  value:
                      (value.value as skir.ExpressionNode_literalWrapper).value,
                ),
              ],
            ),
          ),
          context: context,
        );
      case skir.LocalEditorAction_removeListItemWrapper(:final value):
        final current = read(value.target, context: context)!;
        return write(
          value.target,
          current.withAuthoredPayload(
            skir.DataValue.createListValue(
              items: [
                for (final item in current.authoredItems!)
                  if (item.id != value.item) item,
              ],
            ),
          ),
          context: context,
        );
      default:
        return delegate.execute(action, context: context);
    }
  }
}
