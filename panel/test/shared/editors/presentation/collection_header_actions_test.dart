import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  test(
    "a rebound configured collection resolves its nested document source",
    () {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.nestedLists,
      );
      addTearDown(scenario.dispose);
      final root = scenario.host.document;
      final scope = PortablePresentationScope(
        bindings: scenario.host.rootInvocation.bindings,
        budget: root.budget,
        operations: testPortableOperations(),
        catalog: scenario.catalog,
        host: scenario.host,
      ).withAuthoredLayout(root.root);
      final nestedPath = skir.ValuePath(
        segments: [
          ...CollectionEditorScenario.entriesPath.segments,
          skir.PathSegment.createItem(id: CollectionEditorScenario.first),
        ],
      );
      final nested = scope.withConfiguredValue(
        skir.BindingRef(bindingId: configuredValueBindingId, path: nestedPath),
      )!;
      final local = skir.BindingRef(
        bindingId: configuredValueBindingId,
        path: editorRootPath,
      );
      final source = nested.sourceReference(local)!;
      expect(source.bindingId, configuredValueBindingId);
      expect(source.path, nestedPath);
      expect(
        root.bindings[source.bindingId]!.value
            .editorValueAt(source.path)
            ?.authoredItems
            ?.single
            .id,
        CollectionEditorScenario.first,
      );

      final action = nested.sourceAction(
        skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createRemoveListItem(
            target: local,
            item: CollectionEditorScenario.first,
          ),
        ),
      );
      final removal =
          (action as skir.EditorAction_localWrapper).value
              as skir.LocalEditorAction_removeListItemWrapper;
      expect(removal.value.target, source);
    },
  );

  testWidgets("a hidden authored removal suppresses its generated equivalent", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      confirmRemoval: true,
      transformLayout: (node) => _withItemHeader(
        node,
        (header) =>
            (header.toMutable()
                  ..items = [
                    for (final item in header.items)
                      if (item case skir.HeaderItem_buttonWrapper(:final value))
                        skir.HeaderItem.wrapButton(
                          (value.toMutable()
                                ..visibleIf = _literal(
                                  skir.DataValue.wrapBoolean(false),
                                ))
                              .toFrozen(),
                        )
                      else
                        item,
                  ])
                .toFrozen(),
      ),
    );
    addTearDown(scenario.dispose);
    await _pump(tester, scenario);

    expect(find.byTooltip("Remove step"), findsNothing);
    // The declaration removes first. It cannot suppress second's removal.
    expect(find.byTooltip("Remove item"), findsOneWidget);
    expect(scenario.value.authoredItems!.map((item) => item.id), [
      CollectionEditorScenario.first,
      CollectionEditorScenario.second,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets("aliased removal keeps one pinned action and its confirmation", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      confirmRemoval: true,
      transformLayout: _aliasCollection,
    );
    addTearDown(scenario.dispose);
    await _pump(tester, scenario, width: 320);

    // Authored removal uses configuredValueBindingId. Generated removal uses
    // the scoped alias. They identify the same source item.
    expect(find.byTooltip("Remove item"), findsOneWidget);
    final remove = find.byTooltip("Remove step").first;
    expect(remove.hitTestable(), findsOneWidget);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text("Remove this step?"), findsOneWidget);
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(scenario.value.authoredItems, hasLength(2));

    await tester.tap(find.byTooltip("Remove step").first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Remove step"));
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.single.id,
      CollectionEditorScenario.second,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("read only source headers keep authored navigation available", (
    tester,
  ) async {
    final actions = <skir.EditorAction>[];
    final navigation = skir.EditorAction.createNavigate(
      resource: _text("quest:details"),
      mode: skir.ResourceNavigationMode.open,
    );
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      capabilities: PortablePresentationCapabilities(
        resourceAction: (action, invocation) async {
          actions.add(action);
          return const PortablePresentationWriteApplied();
        },
      ),
      transformLayout: (node) => _withItemHeader(
        node,
        (header) =>
            (header.toMutable()
                  ..items = [
                    ...header.items,
                    _button("open", "Open details", navigation),
                  ])
                .toFrozen(),
      ),
    );
    addTearDown(scenario.dispose);
    await _pump(tester, scenario, readOnly: true);

    final open = find.widgetWithText(TextButton, "Open details").first;
    expect(tester.widget<TextButton>(open).onPressed, isNotNull);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(actions, [navigation]);
    for (final remove in tester.widgetList<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == "Remove item",
      ),
    )) {
      expect(remove.onPressed, isNull);
    }
    expect(scenario.value.authoredItems, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets("resource deletion stays distinct from source item removal", (
    tester,
  ) async {
    final actions = <skir.EditorAction>[];
    final deletion = skir.EditorAction.createAuthoring(
      capability: skir.CapabilityId(value: "fixture:deleteQuest"),
      targets: _literal(
        skir.DataValue.createListValue(
          items: [
            skir.ListItem(
              id: skir.ItemId(value: "target"),
              value: skir.DataValue.wrapStringValue("quest:captured"),
            ),
          ],
        ),
      ),
      initialInput: null,
    );
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      capabilities: PortablePresentationCapabilities(
        resourceAction: (action, invocation) async {
          actions.add(action);
          return const PortablePresentationWriteApplied();
        },
      ),
      transformLayout: (node) => _withItemHeader(
        node,
        (header) =>
            (header.toMutable()
                  ..items = [
                    ...header.items,
                    _button("deleteQuest", "Delete quest", deletion),
                  ])
                .toFrozen(),
      ),
    );
    addTearDown(scenario.dispose);
    await _pump(tester, scenario);

    expect(find.byTooltip("Remove item"), findsNWidgets(2));
    await tester.tap(find.widgetWithText(TextButton, "Delete quest").first);
    await tester.pumpAndSettle();
    // This public host boundary test establishes forwarding. Resource
    // admission and selection effects remain in their existing contract tests.
    expect(actions, [deletion]);
    expect(scenario.value.authoredItems, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  CollectionEditorScenario scenario, {
  double width = 640,
  bool readOnly = false,
}) async {
  await tester.pumpTestApp(
    child: Material(
      child: SizedBox(
        width: width,
        child: CollectionEditorScenarioView(
          scenario: scenario,
          readOnly: readOnly,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

skir.PresentationNode _withItemHeader(
  skir.PresentationNode root,
  skir.PresentationHeader Function(skir.PresentationHeader) transform,
) {
  final control =
      (root.element! as skir.PresentationElement_listInputWrapper).value;
  final item = control.itemPresentation!;
  return (root.toMutable()
        ..element = skir.PresentationElement.wrapListInput(
          (control.toMutable()
                ..itemPresentation =
                    (item.toMutable()..header = transform(item.header!))
                        .toFrozen())
              .toFrozen(),
        ))
      .toFrozen();
}

skir.PresentationNode _aliasCollection(skir.PresentationNode root) {
  final alias = skir.ExpressionBindingId(value: "fixture.collectionAlias");
  final control =
      (root.element! as skir.PresentationElement_listInputWrapper).value;
  final aliasedControl =
      (control.control.toMutable()
            ..binding = skir.BindingRef(
              bindingId: alias,
              path: CollectionEditorScenario.entriesPath,
            ))
          .toFrozen();
  final child =
      (root.toMutable()
            ..element = skir.PresentationElement.wrapListInput(
              (control.toMutable()..control = aliasedControl).toFrozen(),
            ))
          .toFrozen();
  return skir.PresentationNode(
    nodeId: "fixture.alias",
    properties: skir.PresentationProperties.defaultInstance,
    header: null,
    element: skir.PresentationElement.createScopedBinding(
      binding: skir.BindingRef(
        bindingId: configuredValueBindingId,
        path: editorRootPath,
      ),
      scopeBindingId: alias,
      child: child,
    ),
  );
}

skir.ExpressionNode _literal(skir.DataValue value) =>
    skir.ExpressionNode.wrapLiteral(value);
skir.ExpressionNode _text(String value) =>
    _literal(skir.DataValue.wrapStringValue(value));
skir.HeaderItem _button(String id, String label, skir.EditorAction action) =>
    skir.HeaderItem.createButton(
      itemId: skir.HeaderItemId(namespace: "fixture", name: id),
      icon: _text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"> '
        '<path d="M4 4h16v16H4z"/></svg>',
      ),
      label: _text(label),
      tooltip: null,
      action: action,
      priority: null,
      visibleIf: null,
      enabledIf: null,
      tone: skir.HeaderActionTone.neutral,
      confirmation: null,
      placement: skir.HeaderActionPlacement.end,
    );
