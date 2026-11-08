import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "removing an item of a nested list removes it from the document",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.nestedLists,
      );
      addTearDown(scenario.dispose);
      final panel = await scenario.show(tester);
      List<skir.ItemId> innerItems(skir.ListItem outer) => [
        for (final item in outer.value.authoredItems!) item.id,
      ];

      await panel.tapOn(find.tooltip("Expand").first);
      // The first removal belongs to the outer item, the second to the item of
      // the nested list inside it.
      await panel.tapOn(find.tooltip("Remove item").at(1));

      final outer = scenario.value.authoredItems!;
      expect(outer.map((item) => item.id), [
        CollectionEditorScenario.first,
        CollectionEditorScenario.second,
      ]);
      expect(innerItems(outer.first), isEmpty);
      expect(innerItems(outer.last), [CollectionEditorScenario.second]);
    },
  );

  testWidgets("a hidden authored removal suppresses its generated equivalent", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      removeStep: true,
      transformLayout: (node) => withListItemHeader(
        node,
        (header) =>
            (header.toMutable()
                  ..items = [
                    for (final item in header.items)
                      if (item case skir.HeaderItem_buttonWrapper(:final value))
                        skir.HeaderItem.wrapButton(
                          (value.toMutable()
                                ..visibleIf = literalExpression(
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
    await scenario.show(tester);

    expect(find.tooltip("Remove step"), findsNothing);
    // The declaration removes first. It cannot suppress second's removal.
    expect(find.tooltip("Remove item"), findsOneWidget);
    expect(scenario.value.authoredItems!.map((item) => item.id), [
      CollectionEditorScenario.first,
      CollectionEditorScenario.second,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets("aliased removal keeps one pinned action that removes with one "
      "press", (tester) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
      removeStep: true,
      transformLayout: (root) {
        final alias = skir.ExpressionBindingId(
          value: "fixture.collectionAlias",
        );
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
            scopeBinding: declareBinding(
              alias,
              skir.TypeUse.wrapNamed(CollectionEditorScenario.ownerType)
                  .portableTemplate,
            ),
            child: child,
          ),
        );
      },
    );
    addTearDown(scenario.dispose);
    final panel = await scenario.show(
      tester,
      stage: CollectionEditorStage(width: 320),
    );

    // Authored removal uses configuredValueBindingId. Generated removal uses
    // the scoped alias. They identify the same source item.
    expect(find.tooltip("Remove item"), findsOneWidget);
    final remove = find.tooltip("Remove step").first;
    expect(remove.hitTestable(), findsOneWidget);
    await panel.tapOn(remove);

    expect(panel.dialog.showing("Remove this step?"), isFalse);
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
      resource: textLiteral("quest:details"),
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
      transformLayout: (node) => withListItemHeader(
        node,
        (header) =>
            (header.toMutable()
                  ..items = [
                    ...header.items,
                    headerButton("open", "Open details", navigation),
                  ])
                .toFrozen(),
      ),
    );
    addTearDown(scenario.dispose);
    final panel = await scenario.show(tester, readOnly: true);

    await panel.tapOn(panel.labeled("Open details").first);
    expect(actions, [navigation]);
    final removals = find.tooltip("Remove item");
    expect(removals, findsWidgets);
    for (var index = 0; index < removals.evaluate().length; index++) {
      expect(tester.getSemantics(removals.at(index)).isEnabled, isFalse);
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
      targets: literalExpression(
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
      transformLayout: (node) => withListItemHeader(
        node,
        (header) =>
            (header.toMutable()
                  ..items = [
                    ...header.items,
                    headerButton("deleteQuest", "Delete quest", deletion),
                  ])
                .toFrozen(),
      ),
    );
    addTearDown(scenario.dispose);
    final panel = await scenario.show(tester);

    expect(find.tooltip("Remove item"), findsNWidgets(2));
    await panel.tapOn(panel.labeled("Delete quest").first);
    // This public host boundary test establishes forwarding. Resource
    // admission and selection effects remain in their existing contract tests.
    expect(actions, [deletion]);
    expect(scenario.value.authoredItems, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
