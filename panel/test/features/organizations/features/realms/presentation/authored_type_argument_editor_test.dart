import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("chooses only concrete resource descendants", (tester) async {
    final fixture = _concreteResourceFixture();
    types.TypeSelection? selected;

    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            selected = await showCreationConcreteTypePicker(
              context,
              expected: types.TypeSelection.createComplete(
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
      types.TypeSelection_completeWrapper(:final value) => value,
      _ => throw TestFailure("Expected a complete resource selection"),
    };
    expect(complete.definition, fixture.manifest);
  });

  testWidgets("shows no matches and Escape cancels type search", (
    tester,
  ) async {
    final fixture = _concreteResourceFixture();
    types.TypeSelection? selected;

    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            selected = await showCreationConcreteTypePicker(
              context,
              expected: types.TypeSelection.createComplete(
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
    types.TypeUse? selected;

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
      types.TypeUse_nullableWrapper(:final value) => value.value,
      _ => throw TestFailure("Expected a nullable type"),
    };
    final named = switch (nullable) {
      types.TypeUse_namedWrapper(:final value) => value,
      _ => throw TestFailure("Expected a named generic type"),
    };
    expect(named.definition, fixture.container);
    expect(named.arguments, [types.TypeUse.wrapScalar(types.ScalarKind.text)]);
  });

  testWidgets("composes arguments and confirms the Realm repair preview", (
    tester,
  ) async {
    final fixture = _fixture();
    types.TypeSelection? requested;
    authoring.TypeArgumentChangePreview? committed;
    String? status;

    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredTypeArgumentEditor(
          selection: types.TypeSelection.createPending(
            definition: fixture.container,
            arguments: [types.ArgumentSelection.unfilled],
          ),
          catalog: fixture.catalog,
          preview: (next) async {
            requested = next;
            return authoring.TypePreviewResult.createReady(
              catalog: fixture.catalog.snapshot.generation,
              sourceSnapshot: types.SnapshotId(value: "realm:1"),
              resource: types.ResourceId(value: "variable:1"),
              next: next,
              observations: const [],
              intents: const [],
              linkRepairs: const [],
              clearedLocations: [
                types.ValueLocation(
                  resource: types.ResourceId(value: "variable:1"),
                  path: types.ValuePath(
                    segments: [types.PathSegment.createField(name: "value")],
                  ),
                ),
              ],
            );
          },
          commit: (preview) async {
            committed = preview;
            return authoring.CommitTypeArgumentChangeResponse.wrapResult(
              authoring.CommitResult.createCommitted(
                snapshot: types.SnapshotId(value: "realm:2"),
                changed: const [],
              ),
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
      final types.TypeSelection_completeWrapper value => value,
      _ => throw TestFailure("Expected a complete selection"),
    };
    expect(complete.value.definition, fixture.container);
    expect(
      (complete.value.arguments.single as types.TypeUse_namedWrapper)
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
    types.TypeSelection? requested;
    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoredTypeArgumentEditor(
          selection: types.TypeSelection.createPending(
            definition: fixture.container,
            arguments: [
              types.ArgumentSelection.unfilled,
              types.ArgumentSelection.unfilled,
            ],
          ),
          catalog: fixture.catalog,
          preview: (next) async {
            requested = next;
            return authoring.TypePreviewResult.createReady(
              catalog: fixture.catalog.snapshot.generation,
              sourceSnapshot: types.SnapshotId(value: "realm:1"),
              resource: types.ResourceId(value: "variable:1"),
              next: next,
              observations: const [],
              intents: const [],
              linkRepairs: const [],
              clearedLocations: const [],
            );
          },
          commit: (_) async =>
              authoring.CommitTypeArgumentChangeResponse.wrapResult(
                authoring.CommitResult.createCommitted(
                  snapshot: types.SnapshotId(value: "realm:2"),
                  changed: const [],
                ),
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
      final types.TypeSelection_pendingWrapper value => value,
      _ => throw TestFailure("Expected a pending selection"),
    };
    expect(pending.value.definition, fixture.container);
    expect(
      pending.value.arguments.first,
      isA<types.ArgumentSelection_chosenWrapper>(),
    );
    expect(pending.value.arguments.last, types.ArgumentSelection.unfilled);
    expect(find.textContaining("Unfilled"), findsOneWidget);
  });
}

({
  CheckedEditorCatalog catalog,
  types.TypeDefinitionId page,
  types.TypeDefinitionId sequence,
  types.TypeDefinitionId manifest,
})
_concreteResourceFixture() {
  final page = _definition("Page");
  final sequence = _definition("SequencePage");
  final staticPage = _definition("StaticPage");
  final scene = _definition("ScenePage");
  final manifest = _definition("ManifestPage");
  final unrelated = _definition("Unrelated");
  catalog.PublishedType published(
    types.TypeDefinitionId id, {
    required bool abstract,
    List<types.NamedTypeTemplate> parents = const [],
    catalog.TypeDisplay? display,
  }) => catalog.PublishedType(
    definition: types.TypeDefinition(
      id: id,
      parameters: const [],
      representation: types.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: abstract,
      ),
      parents: parents,
    ),
    status: catalog.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: parents,
    display: display,
  );
  final pageParent = types.NamedTypeTemplate(
    definition: page,
    arguments: const [],
  );
  return (
    catalog: CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:resources"),
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
  types.TypeDefinitionId container,
  types.TypeDefinitionId coin,
})
_fixture({
  int parameterCount = 1,
  bool unbounded = false,
  String containerName = "Variable",
}) {
  final container = _definition(containerName);
  final reward = _definition("Reward");
  final coin = _definition("CoinReward");
  catalog.PublishedType published(
    types.TypeDefinitionId id, {
    List<types.TypeParameter> parameters = const [],
    List<types.NamedTypeTemplate> parents = const [],
  }) => catalog.PublishedType(
    definition: types.TypeDefinition(
      id: id,
      parameters: parameters,
      representation: types.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: false,
      ),
      parents: parents,
    ),
    status: catalog.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: parents,
    display: null,
  );
  return (
    catalog: CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:1"),
        types: [
          published(
            container,
            parameters: [
              for (var index = 0; index < parameterCount; index++)
                types.TypeParameter(
                  key: types.ParameterKey(owner: container, index: index),
                  name: index == 0 ? "T" : "U",
                  bounds: unbounded
                      ? const []
                      : [
                          types.TypeTemplate.createNamed(
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
              types.NamedTypeTemplate(definition: reward, arguments: const []),
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

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

catalog.TypeDisplay _display(String name, String icon, String color) =>
    catalog.TypeDisplay(
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
