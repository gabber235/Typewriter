import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("chooses only concrete resource descendants", (tester) async {
    final fixture = _concreteResourceFixture();
    skir.TypeSelection? selected;

    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            selected = await showCreationConcreteTypePicker(
              context,
              expected: skir.TypeSelection.createComplete(
                definition: fixture.page,
                arguments: const [],
              ),
              catalog: fixture.catalog,
            );
          },
          child: const Text("Create page"),
        ),
      ),
    );

    await tester.tap(find.text("Create page"));
    await tester.pumpAndSettle();

    expect(find.text("Search resource types"), findsOneWidget);
    expect(find.text("Page"), findsNothing);
    expect(find.text("Unrelated"), findsNothing);
    expect(find.text("Sequence"), findsOneWidget);
    expect(find.text("Static"), findsOneWidget);
    expect(find.text("Scene"), findsOneWidget);
    expect(find.text("Manifest"), findsOneWidget);
    expect(find.text("Sequence page"), findsOneWidget);

    final query = find.descendant(
      of: find.byType(QueryBar),
      matching: find.byType(EditableText),
    );
    await tester.enterText(query, "manifest");
    await tester.pumpAndSettle();
    expect(find.text("Sequence"), findsNothing);
    expect(find.text("Manifest"), findsOneWidget);
    expect(find.text("Continue"), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final complete = switch (selected) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => throw TestFailure("Expected a complete resource selection"),
    };
    expect(complete.definition, fixture.manifest);
  });

  testWidgets("shows no matches and Escape cancels type search", (
    tester,
  ) async {
    final fixture = _concreteResourceFixture();
    skir.TypeSelection? selected;

    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            selected = await showCreationConcreteTypePicker(
              context,
              expected: skir.TypeSelection.createComplete(
                definition: fixture.page,
                arguments: const [],
              ),
              catalog: fixture.catalog,
            );
          },
          child: const Text("Create page"),
        ),
      ),
    );

    await tester.tap(find.text("Create page"));
    await tester.pumpAndSettle();
    final query = find.descendant(
      of: find.byType(QueryBar),
      matching: find.byType(EditableText),
    );
    await tester.enterText(query, "missing page kind");
    await tester.pumpAndSettle();
    expect(find.text("No results found"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(query).focusNode.hasPrimaryFocus,
      isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueryBar), findsNothing);
    expect(selected, isNull);
  });

  testWidgets("searches scalar arguments and composes a nullable generic", (
    tester,
  ) async {
    final fixture = _fixture(unbounded: true, containerName: "List");
    skir.TypeUse? selected;

    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            selected = await showAuthoredTypeUsePicker(
              context,
              title: "Choose payload type",
              catalog: fixture.catalog,
            );
          },
          child: const Text("Choose payload"),
        ),
      ),
    );

    await tester.tap(find.text("Choose payload"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      "List",
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("List<Unfilled>"));
    await tester.pumpAndSettle();

    expect(find.text("Choose payload type"), findsOneWidget);
    await tester.tap(find.text("T: Choose a type"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      "Text",
    );
    await tester.pumpAndSettle();
    expect(_searchResult("Text"), findsOneWidget);
    expect(_searchResult("Text?"), findsOneWidget);
    await tester.tap(_searchResult("Text"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Allow no value"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Choose"));
    await tester.pumpAndSettle();

    final nullable = switch (selected) {
      skir.TypeUse_nullableWrapper(:final value) => value.value,
      _ => throw TestFailure("Expected a nullable type"),
    };
    final named = switch (nullable) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => throw TestFailure("Expected a named generic type"),
    };
    expect(named.definition, fixture.container);
    expect(named.arguments, [skir.TypeUse.wrapScalar(skir.ScalarKind.text)]);
  });

  testWidgets("composes arguments and confirms the Realm repair preview", (
    tester,
  ) async {
    final fixture = _fixture();
    skir.TypeSelection? requested;
    skir.TypeArgumentChangePreview? committed;
    String? status;

    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredTypeArgumentEditor(
          selection: skir.TypeSelection.createPending(
            definition: fixture.container,
            arguments: [skir.ArgumentSelection.unfilled],
          ),
          catalog: fixture.catalog,
          preview: (next) async {
            requested = next;
            return skir.TypePreviewResult.createReady(
              catalog: fixture.catalog.snapshot.generation,
              resource: skir.ResourceId(value: "variable:1"),
              next: next,
              expectations: const [],
              intents: const [],
              linkRepairs: const [],
              clearedLocations: [
                skir.ValueLocation(
                  resource: skir.ResourceId(value: "variable:1"),
                  path: skir.ValuePath(
                    segments: [skir.PathSegment.createField(name: "value")],
                  ),
                ),
              ],
            );
          },
          commit: (preview) async {
            committed = preview;
            return skir.CommitTypeArgumentChangeResponse.wrapResult(
              skir.CommitResult.committed,
            );
          },
          onStatus: (value) => status = value,
        ),
      ),
    );

    expect(find.textContaining("independent fields remain editable"), findsOne);
    await tester.tap(find.text("Choose a type"));
    await tester.pumpAndSettle();

    await _searchAndChoose(tester, "CoinReward");

    expect(find.text("Review type change"), findsOne);
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();

    final complete = switch (requested) {
      final skir.TypeSelection_completeWrapper value => value,
      _ => throw TestFailure("Expected a complete selection"),
    };
    expect(complete.value.definition, fixture.container);
    expect(
      (complete.value.arguments.single as skir.TypeUse_namedWrapper)
          .value
          .definition,
      fixture.coin,
    );
    expect(find.text("Values cleared: 1"), findsOne);
    expect(find.textContaining("variable:1 value"), findsOne);

    await tester.tap(find.widgetWithText(FilledButton, "Apply type change"));
    await tester.pumpAndSettle();

    expect(committed?.next, requested);
    expect(status, "Type arguments updated");
  });

  testWidgets("persists one chosen argument while another stays Unfilled", (
    tester,
  ) async {
    final fixture = _fixture(parameterCount: 2);
    skir.TypeSelection? requested;
    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredTypeArgumentEditor(
          selection: skir.TypeSelection.createPending(
            definition: fixture.container,
            arguments: [
              skir.ArgumentSelection.unfilled,
              skir.ArgumentSelection.unfilled,
            ],
          ),
          catalog: fixture.catalog,
          preview: (next) async {
            requested = next;
            return skir.TypePreviewResult.createReady(
              catalog: fixture.catalog.snapshot.generation,
              resource: skir.ResourceId(value: "variable:1"),
              next: next,
              expectations: const [],
              intents: const [],
              linkRepairs: const [],
              clearedLocations: const [],
            );
          },
          commit: (_) async => skir.CommitTypeArgumentChangeResponse.wrapResult(
            skir.CommitResult.committed,
          ),
        ),
      ),
    );

    await tester.tap(find.text("Choose a type").first);
    await tester.pumpAndSettle();
    await _searchAndChoose(tester, "CoinReward");
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();

    final pending = switch (requested) {
      final skir.TypeSelection_pendingWrapper value => value,
      _ => throw TestFailure("Expected a pending selection"),
    };
    expect(pending.value.definition, fixture.container);
    expect(
      pending.value.arguments.first,
      isA<skir.ArgumentSelection_chosenWrapper>(),
    );
    expect(pending.value.arguments.last, skir.ArgumentSelection.unfilled);
    expect(find.textContaining("Unfilled"), findsOneWidget);
  });
}

({
  CheckedEditorCatalog catalog,
  skir.TypeDefinitionId page,
  skir.TypeDefinitionId sequence,
  skir.TypeDefinitionId manifest,
})
_concreteResourceFixture() {
  final page = _definition("Page");
  final sequence = _definition("SequencePage");
  final staticPage = _definition("StaticPage");
  final scene = _definition("ScenePage");
  final manifest = _definition("ManifestPage");
  final unrelated = _definition("Unrelated");
  skir.PublishedType published(
    skir.TypeDefinitionId id, {
    required bool abstract,
    List<skir.NamedTypeTemplate> parents = const [],
    skir.TypeDisplay? display,
  }) => skir.PublishedType(
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: abstract,
      ),
      parents: parents,
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: parents,
    display: display,
  );
  final pageParent = skir.NamedTypeTemplate(
    definition: page,
    arguments: const [],
  );
  return (
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:resources"),
        types: [
          published(page, abstract: true),
          published(
            sequence,
            abstract: false,
            parents: [pageParent],
            display: _display(
              "Sequence",
              "material-symbols:account-tree",
              "#2196F3",
            ),
          ),
          published(
            staticPage,
            abstract: false,
            parents: [pageParent],
            display: _display("Static", "material-symbols:push-pin", "#673AB7"),
          ),
          published(
            scene,
            abstract: false,
            parents: [pageParent],
            display: _display("Scene", "material-symbols:movie", "#FF9800"),
          ),
          published(
            manifest,
            abstract: false,
            parents: [pageParent],
            display: _display("Manifest", "material-symbols:schema", "#4CAF50"),
          ),
          published(unrelated, abstract: false),
        ],
        relations: const [],
        resourceDefinitions: const [],
        presentations: const [],
        presentationMaterials: const [],
        configuration: const [],
        diagnostics: const [],
        initialization: const [],
        endpointBindings: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    ),
    page: page,
    sequence: sequence,
    manifest: manifest,
  );
}

({
  CheckedEditorCatalog catalog,
  skir.TypeDefinitionId container,
  skir.TypeDefinitionId coin,
})
_fixture({
  int parameterCount = 1,
  bool unbounded = false,
  String containerName = "Variable",
}) {
  final container = _definition(containerName);
  final reward = _definition("Reward");
  final coin = _definition("CoinReward");
  skir.PublishedType published(
    skir.TypeDefinitionId id, {
    List<skir.TypeParameter> parameters = const [],
    List<skir.NamedTypeTemplate> parents = const [],
  }) => skir.PublishedType(
    definition: skir.TypeDefinition(
      id: id,
      parameters: parameters,
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: false,
      ),
      parents: parents,
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: parents,
    display: null,
  );
  return (
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:1"),
        types: [
          published(
            container,
            parameters: [
              for (var index = 0; index < parameterCount; index++)
                skir.TypeParameter(
                  key: skir.ParameterKey(owner: container, index: index),
                  name: index == 0 ? "T" : "U",
                  bounds: unbounded
                      ? const []
                      : [
                          skir.TypeTemplate.createNamed(
                            definition: reward,
                            arguments: const [],
                          ),
                        ],
                ),
            ],
          ),
          published(reward),
          published(
            coin,
            parents: [
              skir.NamedTypeTemplate(definition: reward, arguments: const []),
            ],
          ),
        ],
        relations: const [],
        resourceDefinitions: const [],
        presentations: const [],
        presentationMaterials: const [],
        configuration: const [],
        diagnostics: const [],
        initialization: const [],
        endpointBindings: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    ),
    container: container,
    coin: coin,
  );
}

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

skir.TypeDisplay _display(String name, String icon, String color) =>
    skir.TypeDisplay(
      name: name,
      description: "$name page",
      icon: icon,
      color: color,
    );

Finder _searchResult(String label) => find.descendant(
  of: find.byType(SearchResultCard),
  matching: find.text(label),
);

Future<void> _searchAndChoose(WidgetTester tester, String label) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(QueryBar),
      matching: find.byType(EditableText),
    ),
    label,
  );
  await tester.pumpAndSettle();
  await tester.tap(_searchResult(label));
  await tester.pumpAndSettle();
}
